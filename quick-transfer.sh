#!/bin/bash
set -e

# Quick Test Transfer Script
# Sends tokens from default address back to itself

echo "=========================================="
echo "NFTCharm Quick Test Transfer"
echo "=========================================="
echo ""

# Check if Bitcoin Core is running, start if needed
echo "Checking Bitcoin Core status..."
if ! bitcoin-cli getblockchaininfo &>/dev/null; then
    echo "Bitcoin Core not running. Starting bitcoind..."
    bitcoind -daemon
    echo "Waiting for Bitcoin Core to start..."
    sleep 5

    # Wait up to 30 seconds for Bitcoin Core to be ready
    for i in {1..30}; do
        if bitcoin-cli getblockchaininfo &>/dev/null; then
            echo "✓ Bitcoin Core started successfully"
            break
        fi
        sleep 1
    done

    if ! bitcoin-cli getblockchaininfo &>/dev/null; then
        echo "ERROR: Bitcoin Core failed to start"
        exit 1
    fi
else
    echo "✓ Bitcoin Core is running"
fi

# Detect Bitcoin network
NETWORK=$(bitcoin-cli getblockchaininfo 2>/dev/null | jq -r '.chain' || echo "main")
if [ "$NETWORK" = "testnet4" ]; then
    BTC_CLI="bitcoin-cli -testnet4"
    echo "Network: testnet4"
elif [ "$NETWORK" = "test" ]; then
    BTC_CLI="bitcoin-cli -testnet"
    echo "Network: testnet"
elif [ "$NETWORK" = "regtest" ]; then
    BTC_CLI="bitcoin-cli -regtest"
    echo "Network: regtest"
else
    BTC_CLI="bitcoin-cli"
    echo "Network: mainnet"
fi

# Load wallet if not already loaded
echo ""
echo "Checking wallet status..."
if ! $BTC_CLI listwallets | jq -e '.[] | select(. == "nftcharm_wallet")' > /dev/null 2>&1; then
    echo "Loading nftcharm_wallet..."
    $BTC_CLI loadwallet "nftcharm_wallet" > /dev/null 2>&1 || {
        echo "ERROR: Failed to load wallet 'nftcharm_wallet'"
        echo "Make sure the wallet exists"
        exit 1
    }
    echo "✓ Wallet loaded"
else
    echo "✓ Wallet already loaded"
fi

# List available UTXOs
echo ""
echo "Available UTXOs:"
$BTC_CLI -rpcwallet="nftcharm_wallet" listunspent | jq -r '.[] | "\(.txid):\(.vout) - \(.amount) BTC"'
echo ""

# Navigate to my-token directory
cd my-token

# Get verification key
export app_vk=$(charms app vk)
echo "Verification key: $app_vk"

# Set the token UTXO from the minting transaction
# This is the UTXO containing the minted tokens
# WARNING: This should be a MINTED token UTXO, not the NFT UTXO with remaining supply!
export in_utxo_1="d8786af1e7e597d77c073905fd6fd7053e4d12894eefa19c5deb45842fc2a8a2:0"
echo "Token UTXO: $in_utxo_1"
echo ""
echo "⚠️  IMPORTANT: Make sure this is a MINTED token UTXO, not the NFT with remaining supply!"
echo "    You can check by running: ./spell.sh $(echo $in_utxo_1 | cut -d':' -f1)"
echo "    It should show 'MY-TOKEN' tokens, NOT 'Has remaining supply'"
echo ""

# Calculate app_id from the ORIGINAL witness UTXO
# This is the UTXO that created the NFT identity
export original_witness_utxo="f62d75e7c52c1929c63033b797947d8af0f4e720cc5d67be5198e24491818941:0"
export app_id=$(echo -n "$original_witness_utxo" | sha256sum | cut -d' ' -f1)
echo "App ID: $app_id"

# Get addresses - send to same address for testing
echo "Getting new address..."
export addr_3=$($BTC_CLI -rpcwallet="nftcharm_wallet" getnewaddress)
if [ -z "$addr_3" ]; then
    echo "ERROR: Failed to generate address"
    echo "Make sure the 'nftcharm_wallet' wallet is loaded"
    exit 1
fi
export addr_4=$addr_3
echo "Recipient address: $addr_3"
echo "Change address: $addr_4"
echo ""

# Get the token UTXO raw transaction
TOKEN_TXID=$(echo $in_utxo_1 | cut -d':' -f1)
echo "Fetching transaction $TOKEN_TXID..."

# Try to get from local node first, fall back to API if needed
if prev_txs=$($BTC_CLI getrawtransaction "$TOKEN_TXID" 2>/dev/null); then
    echo "✓ Retrieved from local node"
else
    echo "Fetching from mempool.space API..."
    prev_txs=$(curl -s "https://mempool.space/testnet4/api/tx/$TOKEN_TXID/hex")
    if [ -z "$prev_txs" ] || [ "$prev_txs" = "Transaction not found" ]; then
        echo "ERROR: Could not fetch transaction"
        exit 1
    fi
    echo "✓ Retrieved from API"
fi
export prev_txs

echo ""
echo "Spell configuration:"
echo "============================================"
echo "Variables for spell:"
echo "  app_id: $app_id"
echo "  app_vk: $app_vk"
echo "  in_utxo_1: $in_utxo_1"
echo "  addr_3: $addr_3"
echo "  addr_4: $addr_4"
echo ""
echo "Expanded spell YAML:"
cat ./spells/send.yaml | envsubst
echo "============================================"

echo ""
echo "Validating spell..."
app_bin="target/wasm32-wasip1/release/my-token.wasm"
if ! cat ./spells/send.yaml | envsubst | charms spell check --prev-txs=$prev_txs --app-bins=$app_bin; then
    echo "ERROR: Spell validation failed"
    exit 1
fi

echo ""
echo "Getting funding UTXO..."
# Get a UTXO for transaction fees
FUNDING_INFO=$($BTC_CLI -rpcwallet="nftcharm_wallet" listunspent | jq -r '.[] | select(.amount > 0.0001 and (.txid + ":" + (.vout|tostring)) != "'$in_utxo_1'") | "\(.txid):\(.vout) \(.amount)"' | head -n1)

if [ -z "$FUNDING_INFO" ]; then
    echo "ERROR: No suitable funding UTXO found"
    echo "Need a UTXO with > 0.0001 BTC that isn't the token UTXO"
    exit 1
fi

export funding_utxo=$(echo $FUNDING_INFO | cut -d' ' -f1)
funding_amount=$(echo $FUNDING_INFO | cut -d' ' -f2)
export funding_utxo_value=$(echo "$funding_amount * 100000000" | bc | cut -d'.' -f1)
echo "Funding UTXO: $funding_utxo ($funding_amount BTC)"

export change_address=$($BTC_CLI -rpcwallet="nftcharm_wallet" getnewaddress)
echo "Change address: $change_address"

echo ""
echo "Generating proof and transactions..."
export RUST_LOG=info

prove_output=$(cat ./spells/send.yaml | envsubst | \
    charms spell prove \
        --app-bins="target/wasm32-wasip1/release/my-token.wasm" \
        --prev-txs=$prev_txs \
        --funding-utxo=$funding_utxo \
        --funding-utxo-value=$funding_utxo_value \
        --change-address=$change_address)

echo ""
echo "Extracting transactions..."
tx_hex_1=$(echo "$prove_output" | jq -r '.[0].bitcoin')
tx_hex_2=$(echo "$prove_output" | jq -r '.[1].bitcoin')

echo ""
echo "Signing transaction 1 (commit)..."
sign_result_1=$($BTC_CLI -rpcwallet="nftcharm_wallet" signrawtransactionwithwallet "$tx_hex_1")
signed_tx_1=$(echo "$sign_result_1" | jq -r '.hex')
complete_1=$(echo "$sign_result_1" | jq -r '.complete')

if [ "$complete_1" != "true" ]; then
    echo "ERROR: Transaction 1 not fully signed!"
    exit 1
fi
echo "✓ Signed"

echo ""
echo "Testing transaction 1..."
test_result_1=$($BTC_CLI testmempoolaccept "[\"$signed_tx_1\"]")
allowed_1=$(echo "$test_result_1" | jq -r '.[0].allowed')

if [ "$allowed_1" != "true" ]; then
    echo "ERROR: Transaction 1 rejected by mempool!"
    echo "Reason: $(echo "$test_result_1" | jq -r '.[0]."reject-reason"')"
    exit 1
fi
echo "✓ Mempool test passed"

echo ""
echo "Broadcasting transaction 1..."
if txid_1=$($BTC_CLI sendrawtransaction "$signed_tx_1" 2>&1); then
    echo "✓ Transaction 1 broadcast: $txid_1"
else
    echo "ERROR: Broadcast failed: $txid_1"
    exit 1
fi

# Wait a moment for transaction to propagate
sleep 2

echo ""
echo "Fetching transaction 1 details..."
if tx1_raw=$($BTC_CLI getrawtransaction "$txid_1" true 2>/dev/null); then
    tx1_scriptpubkey=$(echo "$tx1_raw" | jq -r '.vout[0].scriptPubKey.hex')
    tx1_amount=$(echo "$tx1_raw" | jq -r '.vout[0].value')
else
    # If not in local mempool yet, decode the signed transaction
    echo "Using decoded transaction..."
    tx1_decoded=$($BTC_CLI decoderawtransaction "$signed_tx_1")
    tx1_scriptpubkey=$(echo "$tx1_decoded" | jq -r '.vout[0].scriptPubKey.hex')
    tx1_amount=$(echo "$tx1_decoded" | jq -r '.vout[0].value')
fi

echo ""
echo "Signing transaction 2 (spell)..."
sign_result_2=$($BTC_CLI -rpcwallet="nftcharm_wallet" signrawtransactionwithwallet "$tx_hex_2" \
    "[{\"txid\":\"$txid_1\",\"vout\":0,\"scriptPubKey\":\"$tx1_scriptpubkey\",\"amount\":$tx1_amount}]")
signed_tx_2=$(echo "$sign_result_2" | jq -r '.hex')
complete_2=$(echo "$sign_result_2" | jq -r '.complete')

if [ "$complete_2" != "true" ]; then
    echo "ERROR: Transaction 2 not fully signed!"
    exit 1
fi
echo "✓ Signed"

echo ""
echo "Testing transaction 2..."
test_result_2=$($BTC_CLI testmempoolaccept "[\"$signed_tx_2\"]")
allowed_2=$(echo "$test_result_2" | jq -r '.[0].allowed')

if [ "$allowed_2" != "true" ]; then
    echo "ERROR: Transaction 2 rejected by mempool!"
    echo "Reason: $(echo "$test_result_2" | jq -r '.[0]."reject-reason"')"
    exit 1
fi
echo "✓ Mempool test passed"

echo ""
echo "Broadcasting transaction 2..."
if txid_2=$($BTC_CLI sendrawtransaction "$signed_tx_2" 2>&1); then
    echo "✓ Transaction 2 broadcast: $txid_2"
else
    echo "ERROR: Broadcast failed: $txid_2"
    exit 1
fi

echo ""
echo "=========================================="
echo "✓ Test Transfer Complete!"
echo "=========================================="
echo "Commit TX: $txid_1"
echo "Spell TX:  $txid_2"
echo ""
echo "View the spell transaction:"
echo "  cd .. && ./spell.sh $txid_2"
echo ""
echo "The token transfer was successful!"
echo "You sent 420 tokens to $addr_3"
echo "and 69000 tokens back to $addr_4 (same address)"
echo "=========================================="
