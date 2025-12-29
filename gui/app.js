// NFTCharm GUI Client Application
const API_URL = 'http://localhost:3000';
const WS_URL = 'ws://localhost:3000';

let ws = null;
let currentBalance = 0;

// Initialize WebSocket connection
function initWebSocket() {
    ws = new WebSocket(WS_URL);

    ws.onopen = () => {
        console.log('WebSocket connected');
        showMessage('Connected to server', 'success');
    };

    ws.onmessage = (event) => {
        const data = JSON.parse(event.data);
        handleWebSocketMessage(data);
    };

    ws.onerror = (error) => {
        console.error('WebSocket error:', error);
        showMessage('WebSocket connection error', 'error');
    };

    ws.onclose = () => {
        console.log('WebSocket disconnected');
        showMessage('Disconnected from server', 'warning');
        // Attempt to reconnect after 5 seconds
        setTimeout(initWebSocket, 5000);
    };
}

// Handle WebSocket messages
function handleWebSocketMessage(data) {
    const { type, script, stdout, stderr, code, success } = data;

    switch (type) {
        case 'stdout':
            appendToTerminal(stdout, 'output');
            break;
        case 'stderr':
            appendToTerminal(stderr, 'error');
            break;
        case 'exit':
            appendToTerminal(`\n[Script ${script} exited with code ${code}]\n`, success ? 'success' : 'error');
            break;
    }
}

// Append text to terminal output
function appendToTerminal(text, type = 'output') {
    const terminals = ['sendOutput', 'balanceOutput', 'nftOutput', 'txOutput'];

    terminals.forEach(terminalId => {
        const terminal = document.getElementById(terminalId);
        if (terminal && terminal.style.display !== 'none') {
            terminal.textContent += text;
            terminal.scrollTop = terminal.scrollHeight;
        }
    });
}

// Show status message
function showMessage(message, type = 'info') {
    const container = document.getElementById('statusMessages');
    const colors = {
        success: 'green',
        error: 'red',
        warning: 'yellow',
        info: 'blue'
    };

    const color = colors[type] || colors.info;
    const icons = {
        success: 'check-circle',
        error: 'exclamation-circle',
        warning: 'exclamation-triangle',
        info: 'info-circle'
    };

    const icon = icons[type] || icons.info;

    const alert = document.createElement('div');
    alert.className = `flex items-center p-4 mb-4 text-${color}-800 rounded-lg bg-${color}-50 shadow-lg`;
    alert.innerHTML = `
        <i class="fas fa-${icon} mr-3"></i>
        <span class="sr-only">${type}</span>
        <div class="text-sm font-medium">${message}</div>
        <button type="button" class="ml-auto -mx-1.5 -my-1.5 bg-${color}-50 text-${color}-500 rounded-lg focus:ring-2 focus:ring-${color}-400 p-1.5 hover:bg-${color}-200 inline-flex items-center justify-center h-8 w-8" onclick="this.parentElement.remove()">
            <i class="fas fa-times"></i>
        </button>
    `;

    container.appendChild(alert);

    // Auto remove after 5 seconds
    setTimeout(() => {
        alert.remove();
    }, 5000);
}

// Check Bitcoin Core connection
async function checkConnection() {
    try {
        const response = await fetch(`${API_URL}/status`);
        const data = await response.json();

        const statusDot = document.getElementById('statusDot');
        const statusText = document.getElementById('statusText');

        if (data.connected) {
            statusDot.className = 'status-dot online';
            statusText.textContent = `Connected (${data.blocks} blocks)`;
            document.getElementById('networkName').textContent = data.network;
            return true;
        } else {
            statusDot.className = 'status-dot offline';
            statusText.textContent = 'Bitcoin Core offline';
            return false;
        }
    } catch (error) {
        const statusDot = document.getElementById('statusDot');
        const statusText = document.getElementById('statusText');
        statusDot.className = 'status-dot offline';
        statusText.textContent = 'Server offline';
        return false;
    }
}

// Fetch wallet balance
async function fetchBalance() {
    try {
        const response = await fetch(`${API_URL}/balance`);
        const data = await response.json();

        if (data.balance !== undefined) {
            currentBalance = data.balance;
            const balanceText = `${data.balance.toFixed(8)} BTC`;
            document.getElementById('balance').textContent = balanceText;
            document.getElementById('dashBalance').textContent = balanceText;
        }
    } catch (error) {
        console.error('Error fetching balance:', error);
        document.getElementById('balance').textContent = 'Error';
    }
}

// Fetch current address
async function fetchAddress() {
    try {
        const response = await fetch(`${API_URL}/address`);
        const data = await response.json();

        if (data.address) {
            document.getElementById('currentAddress').textContent = data.address;
            document.getElementById('currentAddress').dataset.address = data.address;
        }
    } catch (error) {
        console.error('Error fetching address:', error);
    }
}

// Fetch recent transactions
async function fetchRecentTransactions() {
    try {
        const response = await fetch(`${API_URL}/transactions?count=5`);
        const data = await response.json();

        const txList = document.getElementById('recentTxList');
        if (data && data.length > 0) {
            txList.innerHTML = data.map(tx => `
                <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                    <div class="flex-1">
                        <code class="text-xs text-gray-600">${tx.txid.substring(0, 16)}...</code>
                        <div class="text-sm ${tx.amount > 0 ? 'text-green-600' : 'text-red-600'}">
                            ${tx.amount > 0 ? '+' : ''}${tx.amount.toFixed(8)} BTC
                        </div>
                    </div>
                    <div class="text-xs text-gray-500">${tx.confirmations} conf</div>
                </div>
            `).join('');
        } else {
            txList.innerHTML = '<p class="text-gray-500">No recent transactions</p>';
        }
    } catch (error) {
        console.error('Error fetching transactions:', error);
    }
}

// Copy address to clipboard
async function copyAddress() {
    const addressElem = document.getElementById('currentAddress');
    const address = addressElem.dataset.address || addressElem.textContent;

    try {
        await navigator.clipboard.writeText(address);
        showMessage('Address copied to clipboard!', 'success');
    } catch (error) {
        console.error('Error copying address:', error);
        showMessage('Failed to copy address', 'error');
    }
}

// Send BTC
document.getElementById('sendBtcForm')?.addEventListener('submit', async (e) => {
    e.preventDefault();

    const address = document.getElementById('sendAddress').value;
    const amount = document.getElementById('sendAmount').value;
    const feeRate = document.getElementById('sendFeeRate').value;

    const sendOutput = document.getElementById('sendOutput');
    sendOutput.innerHTML = '<div class="terminal-output">Sending transaction...</div>';

    try {
        const response = await fetch(`${API_URL}/scripts/send-btc`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ address, amount, feeRate })
        });

        const data = await response.json();

        if (data.success) {
            sendOutput.innerHTML = `<div class="terminal-output">${data.stdout}</div>`;
            showMessage('Transaction sent successfully!', 'success');
            await fetchBalance();
        } else {
            sendOutput.innerHTML = `<div class="terminal-output">${data.stderr || data.error}</div>`;
            showMessage('Transaction failed', 'error');
        }
    } catch (error) {
        sendOutput.innerHTML = `<div class="terminal-output text-red-500">Error: ${error.message}</div>`;
        showMessage(`Error: ${error.message}`, 'error');
    }
});

// Check balance
async function checkBalance() {
    const output = document.getElementById('balanceOutput');
    output.textContent = 'Checking balance...\n';
    output.style.display = 'block';

    try {
        const response = await fetch(`${API_URL}/scripts/check-balance`, {
            method: 'POST'
        });

        const data = await response.json();

        if (data.success) {
            output.textContent = data.stdout;
        } else {
            output.textContent = data.stderr || data.error;
        }
    } catch (error) {
        output.textContent = `Error: ${error.message}`;
        showMessage(`Error: ${error.message}`, 'error');
    }
}

// Create NFT
async function createNFT() {
    const output = document.getElementById('nftOutput');
    output.textContent = 'Creating NFT...\n';
    output.style.display = 'block';

    try {
        const response = await fetch(`${API_URL}/scripts/create-nft`, {
            method: 'POST'
        });

        const data = await response.json();

        if (data.success) {
            output.textContent = data.stdout;
            showMessage('NFT created successfully!', 'success');
            await fetchBalance();
        } else {
            output.textContent = data.stderr || data.error;
            showMessage('Failed to create NFT', 'error');
        }
    } catch (error) {
        output.textContent = `Error: ${error.message}`;
        showMessage(`Error: ${error.message}`, 'error');
    }
}

// Mint tokens
async function mintTokens() {
    const output = document.getElementById('nftOutput');
    output.textContent = 'Minting tokens...\n';
    output.style.display = 'block';

    try {
        const response = await fetch(`${API_URL}/scripts/mint-tokens`, {
            method: 'POST'
        });

        const data = await response.json();

        if (data.success) {
            output.textContent = data.stdout;
            showMessage('Tokens minted successfully!', 'success');
            await fetchBalance();
        } else {
            output.textContent = data.stderr || data.error;
            showMessage('Failed to mint tokens', 'error');
        }
    } catch (error) {
        output.textContent = `Error: ${error.message}`;
        showMessage(`Error: ${error.message}`, 'error');
    }
}

// Transfer tokens
async function transferTokens() {
    const output = document.getElementById('nftOutput');
    output.textContent = 'Transferring tokens...\n';
    output.style.display = 'block';

    try {
        const response = await fetch(`${API_URL}/scripts/transfer-tokens`, {
            method: 'POST'
        });

        const data = await response.json();

        if (data.success) {
            output.textContent = data.stdout;
            showMessage('Tokens transferred successfully!', 'success');
            await fetchBalance();
        } else {
            output.textContent = data.stderr || data.error;
            showMessage('Failed to transfer tokens', 'error');
        }
    } catch (error) {
        output.textContent = `Error: ${error.message}`;
        showMessage(`Error: ${error.message}`, 'error');
    }
}

// View spell
async function viewSpell() {
    const txid = document.getElementById('txidInput').value.trim();

    if (!txid) {
        showMessage('Please enter a transaction ID', 'warning');
        return;
    }

    const output = document.getElementById('txOutput');
    output.textContent = 'Loading transaction...\n';

    try {
        const response = await fetch(`${API_URL}/scripts/spell`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ txid, detailed: false })
        });

        const data = await response.json();

        if (data.success) {
            output.textContent = data.stdout;
        } else {
            output.textContent = data.stderr || data.error;
            showMessage('Failed to load transaction', 'error');
        }
    } catch (error) {
        output.textContent = `Error: ${error.message}`;
        showMessage(`Error: ${error.message}`, 'error');
    }
}

// Initialize tabs with Flowbite
document.addEventListener('DOMContentLoaded', () => {
    // Initialize Flowbite tabs
    const tabElements = [
        { id: 'dashboard', triggerEl: document.querySelector('#dashboard-tab'), targetEl: document.querySelector('#dashboard') },
        { id: 'send', triggerEl: document.querySelector('#send-tab'), targetEl: document.querySelector('#send') },
        { id: 'balance-check', triggerEl: document.querySelector('#balance-tab'), targetEl: document.querySelector('#balance-check') },
        { id: 'nft', triggerEl: document.querySelector('#nft-tab'), targetEl: document.querySelector('#nft') },
        { id: 'transactions', triggerEl: document.querySelector('#transactions-tab'), targetEl: document.querySelector('#transactions') }
    ];

    // Create tabs instance
    const tabs = new Tabs(tabElements[0].targetEl, tabElements);

    // Show first tab by default
    tabs.show('dashboard');

    // Initialize data fetching
    checkConnection();
    fetchBalance();
    fetchAddress();
    fetchRecentTransactions();

    // Initialize WebSocket
    initWebSocket();

    // Update status every 10 seconds
    setInterval(() => {
        checkConnection();
        fetchBalance();
    }, 10000);

    // Update transactions every 30 seconds
    setInterval(fetchRecentTransactions, 30000);
});

// Simple Tabs implementation if Flowbite's doesn't work
class Tabs {
    constructor(defaultTab, tabElements) {
        this.tabs = tabElements;
        this.init();
    }

    init() {
        this.tabs.forEach(tab => {
            if (tab.triggerEl) {
                tab.triggerEl.addEventListener('click', () => {
                    this.show(tab.id);
                });
            }
        });
    }

    show(tabId) {
        this.tabs.forEach(tab => {
            if (tab.targetEl) {
                if (tab.id === tabId) {
                    tab.targetEl.classList.remove('hidden');
                    if (tab.triggerEl) {
                        tab.triggerEl.classList.add('border-purple-600', 'text-purple-600');
                        tab.triggerEl.setAttribute('aria-selected', 'true');
                    }
                } else {
                    tab.targetEl.classList.add('hidden');
                    if (tab.triggerEl) {
                        tab.triggerEl.classList.remove('border-purple-600', 'text-purple-600');
                        tab.triggerEl.setAttribute('aria-selected', 'false');
                    }
                }
            }
        });
    }
}
