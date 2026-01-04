#!/bin/bash
set -e

# Script to prove and broadcast a mint tokens spell
# Usage: ./prove-mint.sh [spell_file]

SPELL_FILE="${1:-/tmp/mint_tokens.yaml}"
cd /Users/user/Desktop/NFTCharm/my-token

echo "=== Token Mint Prove & Broadcast ==="
echo ""

# Detect network
NETWORK=$(bitcoin-cli getblockchaininfo 2>/dev/null | jq -r '.chain' || echo "main")
if [ "$NETWORK" = "testnet4" ]; then
    BTC_CLI="bitcoin-cli -testnet4"
elif [ "$NETWORK" = "test" ]; then
    BTC_CLI="bitcoin-cli -testnet"
else
    BTC_CLI="bitcoin-cli"
fi

# Load wallet
$BTC_CLI loadwallet "nftcharm_wallet" 2>/dev/null || true

# Get first input UTXO from spell file
INPUT_UTXO=$(grep -A1 "ins:" "$SPELL_FILE" | grep "utxo_id" | head -1 | sed 's/.*: //' | tr -d ' ')
INPUT_TXID=$(echo "$INPUT_UTXO" | cut -d':' -f1)
echo "Input UTXO: $INPUT_UTXO"
echo "Input TXID: $INPUT_TXID"

# Get prev tx
PREV_TX=$($BTC_CLI -rpcwallet="nftcharm_wallet" gettransaction "$INPUT_TXID" 2>/dev/null | jq -r '.hex')
if [ -z "$PREV_TX" ] || [ "$PREV_TX" = "null" ]; then
    PREV_TX=$($BTC_CLI getrawtransaction "$INPUT_TXID" 2>/dev/null)
fi
echo "Prev TX fetched (length: ${#PREV_TX})"

# Get funding UTXO (excluding the input UTXO)
echo ""
echo "Finding funding UTXO..."
FUNDING_INFO=$($BTC_CLI -rpcwallet="nftcharm_wallet" listunspent 0 | jq -r --arg ixid "$INPUT_TXID" '.[] | select(.amount > 0.0005 and .txid != $ixid) | "\(.txid):\(.vout) \(.amount)"' | head -n1)

if [ -z "$FUNDING_INFO" ]; then
    echo "ERROR: No suitable funding UTXO found"
    exit 1
fi

FUNDING_UTXO=$(echo "$FUNDING_INFO" | cut -d' ' -f1)
FUNDING_AMOUNT=$(echo "$FUNDING_INFO" | cut -d' ' -f2)
FUNDING_VALUE=$(echo "$FUNDING_AMOUNT * 100000000" | bc | cut -d'.' -f1)
echo "Funding UTXO: $FUNDING_UTXO ($FUNDING_AMOUNT BTC = $FUNDING_VALUE sats)"

# Get change address
CHANGE_ADDR=$($BTC_CLI -rpcwallet="nftcharm_wallet" getnewaddress)
echo "Change Address: $CHANGE_ADDR"

# Display spell
echo ""
echo "=== Spell Content ==="
cat "$SPELL_FILE"
echo "=== End Spell ==="
echo ""

# Prove spell
echo "Proving spell..."
export RUST_LOG=info
PROVE_OUTPUT=$(cat "$SPELL_FILE" | \
    charms spell prove \
        --app-bins="target/wasm32-wasip1/release/my-token.wasm" \
        --prev-txs="$PREV_TX" \
        --funding-utxo="$FUNDING_UTXO" \
        --funding-utxo-value="$FUNDING_VALUE" \
        --change-address="$CHANGE_ADDR")

echo ""
echo "Prove output received"

# Extract transaction hexes
TX_HEX_1=$(echo "$PROVE_OUTPUT" | jq -r '.[0].bitcoin')
TX_HEX_2=$(echo "$PROVE_OUTPUT" | jq -r '.[1].bitcoin')

echo "TX1 hex (first 64 chars): ${TX_HEX_1:0:64}..."
echo "TX2 hex (first 64 chars): ${TX_HEX_2:0:64}..."

# Sign and broadcast TX1
echo ""
echo "Signing transaction 1..."
SIGN_RESULT_1=$($BTC_CLI -rpcwallet="nftcharm_wallet" signrawtransactionwithwallet "$TX_HEX_1")
SIGNED_TX_1=$(echo "$SIGN_RESULT_1" | jq -r '.hex')
COMPLETE_1=$(echo "$SIGN_RESULT_1" | jq -r '.complete')

if [ "$COMPLETE_1" != "true" ]; then
    echo "ERROR: Transaction 1 not fully signed!"
    echo "$SIGN_RESULT_1"
    exit 1
fi

echo "Broadcasting transaction 1..."
TXID_1=$($BTC_CLI sendrawtransaction "$SIGNED_TX_1")
echo "TX1 broadcast: $TXID_1"

sleep 2

# Get TX1 output details
TX1_RAW=$($BTC_CLI getrawtransaction "$TXID_1" true 2>/dev/null || $BTC_CLI decoderawtransaction "$SIGNED_TX_1")
TX1_SCRIPTPUBKEY=$(echo "$TX1_RAW" | jq -r '.vout[0].scriptPubKey.hex')
TX1_AMOUNT=$(echo "$TX1_RAW" | jq -r '.vout[0].value')

# Sign and broadcast TX2
echo ""
echo "Signing transaction 2..."
SIGN_RESULT_2=$($BTC_CLI -rpcwallet="nftcharm_wallet" signrawtransactionwithwallet "$TX_HEX_2" \
    "[{\"txid\":\"$TXID_1\",\"vout\":0,\"scriptPubKey\":\"$TX1_SCRIPTPUBKEY\",\"amount\":$TX1_AMOUNT}]")
SIGNED_TX_2=$(echo "$SIGN_RESULT_2" | jq -r '.hex')
COMPLETE_2=$(echo "$SIGN_RESULT_2" | jq -r '.complete')

if [ "$COMPLETE_2" != "true" ]; then
    echo "ERROR: Transaction 2 not fully signed!"
    echo "$SIGN_RESULT_2"
    exit 1
fi

echo "Broadcasting transaction 2..."
TXID_2=$($BTC_CLI sendrawtransaction "$SIGNED_TX_2")
echo "TX2 broadcast: $TXID_2"

echo ""
echo "=========================================="
echo "SUCCESS! Tokens Minted!"
echo "=========================================="
echo "Commit TX: $TXID_1"
echo "Spell TX:  $TXID_2"
echo ""
echo "View spell: ./spell.sh $TXID_2"
echo "=========================================="
