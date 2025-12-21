#!/bin/bash
set -e

# Create New NFT Script
# Creates a fresh NFT with proper witness data for token minting

echo "=========================================="
echo "NFTCharm - Create New NFT"
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

# Navigate to my-token directory
cd my-token

# Get app verification key
echo ""
echo "Getting app details..."
export app_vk=$(charms app vk)
echo "App VK: $app_vk"

# Select a new witness UTXO (use any unspent UTXO with sufficient BTC)
echo ""
echo "Selecting witness UTXO..."
WITNESS_INFO=$($BTC_CLI -rpcwallet="nftcharm_wallet" listunspent | jq -r '.[] | select(.amount > 0.0001) | "\(.txid):\(.vout) \(.amount)"' | head -n1)

if [ -z "$WITNESS_INFO" ]; then
    echo "ERROR: No suitable witness UTXO found"
    echo "You need a UTXO with > 0.0001 BTC"
    exit 1
fi

export witness_utxo=$(echo $WITNESS_INFO | cut -d' ' -f1)
witness_amount=$(echo $WITNESS_INFO | cut -d' ' -f2)
echo "Witness UTXO: $witness_utxo ($witness_amount BTC)"

# Calculate new app_id from this witness UTXO
export new_app_id=$(echo -n "$witness_utxo" | sha256sum | cut -d' ' -f1)
echo "New App ID: $new_app_id"

# Get output address for the NFT
export nft_address=$($BTC_CLI -rpcwallet="nftcharm_wallet" getnewaddress)
echo "NFT output address: $nft_address"

# Get the witness transaction
echo ""
echo "Fetching witness transaction..."
witness_txid=$(echo $witness_utxo | cut -d':' -f1)
export prev_txs=$($BTC_CLI -rpcwallet="nftcharm_wallet" gettransaction "$witness_txid" 2>/dev/null | jq -r '.hex')
if [ -z "$prev_txs" ] || [ "$prev_txs" = "null" ]; then
    echo "ERROR: Failed to fetch witness transaction"
    exit 1
fi
echo "✓ Witness transaction fetched"

# Create NFT spell YAML
echo ""
echo "Creating NFT spell..."
cat > /tmp/create_nft.yaml <<EOF
version: 8

apps:
  \$00: n/$new_app_id/$app_vk

private_inputs:
  \$00: "$witness_utxo"

ins:
  - utxo_id: $witness_utxo
    charms: {}

outs:
  - address: $nft_address
    charms:
      \$00:
        ticker: MY-TOKEN
        remaining: 100000
EOF

echo "NFT Spell:"
echo "============================================"
cat /tmp/create_nft.yaml
echo "============================================"

# Validate spell
echo ""
echo "Validating spell..."
app_bin="target/wasm32-wasip1/release/my-token.wasm"
if ! cat /tmp/create_nft.yaml | charms spell check --prev-txs=$prev_txs --app-bins=$app_bin; then
    echo "ERROR: Spell validation failed"
    exit 1
fi
echo "✓ Spell valid"

# Get funding UTXO (different from witness)
echo ""
echo "Getting funding UTXO..."
FUNDING_INFO=$($BTC_CLI -rpcwallet="nftcharm_wallet" listunspent | jq -r '.[] | select(.amount > 0.0001 and (.txid + ":" + (.vout|tostring)) != "'$witness_utxo'") | "\(.txid):\(.vout) \(.amount)"' | head -n1)

if [ -z "$FUNDING_INFO" ]; then
    echo "ERROR: No suitable funding UTXO found"
    exit 1
fi

export funding_utxo=$(echo $FUNDING_INFO | cut -d' ' -f1)
funding_amount=$(echo $FUNDING_INFO | cut -d' ' -f2)
export funding_utxo_value=$(echo "$funding_amount * 100000000" | bc | cut -d'.' -f1)
echo "Funding: $funding_utxo ($funding_amount BTC)"

export change_address=$($BTC_CLI -rpcwallet="nftcharm_wallet" getnewaddress)
echo "Change address: $change_address"

# Generate proof and transactions
echo ""
echo "Generating proof and transactions..."
export RUST_LOG=info

prove_output=$(cat /tmp/create_nft.yaml | \
    charms spell prove \
        --app-bins="$app_bin" \
        --prev-txs=$prev_txs \
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
echo "✓ NFT Created Successfully!"
echo "=========================================="
echo "Commit TX: $txid_1"
echo "NFT TX:    $txid_2"
echo ""
echo "NFT UTXO: $txid_2:0"
echo "App ID:   $new_app_id"
echo ""
echo "This NFT has 100,000 remaining supply."
echo ""
echo "To use this NFT for minting tokens:"
echo "1. Update mint-tokens.sh with:"
echo "   export in_utxo_1=\"$txid_2:0\""
echo "   export original_witness_utxo=\"$witness_utxo\""
echo ""
echo "2. Then run: ./mint-tokens.sh"
echo "=========================================="
