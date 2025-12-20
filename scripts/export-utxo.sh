#!/bin/bash
#
# Export UTXO Variables for NFTCharm
#
# Quick script to export UTXO environment variables
# Usage: eval $(./scripts/export-utxo.sh)

NETWORK="testnet4"
WALLET="nftcharm_wallet"
UTXO_INDEX=0

# Get first unspent UTXO
UTXOS=$(bitcoin-cli -${NETWORK} -rpcwallet="${WALLET}" listunspent 1 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$UTXOS" ]; then
    echo "# Error: Could not fetch UTXOs" >&2
    exit 1
fi

UTXO_COUNT=$(echo "$UTXOS" | jq 'length' 2>/dev/null)
if [ "$UTXO_COUNT" -eq 0 ]; then
    echo "# Error: No confirmed UTXOs found" >&2
    exit 1
fi

# Extract UTXO details
TXID=$(echo "$UTXOS" | jq -r ".[${UTXO_INDEX}].txid")
VOUT=$(echo "$UTXOS" | jq -r ".[${UTXO_INDEX}].vout")
ADDRESS=$(echo "$UTXOS" | jq -r ".[${UTXO_INDEX}].address")

# Construct UTXO identifier
UTXO_ID="${TXID}:${VOUT}"

# Calculate app_id (SHA256 hash of UTXO ID)
APP_ID=$(echo -n "${UTXO_ID}" | sha256sum | cut -d' ' -f1)

# Get the raw transaction
RAW_TX=$(bitcoin-cli -${NETWORK} getrawtransaction "${TXID}" 2>/dev/null)

# Output export commands
echo "export in_utxo_0=\"${UTXO_ID}\""
echo "export app_id=\"${APP_ID}\""
echo "export addr_0=\"${ADDRESS}\""
echo "export prev_txs=\"${RAW_TX}\""
