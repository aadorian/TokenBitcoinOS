#!/bin/bash
set -e

# Step 1: Set up temporary cargo target directory
export CARGO_TARGET_DIR=$(mktemp -d)/target
echo "CARGO_TARGET_DIR set to: $CARGO_TARGET_DIR"

# Step 2: Check if charms is installed, install if not
if ! command -v charms &> /dev/null; then
    echo "charms not found, installing version 0.10.0..."
    cargo install charms --version=0.10.0
else
    echo "charms is already installed"
fi

# Step 3: Check if spell template exists, create if not
if [ ! -d "my-token" ]; then
    echo "Spell template not found, creating my-token..."
    charms app new my-token
else
    echo "Spell template my-token already exists"
fi

# Step 4: Navigate to my-token directory
cd ./my-token
echo "Changed directory to my-token"

# Step 5: Unset CARGO_TARGET_DIR
unset CARGO_TARGET_DIR
echo "CARGO_TARGET_DIR unset"

# Step 6: Update cargo dependencies
echo "Updating cargo dependencies..."
cargo update

# Step 7: Build app and generate verification key
echo "Building app and generating verification key..."
app_bin=$(charms app build)
charms app vk "$app_bin"

# Step 8: Export verification key
export app_vk=$(charms app vk "$app_bin")
echo "app_vk exported: $app_vk"

# Step 9: Check if bitcoind is running, start if not
echo "Checking if bitcoind is running..."
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
echo "Checking for wallet..."
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
echo "Checking for unspent outputs..."
unspent=$(bitcoin-cli -rpcwallet="nftcharm_wallet" listunspent)
if [ "$(echo "$unspent" | jq 'length')" -gt 0 ]; then
    echo "Found unspent outputs:"
    echo "$unspent" | jq '.'
else
    echo "No unspent outputs found"
    exit 1
fi

# Step 12: Extract UTXO values and set environment variables
echo "Extracting UTXO values..."
export in_utxo_0=$(echo "$unspent" | jq -r '.[0] | "\(.txid):\(.vout)"')
echo "in_utxo_0: $in_utxo_0"

export app_id=$(echo -n "${in_utxo_0}" | sha256sum | cut -d' ' -f1)
echo "app_id: $app_id"

export addr_0=$(echo "$unspent" | jq -r '.[0].address')
echo "addr_0: $addr_0"

# Step 13: Get raw transaction for prev_txs
echo "Getting raw transaction..."
txid=$(echo "$unspent" | jq -r '.[0].txid')
prev_txs=$(bitcoin-cli -rpcwallet="nftcharm_wallet" gettransaction "$txid" | jq -r '.hex')
echo "prev_txs (txid): $txid"
echo "prev_txs (raw): ${prev_txs:0:64}..." # Show first 64 chars

# Step 14: Export variables for envsubst
echo "Exporting variables for envsubst..."
export app_id
export app_vk
export in_utxo_0
export addr_0

# Step 15: Show substituted YAML for debugging
echo "Substituted YAML:"
cat ./spells/mint-nft.yaml | envsubst

# Step 16: Execute spell check
echo "Running spell check..."
cat ./spells/mint-nft.yaml | envsubst | charms spell check --prev-txs=${prev_txs} --app-bins=${app_bin}

# Step 17: Set funding UTXO (second UTXO, different from the one used for minting)
echo "Setting funding UTXO..."
if [ "$(echo "$unspent" | jq 'length')" -gt 1 ]; then
    funding_utxo=$(echo "$unspent" | jq -r '.[1] | "\(.txid):\(.vout)"')
    funding_utxo_value=$(echo "$unspent" | jq -r '.[1].amount')
    echo "funding_utxo: $funding_utxo"
    echo "funding_utxo_value: $funding_utxo_value"
else
    echo "Warning: Only one UTXO available, using the same one for funding"
    funding_utxo=$(echo "$unspent" | jq -r '.[0] | "\(.txid):\(.vout)"')
    funding_utxo_value=$(echo "$unspent" | jq -r '.[0].amount')
    echo "funding_utxo: $funding_utxo"
    echo "funding_utxo_value: $funding_utxo_value"
fi

# Step 18: Get change address
echo "Getting change address..."
change_address=$(bitcoin-cli -rpcwallet="nftcharm_wallet" getrawchangeaddress)
echo "change_address: $change_address"

# Step 19: Export RUST_LOG
export RUST_LOG=info
echo "RUST_LOG set to: $RUST_LOG"
