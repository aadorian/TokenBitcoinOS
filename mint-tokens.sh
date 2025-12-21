#!/bin/bash
set -e

# Mint Tokens Script
# Mints tokens from an NFT with remaining supply

echo "=========================================="
echo "NFTCharm Token Minting"
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

# Get app details
echo ""
echo "Getting app details..."
export app_vk=$(charms app vk)
export original_witness_utxo="f62d75e7c52c1929c63033b797947d8af0f4e720cc5d67be5198e24491818941:0"
export app_id=$(echo -n "$original_witness_utxo" | sha256sum | cut -d' ' -f1)
echo "App ID: $app_id"
echo "App VK: $app_vk"

# Set NFT UTXO (the one with remaining supply)
export in_utxo_1="d8786af1e7e597d77c073905fd6fd7053e4d12894eefa19c5deb45842fc2a8a2:0"
echo ""
echo "NFT UTXO: $in_utxo_1"

# Get addresses for outputs
export addr_1=$($BTC_CLI -rpcwallet="nftcharm_wallet" getnewaddress)
export addr_2=$($BTC_CLI -rpcwallet="nftcharm_wallet" getnewaddress)
echo "Token output address: $addr_1"
echo "NFT change address: $addr_2"

# Get the NFT transaction
echo ""
echo "Fetching NFT transaction..."
nft_txid=$(echo $in_utxo_1 | cut -d':' -f1)
export prev_txs=$($BTC_CLI -rpcwallet="nftcharm_wallet" gettransaction "$nft_txid" 2>/dev/null | jq -r '.hex')
if [ -z "$prev_txs" ] || [ "$prev_txs" = "null" ]; then
    echo "ERROR: Failed to fetch NFT transaction"
    exit 1
fi
echo "✓ NFT transaction fetched"

# Display the spell
echo ""
echo "Mint Spell:"
echo "============================================"
cat ./spells/mint-token.yaml | envsubst
echo "============================================"

# Validate spell
echo ""
echo "Validating spell..."
app_bin="target/wasm32-wasip1/release/my-token.wasm"
if ! cat ./spells/mint-token.yaml | envsubst | charms spell check --prev-txs=$prev_txs --app-bins=$app_bin; then
    echo "ERROR: Spell validation failed"
    exit 1
fi
echo "✓ Spell valid"

# Get funding UTXO
echo ""
echo "Getting funding UTXO..."
FUNDING_INFO=$($BTC_CLI -rpcwallet="nftcharm_wallet" listunspent | jq -r '.[] | select(.amount > 0.0001 and (.txid + ":" + (.vout|tostring)) != "'$in_utxo_1'") | "\(.txid):\(.vout) \(.amount)"' | head -n1)

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

prove_output=$(cat ./spells/mint-token.yaml | envsubst | \
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
echo "✓ Token Minting Complete!"
echo "=========================================="
echo "Commit TX: $txid_1"
echo "Spell TX:  $txid_2"
echo ""
echo "Minted 69,420 tokens to: $addr_1"
echo "NFT with 30,580 remaining to: $addr_2"
echo ""
echo "To find your token UTXO, run:"
echo "  bitcoin-cli -testnet4 -rpcwallet=\"nftcharm_wallet\" listunspent"
echo ""
echo "The token UTXO will be: $txid_2:0"
echo "Use this UTXO in transfer-tokens.sh"
echo "=========================================="
