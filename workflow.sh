#!/bin/bash
set -e

# Detect Bitcoin network
NETWORK=$(bitcoin-cli getblockchaininfo 2>/dev/null | jq -r '.chain' || echo "main")
if [ "$NETWORK" = "testnet4" ]; then
    BTC_CLI="bitcoin-cli -testnet4"
    echo "Detected testnet4 network"
elif [ "$NETWORK" = "test" ]; then
    BTC_CLI="bitcoin-cli -testnet"
    echo "Detected testnet network"
elif [ "$NETWORK" = "regtest" ]; then
    BTC_CLI="bitcoin-cli -regtest"
    echo "Detected regtest network"
else
    BTC_CLI="bitcoin-cli"
    echo "Using mainnet"
fi

# Helper function to pause and show action
pause_and_show() {
    echo ""
    echo "==> $1"
    sleep 2
}

# Step 1: Set up temporary cargo target directory
pause_and_show "Setting up temporary cargo target directory..."
export CARGO_TARGET_DIR=$(mktemp -d)/target
echo "[1] CARGO_TARGET_DIR set to: $CARGO_TARGET_DIR"

# Step 2: Check if charms is installed, install if not
pause_and_show "Checking if charms CLI is installed..."
if ! command -v charms &> /dev/null; then
    echo "[2] charms not found, installing version 0.10.0..."
    cargo install charms --version=0.10.0
else
    echo "[2] charms is already installed"
fi

# Step 3: Check if spell template exists, create if not
pause_and_show "Checking for spell template (my-token)..."
if [ ! -d "my-token" ]; then
    echo "[3] Spell template not found, creating my-token..."
    charms app new my-token
else
    echo "[3] Spell template my-token already exists"
fi

# Step 4: Navigate to my-token directory
pause_and_show "Navigating to my-token directory..."
cd ./my-token
echo "[4] Changed directory to my-token"

# Step 5: Unset CARGO_TARGET_DIR
pause_and_show "Unsetting CARGO_TARGET_DIR..."
unset CARGO_TARGET_DIR
echo "[5] CARGO_TARGET_DIR unset"

# Step 6: Update cargo dependencies
pause_and_show "Updating cargo dependencies..."
cargo update

# Step 7: Build app and generate verification key
pause_and_show "Building app and generating verification key..."
app_bin=$(charms app build)
echo "[7] Verification key:"
charms app vk "$app_bin"

# Step 8: Export verification key
pause_and_show "Exporting verification key..."
export app_vk=$(charms app vk "$app_bin")
echo "[8] app_vk exported: $app_vk"

# Step 9: Check if bitcoind is running, start if not
pause_and_show "Checking if bitcoind is running..."
if ! $BTC_CLI getblockchaininfo &> /dev/null; then
    echo "[9] Bitcoin server not running, starting bitcoind..."
    bitcoind -daemon
    echo "Waiting for bitcoind to start..."
    sleep 5
    # Wait for server to be ready
    until $BTC_CLI getblockchaininfo &> /dev/null; do
        echo "Waiting for bitcoind to be ready..."
        sleep 2
    done
    echo "[9] bitcoind started successfully"
else
    echo "[9] bitcoind is already running"
fi

# Step 10: Load or create wallet
pause_and_show "Checking for wallet (nftcharm_wallet)..."
wallet_name="nftcharm_wallet"

# Check if wallet is already loaded
if $BTC_CLI listwallets | jq -e --arg name "$wallet_name" 'index($name) >= 0' &> /dev/null; then
    echo "[10] Wallet '$wallet_name' is already loaded"
else
    # Check if wallet exists in wallet directory
    wallet_dir=$($BTC_CLI listwalletdir)
    if echo "$wallet_dir" | jq -e --arg name "$wallet_name" '.wallets[] | select(.name == $name)' &> /dev/null; then
        echo "[10] Wallet '$wallet_name' found, loading..."
        $BTC_CLI loadwallet "$wallet_name"
        echo "[10] Wallet '$wallet_name' loaded successfully"
    else
        # Wallet doesn't exist, create it
        echo "[10] Wallet not found, creating wallet '$wallet_name'..."
        $BTC_CLI createwallet "$wallet_name"
        echo "[10] Wallet '$wallet_name' created and loaded"
    fi
fi

# Step 11: Check wallet balance
pause_and_show "Checking wallet balance..."
balance=$($BTC_CLI -rpcwallet="nftcharm_wallet" getbalance)
echo "[11] Wallet balance: $balance BTC"

# If balance is 0, check unconfirmed balance
if [ "$(echo "$balance == 0" | bc)" -eq 1 ]; then
    balances_info=$($BTC_CLI -rpcwallet="nftcharm_wallet" getbalances 2>/dev/null || echo "{}")
    if [ -n "$balances_info" ] && [ "$balances_info" != "{}" ]; then
        unconfirmed_balance=$(echo "$balances_info" | jq -r '.mine.untrusted_pending // 0')
        echo "[11] Unconfirmed balance: $unconfirmed_balance BTC"
    fi
fi

# Step 12: Check for unspent bitcoin outputs
pause_and_show "Checking for unspent outputs (UTXOs)..."
unspent=$($BTC_CLI -rpcwallet="nftcharm_wallet" listunspent)
if [ "$(echo "$unspent" | jq 'length')" -gt 0 ]; then
    echo "[12] Found unspent outputs:"
    echo "$unspent" | jq '.'
else
    echo "[12] ✗ No unspent outputs found"
    echo ""
    echo "To continue, you need to fund your wallet with testnet4 bitcoin."
    echo "You can get free testnet4 coins from these faucets:"
    echo "  • https://coinfaucet.eu/en/btc-testnet4/"
    echo "  • https://faucet.testnet4.dev"
    echo ""
    echo "Your wallet address:"
    $BTC_CLI -rpcwallet="nftcharm_wallet" getnewaddress
    exit 1
fi

# Step 13: Extract UTXO values and set environment variables
pause_and_show "Extracting UTXO values and computing app_id..."
export in_utxo_0=$(echo "$unspent" | jq -r '.[0] | "\(.txid):\(.vout)"')
echo "[13] in_utxo_0: $in_utxo_0"

export app_id=$(echo -n "${in_utxo_0}" | sha256sum | cut -d' ' -f1)
echo "[13] app_id: $app_id"

export addr_0=$(echo "$unspent" | jq -r '.[0].address')
echo "[13] addr_0: $addr_0"

# Step 14: Get raw transaction for prev_txs
pause_and_show "Getting raw transaction data..."
txid=$(echo "$unspent" | jq -r '.[0].txid')
prev_txs=$($BTC_CLI -rpcwallet="nftcharm_wallet" gettransaction "$txid" | jq -r '.hex')
echo "[14] prev_txs (txid): $txid"
echo "[14] prev_txs (raw): ${prev_txs:0:64}..." # Show first 64 chars

# Step 15: Export variables for envsubst
pause_and_show "Exporting variables for spell template substitution..."
export app_id
export app_vk
export in_utxo_0
export addr_0

# Step 16: Show substituted YAML for debugging
pause_and_show "Showing substituted YAML spell configuration..."
echo "[16] Substituted YAML:"
cat ./spells/mint-nft.yaml | envsubst

# Step 17: Execute spell check
pause_and_show "Running spell check to validate configuration..."
echo "[17] Spell check result:"
cat ./spells/mint-nft.yaml | envsubst | charms spell check --prev-txs=${prev_txs} --app-bins=${app_bin}

# Step 18: Set funding UTXO (second UTXO, different from the one used for minting)
pause_and_show "Setting funding UTXO for transaction fees..."
if [ "$(echo "$unspent" | jq 'length')" -gt 1 ]; then
    funding_utxo=$(echo "$unspent" | jq -r '.[1] | "\(.txid):\(.vout)"')
    funding_utxo_value_btc=$(echo "$unspent" | jq -r '.[1].amount')
    # Convert BTC to satoshis (multiply by 100000000)
    funding_utxo_value=$(echo "$funding_utxo_value_btc * 100000000" | bc | cut -d'.' -f1)
    echo "[18] funding_utxo: $funding_utxo"
    echo "[18] funding_utxo_value: $funding_utxo_value satoshis ($funding_utxo_value_btc BTC)"
else
    echo "[18] Warning: Only one UTXO available, using the same one for funding"
    funding_utxo=$(echo "$unspent" | jq -r '.[0] | "\(.txid):\(.vout)"')
    funding_utxo_value_btc=$(echo "$unspent" | jq -r '.[0].amount')
    # Convert BTC to satoshis (multiply by 100000000)
    funding_utxo_value=$(echo "$funding_utxo_value_btc * 100000000" | bc | cut -d'.' -f1)
    echo "[18] funding_utxo: $funding_utxo"
    echo "[18] funding_utxo_value: $funding_utxo_value satoshis ($funding_utxo_value_btc BTC)"
fi

# Step 19: Get change address
pause_and_show "Getting change address for transaction outputs..."
change_address=$($BTC_CLI -rpcwallet="nftcharm_wallet" getrawchangeaddress)
echo "[19] change_address: $change_address"

# Step 20: Export RUST_LOG
pause_and_show "Setting RUST_LOG environment variable..."
export RUST_LOG=info
echo "[20] RUST_LOG set to: $RUST_LOG"

# Step 21: Execute spell prove
pause_and_show "Running spell prove to generate proof and transactions..."
prove_output=$(cat ./spells/mint-nft.yaml | envsubst | charms spell prove --app-bins=${app_bin} --prev-txs=$prev_txs --funding-utxo=$funding_utxo --funding-utxo-value=$funding_utxo_value --change-address=$change_address)
echo "[21] Prove output:"
echo "$prove_output"

# Step 22: Extract transaction hexes from prove output
pause_and_show "Extracting transaction hexes from prove output..."
tx_hex_1=$(echo "$prove_output" | jq -r '.[0].bitcoin')
tx_hex_2=$(echo "$prove_output" | jq -r '.[1].bitcoin')
echo "[22] First transaction hex (first 64 chars): ${tx_hex_1:0:64}..."
echo "[22] Second transaction hex (first 64 chars): ${tx_hex_2:0:64}..."

# Step 23: Sign and broadcast transaction 1 first (since TX2 depends on it)
pause_and_show "Signing first transaction with wallet..."
sign_result_1=$($BTC_CLI -rpcwallet="nftcharm_wallet" signrawtransactionwithwallet "$tx_hex_1")
signed_tx_1=$(echo "$sign_result_1" | jq -r '.hex')
complete_1=$(echo "$sign_result_1" | jq -r '.complete')

echo "[23] Transaction 1 signing complete: $complete_1"

if [ "$complete_1" != "true" ]; then
    echo "[23] ⚠ Warning: Transaction 1 is not fully signed!"
    echo "Sign result:"
    echo "$sign_result_1" | jq '.'
    exit 1
fi

echo "[23] ✓ Transaction 1 signed successfully"

# Step 23.5: Test transaction 1 before broadcasting
pause_and_show "Testing transaction 1 with mempool acceptance..."
test_result_1=$($BTC_CLI testmempoolaccept "[\"$signed_tx_1\"]")
echo "[23.5] Test result:"
echo "$test_result_1" | jq '.'

allowed_1=$(echo "$test_result_1" | jq -r '.[0].allowed')
if [ "$allowed_1" != "true" ]; then
    echo ""
    echo "[23.5] ✗ Transaction 1 will be rejected by mempool!"
    echo "Reject reason: $(echo "$test_result_1" | jq -r '.[0]."reject-reason"')"
    exit 1
fi

echo "[23.5] ✓ Transaction 1 passed mempool acceptance test"

# Step 24: Submit transaction 1 to Bitcoin network
pause_and_show "Submitting first transaction to Bitcoin network..."
echo "[24] Attempting to broadcast first transaction..."
if txid_1=$($BTC_CLI sendrawtransaction "$signed_tx_1" 2>&1); then
    echo "[24] ✓ First transaction submitted successfully: $txid_1"
else
    echo "[24] ✗ Error submitting first transaction:"
    echo "$txid_1"
    echo ""
    echo "Transaction hex (for manual inspection):"
    echo "$signed_tx_1"
    exit 1
fi

# Step 25: Now sign transaction 2 (which depends on TX1 output)
pause_and_show "Signing second transaction with wallet..."

# Decode transaction 1 to get output details
decoded_tx_1=$($BTC_CLI decoderawtransaction "$signed_tx_1")
tx1_scriptpubkey=$(echo "$decoded_tx_1" | jq -r '.vout[0].scriptPubKey.hex')
tx1_amount=$(echo "$decoded_tx_1" | jq -r '.vout[0].value')

echo "[25] TX1 output 0: scriptPubKey=$tx1_scriptpubkey, amount=$tx1_amount"

# Sign transaction 2 with the previous output information
sign_result_2=$($BTC_CLI -rpcwallet="nftcharm_wallet" signrawtransactionwithwallet "$tx_hex_2" "[{\"txid\":\"$txid_1\",\"vout\":0,\"scriptPubKey\":\"$tx1_scriptpubkey\",\"amount\":$tx1_amount}]")
signed_tx_2=$(echo "$sign_result_2" | jq -r '.hex')
complete_2=$(echo "$sign_result_2" | jq -r '.complete')

echo "[25] Transaction 2 signing complete: $complete_2"

if [ "$complete_2" != "true" ]; then
    echo "[25] ⚠ Warning: Transaction 2 is not fully signed!"
    echo "Sign result:"
    echo "$sign_result_2" | jq '.'
    exit 1
fi

echo "[25] ✓ Transaction 2 signed successfully"

# Step 25.5: Test transaction 2 before broadcasting
pause_and_show "Testing transaction 2 with mempool acceptance..."
test_result_2=$($BTC_CLI testmempoolaccept "[\"$signed_tx_2\"]")
echo "[25.5] Test result:"
echo "$test_result_2" | jq '.'

allowed_2=$(echo "$test_result_2" | jq -r '.[0].allowed')
if [ "$allowed_2" != "true" ]; then
    echo ""
    echo "[25.5] ✗ Transaction 2 will be rejected by mempool!"
    echo "Reject reason: $(echo "$test_result_2" | jq -r '.[0]."reject-reason"')"
    exit 1
fi

echo "[25.5] ✓ Transaction 2 passed mempool acceptance test"

# Step 26: Submit transaction 2 to Bitcoin network
pause_and_show "Submitting second transaction to Bitcoin network..."
echo "[26] Attempting to broadcast second transaction..."
if txid_2=$($BTC_CLI sendrawtransaction "$signed_tx_2" 2>&1); then
    echo "[26] ✓ Second transaction submitted successfully: $txid_2"
else
    echo "[26] ✗ Error submitting second transaction:"
    echo "$txid_2"
    echo ""
    echo "Transaction hex (for manual inspection):"
    echo "$signed_tx_2"
    exit 1
fi

# Step 27: Display transaction IDs and mempool URLs
pause_and_show "Displaying transaction details for mempool verification..."

echo ""
echo "=========================================="
echo "[27] TRANSACTION IDs (Query on Testnet4 Mempool)"
echo "=========================================="
echo "Transaction 1 ID: $txid_1"
echo "Mempool URL: https://mempool.space/testnet4/tx/$txid_1"
echo ""
echo "Transaction 2 ID: $txid_2"
echo "Mempool URL: https://mempool.space/testnet4/tx/$txid_2"
echo "=========================================="
echo ""
echo "✅ NFT minting workflow completed successfully!"
echo "Visit the mempool URLs above to track transaction confirmations."
