#!/bin/bash
set -e

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

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

# Function to view spell content from transaction data
view_spell() {
    local decoded=$1

    echo ""
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}📊 Transaction Summary${NC}"
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    tx_size=$(echo "$decoded" | jq -r '.size')
    tx_vsize=$(echo "$decoded" | jq -r '.vsize')
    tx_weight=$(echo "$decoded" | jq -r '.weight')
    input_count=$(echo "$decoded" | jq -r '.vin | length')
    output_count=$(echo "$decoded" | jq -r '.vout | length')

    echo -e "  Size: ${CYAN}${tx_size}${NC} bytes | vSize: ${CYAN}${tx_vsize}${NC} vbytes | Weight: ${CYAN}${tx_weight}${NC}"
    echo -e "  Inputs: ${CYAN}${input_count}${NC} | Outputs: ${CYAN}${output_count}${NC}"
    echo ""

    echo -e "${BOLD}${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}🔮 Witness Data (Spell Content)${NC}"
    echo -e "${BOLD}${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Extract witness data from inputs
    witness_count=$(echo "$decoded" | jq '[.vin[].txinwitness] | length' 2>/dev/null || echo "0")

    if [ "$witness_count" -eq 0 ]; then
        echo -e "${YELLOW}No witness data found in this transaction${NC}"
    else
        echo -e "Found ${GREEN}${witness_count}${NC} witness stack(s)"
        echo ""

        # Display witness data for each input
        input_idx=0
        echo "$decoded" | jq -c '.vin[]' | while read -r input; do
            witness_item_count=$(echo "$input" | jq -r '.txinwitness | length')

            echo -e "${BOLD}┌─ Input #${input_idx} (${witness_item_count} witness items)${NC}"

            # Try to decode spell data from witness
            witness_items=$(echo "$input" | jq -r '.txinwitness[]?' 2>/dev/null || echo "")

            item_idx=0
            has_spell=false
            has_token=false

            for witness in $witness_items; do
                # Convert hex to ASCII and look for readable text
                decoded_text=$(echo "$witness" | xxd -r -p 2>/dev/null | strings -n 4 2>/dev/null || echo "")

                if [ -n "$decoded_text" ]; then
                    # Check for spell-specific keywords
                    if echo "$decoded_text" | grep -q "spell"; then
                        has_spell=true
                    fi

                    if echo "$decoded_text" | grep -q "ticker"; then
                        has_token=true
                    fi
                fi

                item_idx=$((item_idx + 1))
            done

            # Display spell/token indicators
            if [ "$has_spell" = true ]; then
                echo -e "${BOLD}│ ${GREEN}✓ SPELL DATA DETECTED${NC}"
            fi

            if [ "$has_token" = true ]; then
                echo -e "${BOLD}│ ${GREEN}✓ TOKEN DATA DETECTED${NC}"

                # Extract and display token info
                item_idx=0
                for witness in $witness_items; do
                    decoded_text=$(echo "$witness" | xxd -r -p 2>/dev/null | strings -n 4 2>/dev/null || echo "")

                    if echo "$decoded_text" | grep -q "ticker"; then
                        ticker=$(echo "$decoded_text" | grep -o "MY-TOKEN" | head -1)
                        remaining=$(echo "$decoded_text" | grep -o "remaining" | head -1)

                        if [ -n "$ticker" ]; then
                            echo -e "${BOLD}│${NC}"
                            echo -e "${BOLD}│ 🪙  Token Info:${NC}"
                            echo -e "${BOLD}│${NC}    ${CYAN}Ticker:${NC} ${YELLOW}$ticker${NC}"

                            # Try to extract remaining amount (this is a simplified extraction)
                            # You may need to enhance this based on your data format
                            if [ -n "$remaining" ]; then
                                echo -e "${BOLD}│${NC}    ${CYAN}Status:${NC} Has remaining supply"
                            fi
                        fi
                        break
                    fi
                    item_idx=$((item_idx + 1))
                done
            fi

            echo -e "${BOLD}└─────────────────────────────────────────${NC}"
            echo ""
            input_idx=$((input_idx + 1))
        done
    fi

    # Add option to view detailed output
    echo ""
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Options:${NC}"
    echo -e "  ${CYAN}• Add --detailed flag to see full transaction JSON${NC}"
    echo -e "  ${CYAN}• Add --raw flag to see raw hex data${NC}"
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to view detailed transaction data
view_detailed() {
    local txid=$1
    local raw_hex=$2
    local decoded=$3

    echo ""
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}📋 Detailed Transaction Data${NC}"
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    echo "$decoded" | jq '.' --color-output 2>/dev/null || echo "$decoded" | jq '.'
}

# Function to view raw hex
view_raw() {
    local raw_hex=$1

    echo ""
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}🔤 Raw Transaction Hex${NC}"
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "$raw_hex" | fold -w 80
}

# Main execution
# Default transaction ID if none provided
DEFAULT_TXID="d8786af1e7e597d77c073905fd6fd7053e4d12894eefa19c5deb45842fc2a8a2"

# Parse arguments
TXID=""
SHOW_DETAILED=false
SHOW_RAW=false

for arg in "$@"; do
    case $arg in
        --detailed)
            SHOW_DETAILED=true
            shift
            ;;
        --raw)
            SHOW_RAW=true
            shift
            ;;
        --help)
            echo "Usage: $0 [txid] [--detailed] [--raw]"
            echo ""
            echo "Options:"
            echo "  txid        Transaction ID to view (optional)"
            echo "  --detailed  Show full transaction JSON"
            echo "  --raw       Show raw transaction hex"
            echo "  --help      Show this help message"
            exit 0
            ;;
        *)
            if [ -z "$TXID" ]; then
                TXID=$arg
            fi
            ;;
    esac
done

if [ -z "$TXID" ]; then
    echo -e "${YELLOW}No transaction ID provided, using default${NC}"
    echo ""
    TXID=$DEFAULT_TXID
fi

# Store raw_hex and decoded for use in detailed/raw views
echo -e "${BOLD}${CYAN}=========================================="
echo -e "         SPELL CONTENT VIEWER"
echo -e "==========================================${NC}"
echo -e "${BOLD}Transaction ID:${NC} ${YELLOW}$TXID${NC}"
echo ""

# Get raw transaction hex
echo "Fetching transaction from Bitcoin network..."
raw_hex=$($BTC_CLI getrawtransaction "$TXID" 2>/dev/null || echo "")

if [ -z "$raw_hex" ]; then
    echo -e "${YELLOW}Local node failed, trying mempool.space API...${NC}"

    # Determine API URL based on network
    if [ "$NETWORK" = "testnet4" ]; then
        api_url="https://mempool.space/testnet4/api/tx/$TXID/hex"
    elif [ "$NETWORK" = "test" ]; then
        api_url="https://mempool.space/testnet/api/tx/$TXID/hex"
    elif [ "$NETWORK" = "regtest" ]; then
        echo -e "${RED}Error: Cannot fetch regtest transaction from external API${NC}"
        echo "Enable txindex on your local node: bitcoind -regtest -txindex -reindex"
        exit 1
    else
        api_url="https://mempool.space/api/tx/$TXID/hex"
    fi

    raw_hex=$(curl -s "$api_url")

    if [ -z "$raw_hex" ] || echo "$raw_hex" | grep -q "Transaction not found"; then
        echo -e "${RED}Error: Could not fetch transaction $TXID${NC}"
        echo ""
        echo "Solutions:"
        echo "  1. Enable txindex on your local node:"
        echo "     bitcoind -testnet4 -txindex -reindex"
        echo "  2. Check if the transaction exists on mempool.space"
        exit 1
    fi

    echo -e "${GREEN}✓ Successfully fetched from mempool.space${NC}"
else
    echo -e "${GREEN}✓ Fetched from local Bitcoin node${NC}"
fi

# Decode transaction
echo "Decoding transaction..."
decoded=$($BTC_CLI decoderawtransaction "$raw_hex")

# Show main spell view
view_spell "$decoded"

# Show additional views if requested
if [ "$SHOW_DETAILED" = true ]; then
    view_detailed "$TXID" "$raw_hex" "$decoded"
fi

if [ "$SHOW_RAW" = true ]; then
    view_raw "$raw_hex"
fi
