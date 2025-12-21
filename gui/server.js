const express = require('express');
const cors = require('cors');
const { exec } = require('child_process');
const util = require('util');
const execPromise = util.promisify(exec);

const app = express();
const PORT = 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('.'));

// Bitcoin CLI command builder
function bitcoinCli(command) {
    return `bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" ${command}`;
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

// Parse UTXO for NFT/Token data
function parseUtxoForCharms(utxo) {
    // This is a simplified parser. In a real implementation, you would:
    // 1. Decode the scriptPubKey to check for OP_RETURN or Taproot data
    // 2. Parse the charm data from the transaction
    // 3. Identify NFT vs Token based on the app contract

    // For now, we'll mark UTXOs with specific addresses as potential NFT/Token holders
    const result = {
        txid: utxo.txid,
        vout: utxo.vout,
        address: utxo.address,
        amount: utxo.amount,
        confirmations: utxo.confirmations,
        type: 'plain'
    };

    // Check if this might be an NFT or token UTXO
    // You can enhance this by actually parsing the transaction data
    if (utxo.desc && utxo.desc.includes('tr(')) {
        // Taproot output - could be NFT or token
        result.type = 'unknown';
    }

    return result;
}

// Enhanced UTXO parser with transaction inspection
async function parseUtxoWithTransaction(utxo) {
    const result = parseUtxoForCharms(utxo);

    try {
        // Fetch the raw transaction to inspect outputs
        const txHex = await execBitcoinCli(`getrawtransaction ${utxo.txid}`);
        const tx = await execBitcoinCli(`decoderawtransaction ${txHex}`);

        // Check the output script for OP_RETURN or custom data
        const vout = tx.vout[utxo.vout];

        if (vout && vout.scriptPubKey) {
            const scriptPubKey = vout.scriptPubKey;

            // Look for OP_RETURN data (type 'nulldata')
            if (scriptPubKey.type === 'nulldata' || scriptPubKey.asm.includes('OP_RETURN')) {
                result.type = 'data';
            }

            // Check for witness data (Taproot)
            if (scriptPubKey.type === 'witness_v1_taproot') {
                result.type = 'taproot';
            }
        }

        // Try to identify NFT/Token based on known patterns
        // This is where you'd integrate with the Charms SDK to parse charm data
        // For demonstration, we'll use address patterns from your examples

        const knownNftAddress = 'tb1p40c5eywchazxa4t3jdytnc39c3g8l2tzegzk7zgrzcdm324xce3qww4eud';
        const knownTokenAddress = 'tb1px6jrge3dynx9tjp6vwp7xrq9a3gm9dqpz9jts4jezhvlulayvrqq9rcrz3';

        if (utxo.address === knownNftAddress) {
            result.type = 'nft';
            result.ticker = 'MY-TOKEN';
            result.remaining = 30580; // This should be parsed from actual charm data
        } else if (utxo.address === knownTokenAddress) {
            result.type = 'token';
            result.ticker = 'MY-TOKEN';
            result.tokenAmount = 69420; // This should be parsed from actual charm data
        }

    } catch (error) {
        console.error('Error parsing transaction:', error.message);
    }

    return result;
}

// API Routes

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

// Get current receiving address (gets an existing address from the wallet)
app.get('/address', async (_req, res) => {
    try {
        // Get all addresses with any received amount (including 0)
        const addresses = await execBitcoinCli('listreceivedbyaddress 0 true');

        // Get the most recently used address, or generate a new one if none exist
        let address;
        if (addresses && addresses.length > 0) {
            // Sort by amount received (desc) to get actively used addresses first
            addresses.sort((a, b) => b.amount - a.amount);
            address = addresses[0].address;
        } else {
            // If no addresses exist, generate a new one
            address = await execBitcoinCli('getnewaddress');
        }

        res.json({ address });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// List all addresses in wallet
app.get('/addresses', async (_req, res) => {
    try {
        const addresses = await execBitcoinCli('listreceivedbyaddress 0 true');
        res.json(addresses);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get UTXOs for the entire wallet or specific address
app.get('/utxos/:address?', async (req, res) => {
    try {
        const address = req.params.address;

        let utxos;
        if (address) {
            // Get UTXOs for specific address
            const allUtxos = await execBitcoinCli('listunspent');
            utxos = allUtxos.filter(u => u.address === address);
        } else {
            // Get all wallet UTXOs
            utxos = await execBitcoinCli('listunspent');
        }

        // Parse each UTXO for charm data
        const parsedUtxos = await Promise.all(
            utxos.map(utxo => parseUtxoWithTransaction(utxo))
        );

        res.json({
            count: parsedUtxos.length,
            utxos: parsedUtxos
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get transaction details
app.get('/transaction/:txid', async (req, res) => {
    try {
        const txid = req.params.txid;
        const txHex = await execBitcoinCli(`getrawtransaction ${txid}`);
        const tx = await execBitcoinCli(`decoderawtransaction ${txHex}`);
        res.json(tx);
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

// List recent transactions
app.get('/transactions', async (req, res) => {
    try {
        const count = req.query.count || 10;
        const transactions = await execBitcoinCli(`listtransactions "*" ${count}`);
        res.json(transactions);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Advanced: Parse charm data from UTXO
// This endpoint would integrate with the Charms SDK to properly decode charm data
app.get('/charm/:txid/:vout', async (req, res) => {
    try {
        const { txid, vout } = req.params;

        // Get transaction
        const txHex = await execBitcoinCli(`getrawtransaction ${txid}`);
        const tx = await execBitcoinCli(`decoderawtransaction ${txHex}`);

        // Extract output
        const output = tx.vout[parseInt(vout)];

        // Here you would:
        // 1. Extract witness data from Taproot output
        // 2. Call Charms SDK or CLI to decode charm data
        // 3. Return parsed NFT/Token information

        res.json({
            utxo: `${txid}:${vout}`,
            output,
            note: 'Full charm parsing requires integration with Charms SDK'
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Health check
app.get('/health', (_req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Start server
app.listen(PORT, () => {
    console.log(`
╔════════════════════════════════════════════╗
║     NFTCharm Viewer Server                 ║
║                                            ║
║  Server running on http://localhost:${PORT}  ║
║                                            ║
║  API Endpoints:                            ║
║  GET  /status                              ║
║  GET  /wallet                              ║
║  GET  /address                             ║
║  GET  /addresses                           ║
║  GET  /balance                             ║
║  GET  /utxos/:address?                     ║
║  GET  /transaction/:txid                   ║
║  GET  /transactions                        ║
║  GET  /charm/:txid/:vout                   ║
║                                            ║
║  Open GUI: http://localhost:${PORT}        ║
╚════════════════════════════════════════════╝
    `);

    // Check Bitcoin Core connection on startup
    execBitcoinCli('getblockchaininfo')
        .then(() => console.log('✓ Connected to Bitcoin Core (testnet4)'))
        .catch(() => console.error('✗ Cannot connect to Bitcoin Core. Make sure it\'s running with testnet4 and wallet loaded.'));
});

// Error handling
process.on('uncaughtException', (error) => {
    console.error('Uncaught Exception:', error);
});

process.on('unhandledRejection', (reason, promise) => {
    console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});
