#!/bin/bash
#
# Charm Run - Execute NFT Charm Spell with UTXO Variables
#
# Usage: ./scripts/charm-run.sh [spell-file]
#        ./scripts/charm-run.sh mint-nft
#        ./scripts/charm-run.sh mint-token

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NETWORK="testnet4"
WALLET="nftcharm_wallet"
SPELL_DIR="my-token/spells"
APP_BIN="my-token/target/wasm32-unknown-unknown/release/my_token.wasm"

# Default spell
SPELL_NAME="${1:-mint-nft}"
SPELL_FILE="${SPELL_DIR}/${SPELL_NAME}.yaml"

echo -e "${BLUE}=== NFTCharm Spell Runner ===${NC}"
echo

# Check if spell file exists
if [ ! -f "$SPELL_FILE" ]; then
    echo -e "${RED}Error: Spell file not found: ${SPELL_FILE}${NC}"
    echo "Available spells:"
    ls -1 ${SPELL_DIR}/*.yaml 2>/dev/null | xargs -n1 basename | sed 's/.yaml$//' | sed 's/^/  - /'
    exit 1
fi

# Check if app binary exists
if [ ! -f "$APP_BIN" ]; then
    echo -e "${YELLOW}App binary not found. Building...${NC}"
    cd my-token
    charms app build
    cd ..
    echo -e "${GREEN}Build complete!${NC}"
    echo
fi

# Export UTXO variables
echo -e "${YELLOW}Fetching UTXO variables...${NC}"

# Get first unspent UTXO
UTXOS=$(bitcoin-cli -${NETWORK} -rpcwallet="${WALLET}" listunspent 1 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$UTXOS" ]; then
    echo -e "${RED}Error: Could not fetch UTXOs${NC}"
    echo "Make sure Bitcoin daemon is running: bitcoind -${NETWORK} -daemon"
    exit 1
fi

UTXO_COUNT=$(echo "$UTXOS" | jq 'length' 2>/dev/null)
if [ "$UTXO_COUNT" -eq 0 ]; then
    echo -e "${RED}Error: No confirmed UTXOs found${NC}"
    echo "Please fund your wallet first"
    exit 1
fi

# Extract UTXO details
TXID=$(echo "$UTXOS" | jq -r ".[0].txid")
VOUT=$(echo "$UTXOS" | jq -r ".[0].vout")
ADDRESS=$(echo "$UTXOS" | jq -r ".[0].address")
AMOUNT=$(echo "$UTXOS" | jq -r ".[0].amount")

# Construct UTXO identifier
export in_utxo_0="${TXID}:${VOUT}"

# Calculate app_id (SHA256 hash of UTXO ID)
export app_id=$(echo -n "${in_utxo_0}" | sha256sum | cut -d' ' -f1)

# Get the raw transaction
export prev_txs=$(bitcoin-cli -${NETWORK} getrawtransaction "${TXID}" 2>/dev/null)

# Export address
export addr_0="${ADDRESS}"

# Set app_bin
export app_bin="${APP_BIN}"

# Get app verification key
echo -e "${YELLOW}Getting app verification key...${NC}"
export app_vk=$(charms app vk "${APP_BIN}" 2>/dev/null)

if [ -z "$app_vk" ]; then
    echo -e "${RED}Error: Could not get app verification key${NC}"
    echo "Make sure the app is built correctly"
    exit 1
fi

# Display variables
echo -e "${GREEN}UTXO Variables:${NC}"
echo "  in_utxo_0: ${in_utxo_0}"
echo "  app_id:    ${app_id}"
echo "  addr_0:    ${addr_0}"
echo "  Amount:    ${AMOUNT} BTC"
echo "  app_bin:   ${app_bin}"
echo "  app_vk:    ${app_vk}"
echo

# Run the spell check
echo -e "${YELLOW}Running spell check: ${SPELL_NAME}${NC}"
echo -e "${BLUE}Command: cat ${SPELL_FILE} | envsubst | charms spell check --prev-txs=\${prev_txs} --app-bins=\${app_bin}${NC}"
echo

# Execute the command
cat "${SPELL_FILE}" | envsubst | charms spell check --prev-txs="${prev_txs}" --app-bins="${app_bin}"

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo
    echo -e "${GREEN}✓ Spell check completed successfully!${NC}"
else
    echo
    echo -e "${RED}✗ Spell check failed with exit code ${EXIT_CODE}${NC}"
    exit $EXIT_CODE
fi
