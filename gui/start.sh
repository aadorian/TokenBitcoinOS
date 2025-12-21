#!/bin/bash

# NFTCharm Viewer Startup Script

echo "╔════════════════════════════════════════════╗"
echo "║     NFTCharm Viewer - Startup Script      ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed."
    echo "   Please install Node.js from https://nodejs.org/"
    exit 1
fi

echo "✓ Node.js detected: $(node --version)"
echo ""

# Check if Bitcoin Core is running
echo "Checking Bitcoin Core connection..."
if bitcoin-cli -testnet4 getblockchaininfo &> /dev/null; then
    echo "✓ Bitcoin Core is running on testnet4"

    # Check if wallet is loaded
    if bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" getwalletinfo &> /dev/null; then
        echo "✓ Wallet 'nftcharm_wallet' is loaded"

        # Get and display current balance
        BALANCE=$(bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" getbalance)
        echo "✓ Current balance: $BALANCE BTC"
    else
        echo "⚠️  Wallet 'nftcharm_wallet' is not loaded"
        echo "   Loading wallet..."
        if bitcoin-cli -testnet4 loadwallet "nftcharm_wallet" &> /dev/null; then
            echo "✓ Wallet loaded successfully"
            BALANCE=$(bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" getbalance)
            echo "✓ Current balance: $BALANCE BTC"
        else
            echo "❌ Failed to load wallet 'nftcharm_wallet'"
            echo "   Please ensure the wallet exists"
        fi
    fi
else
    echo "❌ Cannot connect to Bitcoin Core"
    echo "   Please ensure Bitcoin Core is running with testnet4"
    exit 1
fi

echo ""

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
    echo ""
fi

# Start the server
echo "════════════════════════════════════════════"
echo "Starting NFTCharm Viewer..."
echo "════════════════════════════════════════════"
echo ""
echo "Open your browser and navigate to:"
echo "  http://localhost:3000"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

npm start
