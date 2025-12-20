#!/bin/bash
set -e

# Helper function to pause and show action
pause_and_show() {
    echo ""
    echo "==> $1"
    sleep 2
}

# Step 1: Set up temporary cargo target directory
pause_and_show "Setting up temporary cargo target directory..."
export CARGO_TARGET_DIR=$(mktemp -d)/target
echo "CARGO_TARGET_DIR set to: $CARGO_TARGET_DIR"

# Step 2: Check if charms is installed, install if not
pause_and_show "Checking if charms CLI is installed..."
if ! command -v charms &> /dev/null; then
    echo "charms not found, installing version 0.10.0..."
    cargo install charms --version=0.10.0
else
    echo "charms is already installed"
fi

# Step 3: Check if spell template exists, create if not
pause_and_show "Checking for spell template (my-token)..."
if [ ! -d "my-token" ]; then
    echo "Spell template not found, creating my-token..."
    charms app new my-token
else
    echo "Spell template my-token already exists"
fi

# Step 4: Navigate to my-token directory
pause_and_show "Navigating to my-token directory..."
cd ./my-token
echo "Changed directory to my-token"

# Step 5: Unset CARGO_TARGET_DIR
pause_and_show "Unsetting CARGO_TARGET_DIR..."
unset CARGO_TARGET_DIR
echo "CARGO_TARGET_DIR unset"

# Step 6: Update cargo dependencies
pause_and_show "Updating cargo dependencies..."
cargo update

# Step 7: Build app and generate verification key
pause_and_show "Building app and generating verification key..."
app_bin=$(charms app build)
charms app vk "$app_bin"

# Step 8: Export verification key
pause_and_show "Exporting verification key..."
export app_vk=$(charms app vk "$app_bin")
echo "app_vk exported: $app_vk"

# Step 9: Check if bitcoind is running, start if not
pause_and_show "Checking if bitcoind is running..."
if ! bitcoin-cli getblockchaininfo &> /dev/null; then
    echo "Bitcoin server not running, starting bitcoind..."
    bitcoind -daemon
    echo "Waiting for bitcoind to start..."
    sleep 5
    # Wait for server to be ready
    until bitcoin-cli getblockchaininfo &> /dev/null; do
        echo "Waiting for bitcoind to be ready..."
        sleep 2
    done
    echo "bitcoind started successfully"
else
    echo "bitcoind is already running"
fi

# Step 10: Load or create wallet
pause_and_show "Checking for wallet (nftcharm_wallet)..."
wallet_name="nftcharm_wallet"

# Check if wallet is already loaded
if bitcoin-cli listwallets | jq -e --arg name "$wallet_name" 'index($name) >= 0' &> /dev/null; then
    echo "Wallet '$wallet_name' is already loaded"
else
    # Check if wallet exists in wallet directory
    wallet_dir=$(bitcoin-cli listwalletdir)
    if echo "$wallet_dir" | jq -e --arg name "$wallet_name" '.wallets[] | select(.name == $name)' &> /dev/null; then
        echo "Wallet '$wallet_name' found, loading..."
        bitcoin-cli loadwallet "$wallet_name"
        echo "Wallet '$wallet_name' loaded successfully"
    else
        # Wallet doesn't exist, create it
        echo "Wallet not found, creating wallet '$wallet_name'..."
        bitcoin-cli createwallet "$wallet_name"
        echo "Wallet '$wallet_name' created and loaded"
    fi
fi

# Step 11: Check for unspent bitcoin outputs
pause_and_show "Checking for unspent outputs (UTXOs)..."
unspent=$(bitcoin-cli -rpcwallet="nftcharm_wallet" listunspent)
if [ "$(echo "$unspent" | jq 'length')" -gt 0 ]; then
    echo "Found unspent outputs:"
    echo "$unspent" | jq '.'
else
    echo "No unspent outputs found"
    exit 1
fi

# Step 12: Extract UTXO values and set environment variables
pause_and_show "Extracting UTXO values and computing app_id..."
export in_utxo_0=$(echo "$unspent" | jq -r '.[0] | "\(.txid):\(.vout)"')
echo "in_utxo_0: $in_utxo_0"

export app_id=$(echo -n "${in_utxo_0}" | sha256sum | cut -d' ' -f1)
echo "app_id: $app_id"

export addr_0=$(echo "$unspent" | jq -r '.[0].address')
echo "addr_0: $addr_0"

# Step 13: Get raw transaction for prev_txs
pause_and_show "Getting raw transaction data..."
txid=$(echo "$unspent" | jq -r '.[0].txid')
prev_txs=$(bitcoin-cli -rpcwallet="nftcharm_wallet" gettransaction "$txid" | jq -r '.hex')
echo "prev_txs (txid): $txid"
echo "prev_txs (raw): ${prev_txs:0:64}..." # Show first 64 chars

# Step 14: Export variables for envsubst
pause_and_show "Exporting variables for spell template substitution..."
export app_id
export app_vk
export in_utxo_0
export addr_0

# Step 15: Show substituted YAML for debugging
pause_and_show "Showing substituted YAML spell configuration..."
cat ./spells/mint-nft.yaml | envsubst

# Step 16: Execute spell check
pause_and_show "Running spell check to validate configuration..."
cat ./spells/mint-nft.yaml | envsubst | charms spell check --prev-txs=${prev_txs} --app-bins=${app_bin}

# Step 17: Set funding UTXO (second UTXO, different from the one used for minting)
pause_and_show "Setting funding UTXO for transaction fees..."
if [ "$(echo "$unspent" | jq 'length')" -gt 1 ]; then
    funding_utxo=$(echo "$unspent" | jq -r '.[1] | "\(.txid):\(.vout)"')
    funding_utxo_value_btc=$(echo "$unspent" | jq -r '.[1].amount')
    # Convert BTC to satoshis (multiply by 100000000)
    funding_utxo_value=$(echo "$funding_utxo_value_btc * 100000000" | bc | cut -d'.' -f1)
    echo "funding_utxo: $funding_utxo"
    echo "funding_utxo_value: $funding_utxo_value satoshis ($funding_utxo_value_btc BTC)"
else
    echo "Warning: Only one UTXO available, using the same one for funding"
    funding_utxo=$(echo "$unspent" | jq -r '.[0] | "\(.txid):\(.vout)"')
    funding_utxo_value_btc=$(echo "$unspent" | jq -r '.[0].amount')
    # Convert BTC to satoshis (multiply by 100000000)
    funding_utxo_value=$(echo "$funding_utxo_value_btc * 100000000" | bc | cut -d'.' -f1)
    echo "funding_utxo: $funding_utxo"
    echo "funding_utxo_value: $funding_utxo_value satoshis ($funding_utxo_value_btc BTC)"
fi

# Step 18: Get change address
pause_and_show "Getting change address for transaction outputs..."
change_address=$(bitcoin-cli -rpcwallet="nftcharm_wallet" getrawchangeaddress)
echo "change_address: $change_address"

# Step 19: Export RUST_LOG
pause_and_show "Setting RUST_LOG environment variable..."
export RUST_LOG=info
echo "RUST_LOG set to: $RUST_LOG"

# Step 20: Execute spell prove
pause_and_show "Running spell prove to generate proof and transactions..."
prove_output=$(cat ./spells/mint-nft.yaml | envsubst | charms spell prove --app-bins=${app_bin} --prev-txs=$prev_txs --funding-utxo=$funding_utxo --funding-utxo-value=$funding_utxo_value --change-address=$change_address)
echo "$prove_output"

# Step 21: Extract transaction hexes from prove output
pause_and_show "Extracting transaction hexes from prove output..."
tx_hex_1=$(echo "$prove_output" | jq -r '.[0].bitcoin')
tx_hex_2=$(echo "$prove_output" | jq -r '.[1].bitcoin')
echo "First transaction hex (first 64 chars): ${tx_hex_1:0:64}..."
echo "Second transaction hex (first 64 chars): ${tx_hex_2:0:64}..."

# Step 22: Sign transactions with wallet
pause_and_show "Signing transactions with wallet to add witness data..."
signed_tx_1=$(bitcoin-cli -rpcwallet="nftcharm_wallet" signrawtransactionwithwallet "$tx_hex_1" | jq -r '.hex')
signed_tx_2=$(bitcoin-cli -rpcwallet="nftcharm_wallet" signrawtransactionwithwallet "$tx_hex_2" | jq -r '.hex')
echo "Transactions signed successfully"

# Step 23: Create transaction array for package submission
pause_and_show "Creating transaction package array..."
tx_array=$(jq -n --arg tx1 "$signed_tx_1" --arg tx2 "$signed_tx_2" '[$tx1, $tx2]')
echo "Transaction package prepared"

# Step 24: Submit transaction package to Bitcoin network
pause_and_show "Submitting transaction package to Bitcoin network..."
submit_result=$(bitcoin-cli -rpcwallet="nftcharm_wallet" submitpackage "$tx_array")
echo "$submit_result"
echo "Transaction package submitted successfully"

# Step 25: Extract and display transaction IDs
pause_and_show "Extracting transaction IDs for mempool query..."
txid_1=$(bitcoin-cli -rpcwallet="nftcharm_wallet" decoderawtransaction "$signed_tx_1" | jq -r '.txid')
txid_2=$(bitcoin-cli -rpcwallet="nftcharm_wallet" decoderawtransaction "$signed_tx_2" | jq -r '.txid')

echo ""
echo "=========================================="
echo "TRANSACTION IDs (Query on Testnet4 Mempool)"
echo "=========================================="
echo "Transaction 1 ID: $txid_1"
echo "Mempool URL: https://mempool.space/testnet4/tx/$txid_1"
echo ""
echo "Transaction 2 ID: $txid_2"
echo "Mempool URL: https://mempool.space/testnet4/tx/$txid_2"
echo "=========================================="
