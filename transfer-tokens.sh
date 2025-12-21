#!/bin/bash
set -e

# Token Transfer Script
# Transfers tokens between addresses using custom JSON spell format

echo "=========================================="
echo "NFTCharm Token Transfer"
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

# Display wallet info
echo ""
echo "==========================================="
echo "Wallet Information"
echo "==========================================="
WALLET_ADDRESS=$($BTC_CLI -rpcwallet="nftcharm_wallet" getaddressesbylabel "" | jq -r 'keys[0]' 2>/dev/null)
if [ -z "$WALLET_ADDRESS" ] || [ "$WALLET_ADDRESS" = "null" ]; then
    WALLET_ADDRESS=$($BTC_CLI -rpcwallet="nftcharm_wallet" getnewaddress)
fi
echo "Primary address: $WALLET_ADDRESS"

# Get wallet balance
WALLET_BALANCE=$($BTC_CLI -rpcwallet="nftcharm_wallet" getbalance)
echo "Total BTC balance: $WALLET_BALANCE BTC"
echo ""

# List UTXOs sorted by BTC amount (descending)
echo "==========================================="
echo "Available UTXOs (sorted by BTC amount)"
echo "==========================================="
echo ""
echo "UTXOs with BTC (for funding):"
$BTC_CLI -rpcwallet="nftcharm_wallet" listunspent | jq -r 'sort_by(-.amount) | .[] | "\(.txid):\(.vout) - \(.amount) BTC"'
echo ""

echo "Note: Use UTXOs with higher BTC amounts for funding transaction fees."
echo "      Token UTXOs will typically have small BTC amounts (dust)."
echo ""

# Navigate to my-token directory
cd my-token

# Get app details
export app_vk=$(charms app vk)
export original_witness_utxo="f62d75e7c52c1929c63033b797947d8af0f4e720cc5d67be5198e24491818941:0"
export app_id=$(echo -n "$original_witness_utxo" | sha256sum | cut -d' ' -f1)

echo "==========================================="
echo "Token Information"
echo "==========================================="
echo "App ID: $app_id"
echo "App VK: $app_vk"
echo ""

# Scan UTXOs for token balances
echo "Scanning for token balances..."
TOTAL_TOKENS=0
TOKEN_UTXOS=()

# Get all UTXOs from wallet
cd ..
UTXOS=$($BTC_CLI -rpcwallet="nftcharm_wallet" listunspent)
cd my-token

# Check each UTXO for tokens
while IFS= read -r utxo_entry; do
    utxo_id=$(echo "$utxo_entry" | jq -r '.txid + ":" + (.vout|tostring)')
    utxo_amount=$(echo "$utxo_entry" | jq -r '.amount')

    # Try to fetch and decode the transaction to check for tokens
    txid=$(echo "$utxo_id" | cut -d':' -f1)
    vout=$(echo "$utxo_id" | cut -d':' -f2)

    # Get raw transaction
    if tx_raw=$($BTC_CLI getrawtransaction "$txid" true 2>/dev/null); then
        # Check if this output has witness data that might contain token information
        witness=$($BTC_CLI getrawtransaction "$txid" true 2>/dev/null | jq -r ".vin[].txinwitness // empty" 2>/dev/null)

        # For now, we'll mark UTXOs with very small amounts as potential token UTXOs
        # A proper implementation would decode the witness data
        if (( $(echo "$utxo_amount < 0.0001" | bc -l) )); then
            # This is likely a token UTXO (has dust amount)
            # You would need to properly decode witness data to get exact token amount
            TOKEN_UTXOS+=("$utxo_id ($utxo_amount BTC)")
        fi
    fi
done < <(echo "$UTXOS" | jq -c '.[]')

if [ ${#TOKEN_UTXOS[@]} -gt 0 ]; then
    echo "Token UTXOs found (${#TOKEN_UTXOS[@]}):"
    for token_utxo in "${TOKEN_UTXOS[@]}"; do
        echo "  $token_utxo"
    done
else
    echo "No token UTXOs found in wallet"
fi

echo ""
echo "Note: To see exact token amounts, you need to decode the witness data"
echo "      or use the spell viewer on each UTXO"
echo ""
echo "==========================================="
echo ""

# Default values
DEFAULT_WALLET_ADDR="tb1p0hewpmw7guc6675fezgdyasc43ma73f35j9wgpkup5chuut6547q6tathe"
# This should be a token UTXO (type t/), not an NFT (type n/)
# If you only have an NFT, you need to mint tokens first
DEFAULT_TOKEN_UTXO=""
DEFAULT_TRANSFER_AMOUNT="100"

# Prompt for source UTXOs
echo "Enter source UTXO(s) with tokens (separated by semicolon for multiple):"
echo "Default: $DEFAULT_TOKEN_UTXO"
read -p "Source UTXOs [Enter for default]: " SOURCE_UTXOS_INPUT
SOURCE_UTXOS_INPUT=${SOURCE_UTXOS_INPUT:-$DEFAULT_TOKEN_UTXO}

echo ""
echo "Enter token amount(s) for each source UTXO (same order, separated by semicolon):"
echo "Default: $DEFAULT_TRANSFER_AMOUNT tokens"
read -p "Source amounts [Enter for default]: " SOURCE_AMOUNTS_INPUT
SOURCE_AMOUNTS_INPUT=${SOURCE_AMOUNTS_INPUT:-$DEFAULT_TRANSFER_AMOUNT}

# Prompt for destination addresses and amounts separately
echo ""
echo "Enter destination address(es) (separated by semicolon for multiple):"
echo "Default: $DEFAULT_WALLET_ADDR (same wallet)"
read -p "Destination addresses [Enter for default]: " DEST_ADDRS_INPUT
DEST_ADDRS_INPUT=${DEST_ADDRS_INPUT:-$DEFAULT_WALLET_ADDR}

echo ""
echo "Enter corresponding amount(s) (same order as addresses, separated by semicolon):"
echo "Default: $DEFAULT_TRANSFER_AMOUNT tokens"
read -p "Amounts [Enter for default]: " DEST_AMOUNTS_INPUT
DEST_AMOUNTS_INPUT=${DEST_AMOUNTS_INPUT:-$DEFAULT_TRANSFER_AMOUNT}

# Parse source UTXOs
IFS=';' read -ra SOURCE_UTXOS_ARRAY <<< "$SOURCE_UTXOS_INPUT"
IFS=';' read -ra SOURCE_AMOUNTS_ARRAY <<< "$SOURCE_AMOUNTS_INPUT"

# Check if arrays have same length
if [ ${#SOURCE_UTXOS_ARRAY[@]} -ne ${#SOURCE_AMOUNTS_ARRAY[@]} ]; then
    echo ""
    echo "ERROR: Number of source UTXOs (${#SOURCE_UTXOS_ARRAY[@]}) doesn't match number of amounts (${#SOURCE_AMOUNTS_ARRAY[@]})"
    exit 1
fi

SOURCE_UTXOS=""
PREV_TXS=""
TOTAL_INPUT=0

echo ""
echo "Processing source UTXOs..."
for i in "${!SOURCE_UTXOS_ARRAY[@]}"; do
    # Trim whitespace
    utxo=$(echo "${SOURCE_UTXOS_ARRAY[$i]}" | xargs)
    amount=$(echo "${SOURCE_AMOUNTS_ARRAY[$i]}" | xargs)

    SOURCE_UTXOS+="    {\"utxo_id\": \"$utxo\", \"charms\": {\"\$00\": $amount}},"
    TOTAL_INPUT=$((TOTAL_INPUT + amount))

    # Fetch transaction
    txid=$(echo $utxo | cut -d':' -f1)
    echo "  Fetching $txid ($amount tokens)..."
    if tx_hex=$($BTC_CLI -rpcwallet="nftcharm_wallet" gettransaction "$txid" 2>/dev/null | jq -r '.hex'); then
        if [ -n "$tx_hex" ] && [ "$tx_hex" != "null" ]; then
            PREV_TXS+="$tx_hex,"
        fi
    fi
done

# Remove trailing commas
SOURCE_UTXOS=${SOURCE_UTXOS%,}
PREV_TXS=${PREV_TXS%,}

# Parse destinations
IFS=';' read -ra DEST_ADDRS_ARRAY <<< "$DEST_ADDRS_INPUT"
IFS=';' read -ra DEST_AMOUNTS_ARRAY <<< "$DEST_AMOUNTS_INPUT"

# Check if arrays have same length
if [ ${#DEST_ADDRS_ARRAY[@]} -ne ${#DEST_AMOUNTS_ARRAY[@]} ]; then
    echo ""
    echo "ERROR: Number of addresses (${#DEST_ADDRS_ARRAY[@]}) doesn't match number of amounts (${#DEST_AMOUNTS_ARRAY[@]})"
    exit 1
fi

DEST_OUTPUTS=""
TOTAL_OUTPUT=0

echo ""
echo "Processing destinations..."
for i in "${!DEST_ADDRS_ARRAY[@]}"; do
    # Trim whitespace
    address=$(echo "${DEST_ADDRS_ARRAY[$i]}" | xargs)
    amount=$(echo "${DEST_AMOUNTS_ARRAY[$i]}" | xargs)

    DEST_OUTPUTS+="    {\"address\": \"$address\", \"charms\": {\"\$00\": $amount}},"
    TOTAL_OUTPUT=$((TOTAL_OUTPUT + amount))
    echo "  $address: $amount tokens"
done

# Remove trailing comma
DEST_OUTPUTS=${DEST_OUTPUTS%,}

# Validate amounts
if [ $TOTAL_INPUT -ne $TOTAL_OUTPUT ]; then
    echo ""
    echo "ERROR: Input ($TOTAL_INPUT) and output ($TOTAL_OUTPUT) amounts don't match!"
    exit 1
fi

echo ""
echo "✓ Amounts balanced: $TOTAL_INPUT tokens"

# Generate spell JSON
SPELL_JSON=$(cat <<EOF
{
  "version": 8,
  "apps": {
    "\$00": "t/$app_id/$app_vk"
  },
  "ins": [
$SOURCE_UTXOS
  ],
  "outs": [
$DEST_OUTPUTS
  ]
}
EOF
)

echo ""
echo "Generated Spell:"
echo "============================================"
echo "$SPELL_JSON"
echo "============================================"

# Get funding UTXO
echo ""
echo "Getting funding UTXO..."
FUNDING_INFO=$($BTC_CLI -rpcwallet="nftcharm_wallet" listunspent | jq -r '.[] | select(.amount > 0.0001) | "\(.txid):\(.vout) \(.amount)"' | head -n1)

if [ -z "$FUNDING_INFO" ]; then
    echo "ERROR: No suitable funding UTXO found"
    exit 1
fi

funding_utxo=$(echo $FUNDING_INFO | cut -d' ' -f1)
funding_amount=$(echo $FUNDING_INFO | cut -d' ' -f2)
funding_utxo_value=$(echo "$funding_amount * 100000000" | bc | cut -d'.' -f1)
echo "Funding: $funding_utxo ($funding_amount BTC)"

change_address=$($BTC_CLI -rpcwallet="nftcharm_wallet" getnewaddress)
echo "Change address: $change_address"

# Validate spell
echo ""
echo "Validating spell..."
if ! echo "$SPELL_JSON" | charms spell check --prev-txs=$PREV_TXS --app-bins="target/wasm32-wasip1/release/my-token.wasm"; then
    echo "ERROR: Spell validation failed"
    exit 1
fi
echo "✓ Spell valid"

# Generate proof and transactions
echo ""
echo "Generating proof and transactions..."
export RUST_LOG=info

prove_output=$(echo "$SPELL_JSON" | \
    charms spell prove \
        --app-bins="target/wasm32-wasip1/release/my-token.wasm" \
        --prev-txs=$PREV_TXS \
        --funding-utxo=$funding_utxo \
        --funding-utxo-value=$funding_utxo_value \
        --change-address=$change_address)

tx_hex_1=$(echo "$prove_output" | jq -r '.[0].bitcoin')
tx_hex_2=$(echo "$prove_output" | jq -r '.[1].bitcoin')

# Sign and broadcast transaction 1
echo ""
echo "Signing transaction 1..."
sign_result_1=$($BTC_CLI -rpcwallet="nftcharm_wallet" signrawtransactionwithwallet "$tx_hex_1")
signed_tx_1=$(echo "$sign_result_1" | jq -r '.hex')
complete_1=$(echo "$sign_result_1" | jq -r '.complete')

if [ "$complete_1" != "true" ]; then
    echo "ERROR: Transaction 1 not fully signed!"
    exit 1
fi

echo "Broadcasting transaction 1..."
if txid_1=$($BTC_CLI sendrawtransaction "$signed_tx_1" 2>&1); then
    echo "✓ TX1: $txid_1"
else
    echo "ERROR: $txid_1"
    exit 1
fi

sleep 2

# Get TX1 details
if tx1_raw=$($BTC_CLI getrawtransaction "$txid_1" true 2>/dev/null); then
    tx1_scriptpubkey=$(echo "$tx1_raw" | jq -r '.vout[0].scriptPubKey.hex')
    tx1_amount=$(echo "$tx1_raw" | jq -r '.vout[0].value')
else
    tx1_decoded=$($BTC_CLI decoderawtransaction "$signed_tx_1")
    tx1_scriptpubkey=$(echo "$tx1_decoded" | jq -r '.vout[0].scriptPubKey.hex')
    tx1_amount=$(echo "$tx1_decoded" | jq -r '.vout[0].value')
fi

# Sign and broadcast transaction 2
echo ""
echo "Signing transaction 2..."
sign_result_2=$($BTC_CLI -rpcwallet="nftcharm_wallet" signrawtransactionwithwallet "$tx_hex_2" \
    "[{\"txid\":\"$txid_1\",\"vout\":0,\"scriptPubKey\":\"$tx1_scriptpubkey\",\"amount\":$tx1_amount}]")
signed_tx_2=$(echo "$sign_result_2" | jq -r '.hex')
complete_2=$(echo "$sign_result_2" | jq -r '.complete')

if [ "$complete_2" != "true" ]; then
    echo "ERROR: Transaction 2 not fully signed!"
    exit 1
fi

echo "Broadcasting transaction 2..."
if txid_2=$($BTC_CLI sendrawtransaction "$signed_tx_2" 2>&1); then
    echo "✓ TX2: $txid_2"
else
    echo "ERROR: $txid_2"
    exit 1
fi

echo ""
echo "=========================================="
echo "✓ Token Transfer Complete!"
echo "=========================================="
echo "Commit TX: $txid_1"
echo "Spell TX:  $txid_2"
echo ""
echo "Transferred $TOTAL_INPUT tokens"
echo ""
echo "View transaction:"
echo "  cd .. && ./spell.sh $txid_2"
echo "=========================================="
