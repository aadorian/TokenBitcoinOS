const express = require('express');
const cors = require('cors');
const { exec, spawn } = require('child_process');
const util = require('util');
const path = require('path');
const WebSocket = require('ws');
const http = require('http');

const execPromise = util.promisify(exec);

const app = express();
const PORT = 3000;

// Create HTTP server
const server = http.createServer(app);

// Create WebSocket server
const wss = new WebSocket.Server({ server });

// Store active script executions
const activeScripts = new Map();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('.'));
app.use(express.static(path.join(__dirname, 'public')));

// Bitcoin CLI command builder
function bitcoinCli(command, network = 'testnet4') {
    const networkFlag = network === 'testnet4' ? '-testnet4' : network === 'testnet' ? '-testnet' : '';
    return `bitcoin-cli ${networkFlag} -rpcwallet="nftcharm_wallet" ${command}`;
}

// Execute Bitcoin CLI command
async function execBitcoinCli(command) {
    try {
        const { stdout, stderr } = await execPromise(bitcoinCli(command));
        if (stderr && !stderr.includes('warning')) {
            console.error('Bitcoin CLI stderr:', stderr);
        }
        return JSON.parse(stdout);
    } catch (error) {
        console.error('Bitcoin CLI error:', error);
        throw error;
    }
}

// WebSocket connection handler
wss.on('connection', (ws) => {
    console.log('Client connected');

    ws.on('message', (message) => {
        console.log('Received:', message.toString());
    });

    ws.on('close', () => {
        console.log('Client disconnected');
    });
});

// Broadcast to all connected clients
function broadcast(data) {
    wss.clients.forEach((client) => {
        if (client.readyState === WebSocket.OPEN) {
            client.send(JSON.stringify(data));
        }
    });
}

// Execute shell script
function executeScript(scriptName, args = [], ws = null) {
    const scriptPath = path.join(__dirname, '..', scriptName);
    const scriptId = Date.now().toString();

    return new Promise((resolve, reject) => {
        const process = spawn('bash', [scriptPath, ...args], {
            cwd: path.join(__dirname, '..')
        });

        activeScripts.set(scriptId, process);

        let stdout = '';
        let stderr = '';

        process.stdout.on('data', (data) => {
            const output = data.toString();
            stdout += output;

            if (ws) {
                ws.send(JSON.stringify({
                    type: 'stdout',
                    scriptId,
                    data: output
                }));
            } else {
                broadcast({
                    type: 'stdout',
                    scriptId,
                    script: scriptName,
                    data: output
                });
            }
        });

        process.stderr.on('data', (data) => {
            const output = data.toString();
            stderr += output;

            if (ws) {
                ws.send(JSON.stringify({
                    type: 'stderr',
                    scriptId,
                    data: output
                }));
            } else {
                broadcast({
                    type: 'stderr',
                    scriptId,
                    script: scriptName,
                    data: output
                });
            }
        });

        process.on('close', (code) => {
            activeScripts.delete(scriptId);

            const result = {
                code,
                stdout,
                stderr,
                success: code === 0
            };

            if (ws) {
                ws.send(JSON.stringify({
                    type: 'exit',
                    scriptId,
                    ...result
                }));
            } else {
                broadcast({
                    type: 'exit',
                    scriptId,
                    script: scriptName,
                    ...result
                });
            }

            if (code === 0) {
                resolve(result);
            } else {
                reject(new Error(`Script exited with code ${code}: ${stderr}`));
            }
        });

        process.on('error', (error) => {
            activeScripts.delete(scriptId);
            reject(error);
        });
    });
}

// API Routes

// Health check
app.get('/health', (_req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Check Bitcoin Core connection status
app.get('/status', async (req, res) => {
    try {
        const info = await execBitcoinCli('getblockchaininfo');
        res.json({
            connected: true,
            network: info.chain,
            blocks: info.blocks,
            headers: info.headers,
            verificationProgress: info.verificationprogress
        });
    } catch (error) {
        res.json({
            connected: false,
            error: error.message
        });
    }
});

// Get wallet info
app.get('/wallet', async (req, res) => {
    try {
        const info = await execBitcoinCli('getwalletinfo');
        res.json(info);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get balance
app.get('/balance', async (req, res) => {
    try {
        const balance = await execBitcoinCli('getbalance');
        res.json({ balance });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get current address
app.get('/address', async (_req, res) => {
    try {
        const addresses = await execBitcoinCli('listreceivedbyaddress 0 true');
        let address;
        if (addresses && addresses.length > 0) {
            addresses.sort((a, b) => b.amount - a.amount);
            address = addresses[0].address;
        } else {
            address = await execBitcoinCli('getnewaddress');
        }
        res.json({ address });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// List UTXOs
app.get('/utxos', async (req, res) => {
    try {
        const utxos = await execBitcoinCli('listunspent');
        res.json({ count: utxos.length, utxos });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// List transactions
app.get('/transactions', async (req, res) => {
    try {
        const count = req.query.count || 10;
        const transactions = await execBitcoinCli(`listtransactions "*" ${count}`);
        res.json(transactions);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Script execution endpoints

// Execute check-balance.sh
app.post('/scripts/check-balance', async (req, res) => {
    try {
        const result = await executeScript('check-balance.sh');
        res.json(result);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Execute send-btc.sh (non-interactive version for GUI)
app.post('/scripts/send-btc', async (req, res) => {
    try {
        const { address, amount, feeRate } = req.body;

        if (!address || !amount) {
            return res.status(400).json({ error: 'Address and amount are required' });
        }

        // Execute the transaction directly via bitcoin-cli
        const scriptPath = path.join(__dirname, '..', 'send-btc.sh');
        const scriptId = Date.now().toString();
        const fee = feeRate || '1';

        return new Promise((resolve, reject) => {
            const process = spawn('bash', [scriptPath, address, amount, fee], {
                cwd: path.join(__dirname, '..')
            });

            let stdout = '';
            let stderr = '';

            // Auto-confirm by sending 'yes' to stdin
            process.stdin.write('yes\n');
            process.stdin.end();

            process.stdout.on('data', (data) => {
                const output = data.toString();
                stdout += output;
                broadcast({
                    type: 'stdout',
                    scriptId,
                    script: 'send-btc.sh',
                    data: output
                });
            });

            process.stderr.on('data', (data) => {
                const output = data.toString();
                stderr += output;
                broadcast({
                    type: 'stderr',
                    scriptId,
                    script: 'send-btc.sh',
                    data: output
                });
            });

            process.on('close', (code) => {
                const result = {
                    code,
                    stdout,
                    stderr,
                    success: code === 0
                };

                broadcast({
                    type: 'exit',
                    scriptId,
                    script: 'send-btc.sh',
                    ...result
                });

                if (code === 0) {
                    resolve(res.json(result));
                } else {
                    reject(res.status(500).json({ error: stderr, ...result }));
                }
            });

            process.on('error', (error) => {
                reject(res.status(500).json({ error: error.message }));
            });
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Execute create-nft.sh
app.post('/scripts/create-nft', async (req, res) => {
    try {
        const result = await executeScript('create-nft.sh');
        res.json(result);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Execute mint-tokens.sh
app.post('/scripts/mint-tokens', async (req, res) => {
    try {
        const result = await executeScript('mint-tokens.sh');
        res.json(result);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Execute transfer-tokens.sh (interactive version - shows instructions)
app.post('/scripts/transfer-tokens', async (req, res) => {
    try {
        const result = await executeScript('transfer-tokens.sh');
        res.json(result);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get available token UTXOs for transfer
app.get('/tokens/utxos', async (req, res) => {
    try {
        // Get all UTXOs from wallet
        const utxos = await execBitcoinCli('listunspent');

        // Filter for likely token UTXOs (small amounts, could be dust)
        const tokenUtxos = utxos.filter(utxo => utxo.amount < 0.0001);

        res.json({
            count: tokenUtxos.length,
            utxos: tokenUtxos.map(utxo => ({
                txid: utxo.txid,
                vout: utxo.vout,
                amount: utxo.amount,
                address: utxo.address,
                utxo_id: `${utxo.txid}:${utxo.vout}`
            }))
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Execute spell.sh
app.post('/scripts/spell', async (req, res) => {
    try {
        const { txid, detailed, raw } = req.body;

        if (!txid) {
            return res.status(400).json({ error: 'Transaction ID is required' });
        }

        const args = [txid];
        if (detailed) args.push('--detailed');
        if (raw) args.push('--raw');

        const result = await executeScript('spell.sh', args);
        res.json(result);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// List available scripts
app.get('/scripts', (req, res) => {
    res.json({
        scripts: [
            {
                name: 'check-balance.sh',
                description: 'Check token balances in wallet',
                endpoint: '/scripts/check-balance',
                method: 'POST',
                params: []
            },
            {
                name: 'send-btc.sh',
                description: 'Send Bitcoin to an address',
                endpoint: '/scripts/send-btc',
                method: 'POST',
                params: ['address', 'amount', 'feeRate (optional)']
            },
            {
                name: 'create-nft.sh',
                description: 'Create a new NFT',
                endpoint: '/scripts/create-nft',
                method: 'POST',
                params: []
            },
            {
                name: 'mint-tokens.sh',
                description: 'Mint tokens from an NFT',
                endpoint: '/scripts/mint-tokens',
                method: 'POST',
                params: []
            },
            {
                name: 'transfer-tokens.sh',
                description: 'Transfer tokens to another address',
                endpoint: '/scripts/transfer-tokens',
                method: 'POST',
                params: []
            },
            {
                name: 'spell.sh',
                description: 'View spell content from a transaction',
                endpoint: '/scripts/spell',
                method: 'POST',
                params: ['txid', 'detailed (optional)', 'raw (optional)']
            }
        ]
    });
});

// Start server
server.listen(PORT, () => {
    console.log(`
╔════════════════════════════════════════════╗
║     NFTCharm GUI Server                    ║
║                                            ║
║  Server running on http://localhost:${PORT}  ║
║  WebSocket: ws://localhost:${PORT}          ║
║                                            ║
║  API Endpoints:                            ║
║  GET  /status                              ║
║  GET  /wallet                              ║
║  GET  /balance                             ║
║  GET  /address                             ║
║  GET  /utxos                               ║
║  GET  /transactions                        ║
║  GET  /scripts                             ║
║                                            ║
║  Script Execution:                         ║
║  POST /scripts/check-balance               ║
║  POST /scripts/send-btc                    ║
║  POST /scripts/create-nft                  ║
║  POST /scripts/mint-tokens                 ║
║  POST /scripts/transfer-tokens             ║
║  POST /scripts/spell                       ║
║                                            ║
║  Open GUI: http://localhost:${PORT}        ║
╚════════════════════════════════════════════╝
    `);

    // Check Bitcoin Core connection on startup
    execBitcoinCli('getblockchaininfo')
        .then(() => console.log('✓ Connected to Bitcoin Core (testnet4)'))
        .catch(() => console.error('✗ Cannot connect to Bitcoin Core. Make sure it\'s running.'));
});

// Error handling
process.on('uncaughtException', (error) => {
    console.error('Uncaught Exception:', error);
});

process.on('unhandledRejection', (reason, promise) => {
    console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});
