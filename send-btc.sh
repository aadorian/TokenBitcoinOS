#!/bin/bash
set -e

# Send Bitcoin Transaction Script
# Sends BTC to a specified address using bitcoin-cli

echo "=========================================="
echo "Bitcoin Transaction Sender"
echo "=========================================="
echo ""

# Parse command line arguments
RECIPIENT_ADDRESS="${1:-}"
AMOUNT="${2:-}"

if [ -z "$RECIPIENT_ADDRESS" ]; then
    echo "Usage: ./send-btc.sh <address> <amount> [fee_rate]"
    echo ""
    echo "Example:"
    echo "  ./send-btc.sh tb1q8whwjzcj5lm4e6yppcpa5vu6z5jeu8spvqj9zn 0.001"
    echo "  ./send-btc.sh tb1q8whwjzcj5lm4e6yppcpa5vu6z5jeu8spvqj9zn 0.001 2"
    echo ""
    echo "fee_rate is optional (default: 1 sat/vB for testnet)"
    echo ""
    exit 1
fi

if [ -z "$AMOUNT" ]; then
    echo "Usage: ./send-btc.sh <address> <amount> [fee_rate]"
    echo ""
    echo "Example:"
    echo "  ./send-btc.sh tb1q8whwjzcj5lm4e6yppcpa5vu6z5jeu8spvqj9zn 0.001"
    echo "  ./send-btc.sh tb1q8whwjzcj5lm4e6yppcpa5vu6z5jeu8spvqj9zn 0.001 2"
    echo ""
    echo "fee_rate is optional (default: 1 sat/vB for testnet)"
    echo ""
    exit 1
fi

# Check if Bitcoin Core is running
echo "Checking Bitcoin Core status..."
if ! bitcoin-cli getblockchaininfo &>/dev/null; then
    echo "Bitcoin Core not running. Starting bitcoind..."
    bitcoind -daemon
    sleep 5
    if ! bitcoin-cli getblockchaininfo &>/dev/null; then
        echo "ERROR: Bitcoin Core failed to start"
        exit 1
    fi
    echo "✓ Bitcoin Core started"
else
    echo "✓ Bitcoin Core is running"
fi

# Detect network
NETWORK=$(bitcoin-cli getblockchaininfo 2>/dev/null | jq -r '.chain' || echo "main")
if [ "$NETWORK" = "testnet4" ]; then
    BTC_CLI="bitcoin-cli -testnet4"
    echo "Network: testnet4"
elif [ "$NETWORK" = "test" ]; then
    BTC_CLI="bitcoin-cli -testnet"
    echo "Network: testnet"
else
    BTC_CLI="bitcoin-cli"
    echo "Network: mainnet"
fi

# Load wallet
echo ""
echo "Loading wallet..."
if ! $BTC_CLI listwallets | jq -e '.[] | select(. == "nftcharm_wallet")' > /dev/null 2>&1; then
    $BTC_CLI loadwallet "nftcharm_wallet" > /dev/null 2>&1
    echo "✓ Wallet loaded"
else
    echo "✓ Wallet already loaded"
fi

# Check wallet balance
echo ""
echo "Checking wallet balance..."
BALANCE=$($BTC_CLI -rpcwallet="nftcharm_wallet" getbalance)
echo "Available balance: $BALANCE BTC"

# Validate amount
if (( $(echo "$AMOUNT > $BALANCE" | bc -l) )); then
    echo "ERROR: Insufficient balance. You have $BALANCE BTC but trying to send $AMOUNT BTC"
    exit 1
fi

# Set fee rate
FEE_RATE="${3:-1}"

# Display transaction details
echo ""
echo "=========================================="
echo "Transaction Details:"
echo "=========================================="
echo "Recipient: $RECIPIENT_ADDRESS"
echo "Amount:    $AMOUNT BTC"
echo "Fee Rate:  $FEE_RATE sat/vB"
echo "Network:   $NETWORK"
echo "=========================================="
echo ""

# Confirm transaction
read -p "Do you want to proceed? (yes/no): " CONFIRM
CONFIRM_LOWER=$(echo "$CONFIRM" | tr '[:upper:]' '[:lower:]')
if [ "$CONFIRM_LOWER" != "yes" ] && [ "$CONFIRM_LOWER" != "y" ]; then
    echo "Transaction cancelled."
    exit 0
fi

# Send transaction
echo ""
echo "Sending transaction..."
if TXID=$($BTC_CLI -rpcwallet="nftcharm_wallet" -named sendtoaddress address="$RECIPIENT_ADDRESS" amount="$AMOUNT" fee_rate="$FEE_RATE" 2>&1); then
    echo ""
    echo "=========================================="
    echo "✓ Transaction Sent Successfully!"
    echo "=========================================="
    echo "Transaction ID: $TXID"
    echo ""
    echo "You can check the transaction status with:"
    echo "  $BTC_CLI gettransaction $TXID"
    echo ""
    if [ "$NETWORK" = "testnet4" ] || [ "$NETWORK" = "test" ]; then
        echo "View on explorer:"
        echo "  https://mempool.space/testnet/tx/$TXID"
    else
        echo "View on explorer:"
        echo "  https://mempool.space/tx/$TXID"
    fi
    echo "=========================================="
else
    echo ""
    echo "=========================================="
    echo "ERROR: Transaction Failed"
    echo "=========================================="
    echo "$TXID"
    echo "=========================================="
    exit 1
fi
