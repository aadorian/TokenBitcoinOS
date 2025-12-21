#!/bin/bash
set -e

# Test Transfer Script
# This script sends tokens from the default address back to itself to verify the token is working

echo "=========================================="
echo "NFTCharm Test Transfer Script"
echo "=========================================="
echo ""

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

# Navigate to my-token directory
cd my-token

echo ""
echo "Step 1: Get verification key..."
export app_vk=$(charms app vk)
echo "app_vk: $app_vk"

echo ""
echo "Step 2: Find the UTXO with tokens..."
# Look for the token minted transaction - should be the second tx from the minting process
# Based on your output, this should be transaction: 99c87e74dfb50db7fac0ed41ed640dd62ec4d97e77aca70a60ed57edcd89485b
# The token output is usually at vout 0

# List all UTXOs and find the one with tokens
echo "Available UTXOs:"
$BTC_CLI -rpcwallet="nftcharm_wallet" listunspent | jq '.[] | {txid: .txid, vout: .vout, amount: .amount, address: .address}'

echo ""
read -p "Enter the UTXO with tokens (format: txid:vout): " TOKEN_UTXO
export in_utxo_1="$TOKEN_UTXO"

echo ""
echo "Step 3: Calculate app_id from the original NFT UTXO..."
# The app_id should be from the ORIGINAL witness UTXO that created the NFT
# Based on your output: f62d75e7c52c1929c63033b797947d8af0f4e720cc5d67be5198e24491818941:0
export original_witness_utxo="f62d75e7c52c1929c63033b797947d8af0f4e720cc5d67be5198e24491818941:0"
export app_id=$(echo -n "$original_witness_utxo" | sha256sum | cut -d' ' -f1)
echo "app_id: $app_id"

echo ""
echo "Step 4: Get addresses for transfer..."
# Get the current default address
export addr_3=$($BTC_CLI -rpcwallet="nftcharm_wallet" getnewaddress)
echo "Recipient address (addr_3): $addr_3"

# Use the same address for change
export addr_4=$addr_3
echo "Change address (addr_4): $addr_4"

echo ""
echo "Step 5: Get the token UTXO raw transaction..."
TOKEN_TXID=$(echo $in_utxo_1 | cut -d':' -f1)
export prev_txs=$($BTC_CLI getrawtransaction "$TOKEN_TXID")
echo "Token transaction fetched (txid: $TOKEN_TXID)"

echo ""
echo "Step 6: Prepare send.yaml spell..."
echo "============================================"
cat ./spells/send.yaml | envsubst
echo "============================================"

echo ""
echo "Step 7: Validate spell..."
app_bin=$(charms app bin)
cat ./spells/send.yaml | envsubst | charms spell check --prev-txs=$prev_txs --app-bins=$app_bin

echo ""
echo "Step 8: Get funding UTXO for transaction fees..."
# Get a UTXO for paying fees (should be different from the token UTXO)
FUNDING_INFO=$($BTC_CLI -rpcwallet="nftcharm_wallet" listunspent | jq -r '.[] | select(.amount > 0.00001) | "\(.txid):\(.vout) \(.amount)"' | head -n1)
export funding_utxo=$(echo $FUNDING_INFO | cut -d' ' -f1)
funding_amount=$(echo $FUNDING_INFO | cut -d' ' -f2)
export funding_utxo_value=$(echo "$funding_amount * 100000000" | bc | cut -d'.' -f1)
echo "funding_utxo: $funding_utxo"
echo "funding_utxo_value: $funding_utxo_value satoshis"

echo ""
echo "Step 9: Get change address..."
export change_address=$($BTC_CLI -rpcwallet="nftcharm_wallet" getnewaddress)
echo "change_address: $change_address"

echo ""
echo "Step 10: Generate proof and transactions..."
export RUST_LOG=info
prove_output=$(cat ./spells/send.yaml | envsubst | \
    charms spell prove \
        --app-bins=$app_bin \
        --prev-txs=$prev_txs \
        --funding-utxo=$funding_utxo \
        --funding-utxo-value=$funding_utxo_value \
        --change-address=$change_address)

echo ""
echo "Step 11: Extract transaction hexes..."
tx_hex_1=$(echo "$prove_output" | jq -r '.[0].bitcoin')
tx_hex_2=$(echo "$prove_output" | jq -r '.[1].bitcoin')
echo "Transaction 1 hex (first 64 chars): ${tx_hex_1:0:64}..."
echo "Transaction 2 hex (first 64 chars): ${tx_hex_2:0:64}..."

echo ""
echo "Step 12: Sign transaction 1..."
sign_result_1=$($BTC_CLI -rpcwallet="nftcharm_wallet" signrawtransactionwithwallet "$tx_hex_1")
signed_tx_1=$(echo "$sign_result_1" | jq -r '.hex')
complete_1=$(echo "$sign_result_1" | jq -r '.complete')

if [ "$complete_1" != "true" ]; then
    echo "ERROR: Transaction 1 not fully signed!"
    exit 1
fi
echo "Transaction 1 signed successfully"

echo ""
echo "Step 13: Test transaction 1 mempool acceptance..."
test_result_1=$($BTC_CLI testmempoolaccept "[\"$signed_tx_1\"]")
allowed_1=$(echo "$test_result_1" | jq -r '.[0].allowed')

if [ "$allowed_1" != "true" ]; then
    echo "ERROR: Transaction 1 rejected by mempool!"
    echo "Reject reason: $(echo "$test_result_1" | jq -r '.[0]."reject-reason"')"
    exit 1
fi
echo "Transaction 1 passed mempool test"

echo ""
echo "Step 14: Broadcast transaction 1..."
if txid_1=$($BTC_CLI sendrawtransaction "$signed_tx_1" 2>&1); then
    echo "Transaction 1 submitted successfully!"
    echo "TXID: $txid_1"
else
    echo "ERROR: Failed to broadcast transaction 1"
    echo "$txid_1"
    exit 1
fi

echo ""
echo "Step 15: Extract transaction 1 output details..."
tx1_raw=$($BTC_CLI getrawtransaction "$txid_1" true)
tx1_scriptpubkey=$(echo "$tx1_raw" | jq -r '.vout[0].scriptPubKey.hex')
tx1_amount=$(echo "$tx1_raw" | jq -r '.vout[0].value')
echo "TX1 output 0 scriptPubKey: $tx1_scriptpubkey"
echo "TX1 output 0 amount: $tx1_amount BTC"

echo ""
echo "Step 16: Sign transaction 2..."
sign_result_2=$($BTC_CLI -rpcwallet="nftcharm_wallet" signrawtransactionwithwallet "$tx_hex_2" \
    "[{\"txid\":\"$txid_1\",\"vout\":0,\"scriptPubKey\":\"$tx1_scriptpubkey\",\"amount\":$tx1_amount}]")
signed_tx_2=$(echo "$sign_result_2" | jq -r '.hex')
complete_2=$(echo "$sign_result_2" | jq -r '.complete')

if [ "$complete_2" != "true" ]; then
    echo "ERROR: Transaction 2 not fully signed!"
    exit 1
fi
echo "Transaction 2 signed successfully"

echo ""
echo "Step 17: Test transaction 2 mempool acceptance..."
test_result_2=$($BTC_CLI testmempoolaccept "[\"$signed_tx_2\"]")
allowed_2=$(echo "$test_result_2" | jq -r '.[0].allowed')

if [ "$allowed_2" != "true" ]; then
    echo "ERROR: Transaction 2 rejected by mempool!"
    echo "Reject reason: $(echo "$test_result_2" | jq -r '.[0]."reject-reason"')"
    exit 1
fi
echo "Transaction 2 passed mempool test"

echo ""
echo "Step 18: Broadcast transaction 2..."
if txid_2=$($BTC_CLI sendrawtransaction "$signed_tx_2" 2>&1); then
    echo "Transaction 2 submitted successfully!"
    echo "TXID: $txid_2"
else
    echo "ERROR: Failed to broadcast transaction 2"
    echo "$txid_2"
    exit 1
fi

echo ""
echo "=========================================="
echo "Test Transfer Complete!"
echo "=========================================="
echo "Commit Transaction: $txid_1"
echo "Spell Transaction: $txid_2"
echo ""
echo "The tokens have been successfully transferred back to the same address,"
echo "proving that the token system is working correctly!"
echo ""
echo "You can view the spell transaction with:"
echo "./spell.sh $txid_2"
