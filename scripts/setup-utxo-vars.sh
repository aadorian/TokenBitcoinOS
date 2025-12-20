#!/bin/bash
#
# Setup UTXO Environment Variables for NFTCharm
#
# This script queries bitcoin-cli for unspent outputs and exports
# the necessary environment variables for NFT minting.
#
# Usage: source ./scripts/setup-utxo-vars.sh
#        OR
#        ./scripts/setup-utxo-vars.sh

set -e

# Configuration
NETWORK="testnet4"
WALLET="nftcharm_wallet"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== NFTCharm UTXO Setup ===${NC}"
echo

# Check if bitcoin-cli is available
if ! command -v bitcoin-cli &> /dev/null; then
    echo -e "${RED}Error: bitcoin-cli not found${NC}"
    echo "Please install Bitcoin Core first"
    exit 1
fi

# Check if daemon is running
if ! bitcoin-cli -${NETWORK} getblockchaininfo &> /dev/null; then
    echo -e "${RED}Error: Bitcoin daemon is not running${NC}"
    echo "Start it with: bitcoind -${NETWORK} -daemon"
    exit 1
fi

# List unspent outputs
echo -e "${YELLOW}Fetching unspent outputs from wallet '${WALLET}'...${NC}"
UTXOS=$(bitcoin-cli -${NETWORK} -rpcwallet="${WALLET}" listunspent 1)

# Check if we have any UTXOs
UTXO_COUNT=$(echo "$UTXOS" | jq 'length')
if [ "$UTXO_COUNT" -eq 0 ]; then
    echo -e "${RED}No confirmed UTXOs found${NC}"
    echo "Please fund your wallet first. Get your address with:"
    echo "  bitcoin-cli -${NETWORK} -rpcwallet=\"${WALLET}\" getnewaddress"
    exit 1
fi

echo -e "${GREEN}Found ${UTXO_COUNT} UTXO(s)${NC}"
echo

# Display all UTXOs
echo -e "${YELLOW}Available UTXOs:${NC}"
echo "$UTXOS" | jq -r '.[] | "\(.txid):\(.vout) - \(.amount) BTC (\(.confirmations) confirmations)"'
echo

# Select the first UTXO (you can modify this to select a specific one)
UTXO_INDEX=0
echo -e "${YELLOW}Using UTXO #${UTXO_INDEX}${NC}"

# Extract UTXO details
TXID=$(echo "$UTXOS" | jq -r ".[${UTXO_INDEX}].txid")
VOUT=$(echo "$UTXOS" | jq -r ".[${UTXO_INDEX}].vout")
AMOUNT=$(echo "$UTXOS" | jq -r ".[${UTXO_INDEX}].amount")
ADDRESS=$(echo "$UTXOS" | jq -r ".[${UTXO_INDEX}].address")
CONFIRMATIONS=$(echo "$UTXOS" | jq -r ".[${UTXO_INDEX}].confirmations")

# Construct UTXO identifier
UTXO_ID="${TXID}:${VOUT}"

# Calculate app_id (SHA256 hash of UTXO ID)
APP_ID=$(echo -n "${UTXO_ID}" | sha256sum | cut -d' ' -f1)

# Get the raw transaction for prev_txs
RAW_TX=$(bitcoin-cli -${NETWORK} getrawtransaction "${TXID}")

# Export environment variables
export in_utxo_0="${UTXO_ID}"
export app_id="${APP_ID}"
export addr_0="${ADDRESS}"
export prev_txs="${RAW_TX}"

# Display the exported variables
echo
echo -e "${GREEN}=== Exported Environment Variables ===${NC}"
echo -e "${YELLOW}in_utxo_0${NC}  = ${in_utxo_0}"
echo -e "${YELLOW}app_id${NC}     = ${app_id}"
echo -e "${YELLOW}addr_0${NC}     = ${addr_0}"
echo -e "${YELLOW}prev_txs${NC}   = ${prev_txs:0:80}... (truncated)"
echo
echo -e "${GREEN}UTXO Details:${NC}"
echo "  Amount: ${AMOUNT} BTC"
echo "  Confirmations: ${CONFIRMATIONS}"
echo

# Save to a file for later use
ENV_FILE=".env.utxo"
cat > "${ENV_FILE}" << EOF
# NFTCharm UTXO Environment Variables
# Generated: $(date)

export in_utxo_0="${in_utxo_0}"
export app_id="${app_id}"
export addr_0="${addr_0}"
export prev_txs="${prev_txs}"

# UTXO Details
# Amount: ${AMOUNT} BTC
# Confirmations: ${CONFIRMATIONS}
# Network: ${NETWORK}
# Wallet: ${WALLET}
EOF

echo -e "${GREEN}Variables saved to ${ENV_FILE}${NC}"
echo "To load these variables later, run:"
echo -e "  ${YELLOW}source ${ENV_FILE}${NC}"
echo

# Create a helper command to use these variables
echo -e "${YELLOW}Example usage with charms:${NC}"
echo "  cd my-token"
echo "  charms app build"
echo "  # Use the exported variables in your spell files"
echo

# Optionally display the command to mint NFT
cat << 'EOF'
To mint an NFT using these variables, update your spell file with:
  - UTXO: $in_utxo_0
  - App Identity: $app_id
  - Address: $addr_0
EOF
