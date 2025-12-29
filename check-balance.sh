#!/bin/bash
set -e

# Token Balance Checker Script
# Scans wallet UTXOs and displays token balances

echo "=========================================="
echo "NFTCharm Token Balance Checker"
echo "=========================================="
echo ""

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

# Get wallet info
echo ""
echo "=========================================="
echo "Wallet Information"
echo "=========================================="
WALLET_ADDRESS=$($BTC_CLI -rpcwallet="nftcharm_wallet" getaddressesbylabel "" | jq -r 'keys[0]' 2>/dev/null)
if [ -z "$WALLET_ADDRESS" ] || [ "$WALLET_ADDRESS" = "null" ]; then
    WALLET_ADDRESS=$($BTC_CLI -rpcwallet="nftcharm_wallet" getnewaddress)
fi
echo "Primary address: $WALLET_ADDRESS"

# Get BTC balance
BTC_BALANCE=$($BTC_CLI -rpcwallet="nftcharm_wallet" getbalance)
echo "BTC balance:     $BTC_BALANCE BTC"
echo ""

# Navigate to my-token directory if it exists
if [ -d "my-token" ]; then
    cd my-token

    # Get app details
    echo "Getting token app details..."
    export app_vk=$(charms app vk 2>/dev/null || echo "")

    if [ -n "$app_vk" ]; then
        echo "App VK: $app_vk"
        echo ""
    fi

    cd ..
else
    echo "Note: my-token directory not found, will scan for token UTXOs without app verification"
    echo ""
fi

# Scan UTXOs for tokens
echo "=========================================="
echo "Scanning for Token UTXOs"
echo "=========================================="
echo ""

UTXOS=$($BTC_CLI -rpcwallet="nftcharm_wallet" listunspent)
TOTAL_UTXOS=$(echo "$UTXOS" | jq 'length')

echo "Total UTXOs in wallet: $TOTAL_UTXOS"
echo ""

# Track token balances
declare -A TOKEN_BALANCES
TOTAL_TOKENS=0
TOKEN_UTXO_COUNT=0
NFT_UTXO_COUNT=0

echo "Analyzing UTXOs..."
echo ""

# Function to extract token info from witness data
extract_token_info() {
    local txid=$1
    local vout=$2

    # Get raw transaction
    if tx_raw=$($BTC_CLI getrawtransaction "$txid" true 2>/dev/null); then
        # Check witness data in inputs for token information
        witness_data=$(echo "$tx_raw" | jq -r ".vin[].txinwitness[]?" 2>/dev/null | head -1)

        if [ -n "$witness_data" ]; then
            # Try to decode witness data for token information
            decoded_text=$(echo "$witness_data" | xxd -r -p 2>/dev/null | strings -n 4 2>/dev/null || echo "")

            if echo "$decoded_text" | grep -q "MY-TOKEN"; then
                # Look for token amount patterns
                # This is a simplified extraction - actual implementation may vary
                return 0
            fi
        fi
    fi

    return 1
}

# Categorize UTXOs
while IFS= read -r utxo_entry; do
    utxo_id=$(echo "$utxo_entry" | jq -r '.txid + ":" + (.vout|tostring)')
    utxo_amount=$(echo "$utxo_entry" | jq -r '.amount')
    address=$(echo "$utxo_entry" | jq -r '.address')
    confirmations=$(echo "$utxo_entry" | jq -r '.confirmations')

    txid=$(echo "$utxo_id" | cut -d':' -f1)
    vout=$(echo "$utxo_id" | cut -d':' -f2)

    # Check if this is a dust UTXO (likely contains tokens)
    if (( $(echo "$utxo_amount < 0.0001" | bc -l) )); then
        # This is likely a token/NFT UTXO
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "UTXO: $utxo_id"
        echo "Amount: $utxo_amount BTC (dust)"
        echo "Address: $address"
        echo "Confirmations: $confirmations"

        # Try to get transaction details
        if tx_raw=$($BTC_CLI getrawtransaction "$txid" true 2>/dev/null); then
            # Check witness data for token/NFT info
            has_witness=$(echo "$tx_raw" | jq -r '.vin[].txinwitness // empty' 2>/dev/null | head -1)

            if [ -n "$has_witness" ]; then
                echo "Type: Token/NFT UTXO (has witness data)"

                # Try to extract token ticker from witness
                witness_items=$(echo "$tx_raw" | jq -r '.vin[].txinwitness[]?' 2>/dev/null)
                for witness in $witness_items; do
                    decoded_text=$(echo "$witness" | xxd -r -p 2>/dev/null | strings -n 4 2>/dev/null || echo "")

                    if echo "$decoded_text" | grep -q "MY-TOKEN"; then
                        echo "Ticker: MY-TOKEN"

                        # Check if it's an NFT (has "remaining") or regular token
                        if echo "$decoded_text" | grep -q "remaining"; then
                            echo "Note: This appears to be an NFT (has remaining supply)"
                            NFT_UTXO_COUNT=$((NFT_UTXO_COUNT + 1))
                        else
                            echo "Note: This appears to be a token UTXO"
                            TOKEN_UTXO_COUNT=$((TOKEN_UTXO_COUNT + 1))
                        fi

                        # Try to extract amount (simplified - may need enhancement)
                        echo "Info: Use ./spell.sh $txid to see full token details"
                        break
                    fi
                done
            else
                echo "Type: Dust UTXO (no witness data)"
            fi
        else
            echo "Type: Unknown (cannot fetch transaction)"
        fi

        echo ""
    fi
done < <(echo "$UTXOS" | jq -c '.[]')

# Summary
echo "=========================================="
echo "Summary"
echo "=========================================="
echo "Total BTC:        $BTC_BALANCE BTC"
echo "Total UTXOs:      $TOTAL_UTXOS"
echo "Token UTXOs:      $TOKEN_UTXO_COUNT"
echo "NFT UTXOs:        $NFT_UTXO_COUNT"
echo ""

if [ $TOKEN_UTXO_COUNT -eq 0 ] && [ $NFT_UTXO_COUNT -eq 0 ]; then
    echo "No token or NFT UTXOs found in wallet."
    echo ""
    echo "To create tokens:"
    echo "  1. Run ./create-nft.sh to create an NFT"
    echo "  2. Run ./mint-tokens.sh to mint tokens from the NFT"
else
    echo "To view detailed token information for any UTXO:"
    echo "  ./spell.sh <txid> [--detailed]"
    echo ""
    echo "To transfer tokens:"
    echo "  ./transfer-tokens.sh"
fi
echo "=========================================="
