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

# Function to view spell content from transaction ID
view_spell() {
    local txid=$1
    if [ -z "$txid" ]; then
        echo "Error: Transaction ID required"
        echo "Usage: $0 <txid>"
        exit 1
    fi

    echo "=========================================="
    echo "SPELL CONTENT VIEWER"
    echo "=========================================="
    echo "Transaction ID: $txid"
    echo ""

    # Get raw transaction hex
    echo "Fetching transaction from Bitcoin network..."
    raw_hex=$($BTC_CLI getrawtransaction "$txid" 2>/dev/null || echo "")

    if [ -z "$raw_hex" ]; then
        echo "Error: Could not fetch transaction $txid"
        echo "Make sure bitcoind is running and the transaction exists"
        exit 1
    fi

    # Decode transaction
    echo "Decoding transaction..."
    decoded=$($BTC_CLI decoderawtransaction "$raw_hex")

    echo ""
    echo "Transaction Details:"
    echo "===================="
    echo "$decoded" | jq '{
        txid: .txid,
        version: .version,
        size: .size,
        vsize: .vsize,
        weight: .weight,
        inputs: [.vin[] | {
            txid: .txid,
            vout: .vout,
            witness_items: (.txinwitness | length)
        }],
        outputs: [.vout[] | {
            value: .value,
            type: .scriptPubKey.type,
            address: .scriptPubKey.address
        }]
    }'

    echo ""
    echo "Raw Transaction Hex:"
    echo "===================="
    echo "$raw_hex"
    echo ""

    echo "Witness Data (Spell Content):"
    echo "=============================="

    # Extract witness data from inputs
    witness_count=$(echo "$decoded" | jq '[.vin[].txinwitness] | length' 2>/dev/null || echo "0")

    if [ "$witness_count" -eq 0 ]; then
        echo "No witness data found in this transaction"
    else
        echo "Found $witness_count witness stack(s)"
        echo ""

        # Display witness data for each input
        input_idx=0
        echo "$decoded" | jq -c '.vin[]' | while read -r input; do
            echo "Input #$input_idx:"
            echo "$input" | jq '{
                txid: .txid,
                vout: .vout,
                witness_items: (.txinwitness | length),
                witness: .txinwitness
            }'

            # Try to decode spell data from witness
            witness_items=$(echo "$input" | jq -r '.txinwitness[]?' 2>/dev/null || echo "")

            item_idx=0
            for witness in $witness_items; do
                echo ""
                echo "  Witness Item #$item_idx:"
                echo "  Hex: ${witness:0:100}..."

                # Convert hex to ASCII and look for readable text
                decoded_text=$(echo "$witness" | xxd -r -p 2>/dev/null | strings -n 4 2>/dev/null || echo "")

                if [ -n "$decoded_text" ]; then
                    echo "  Decoded text:"
                    echo "$decoded_text" | sed 's/^/    /'

                    # Check for spell-specific keywords
                    if echo "$decoded_text" | grep -q "spell"; then
                        echo ""
                        echo "  *** SPELL DATA DETECTED ***"
                    fi

                    if echo "$decoded_text" | grep -q "MY-TOKEN\|ticker"; then
                        echo "  *** TOKEN DATA DETECTED ***"
                        echo "$decoded_text" | grep -E "ticker|MY-TOKEN|remaining|version" | sed 's/^/    /'
                    fi
                fi

                item_idx=$((item_idx + 1))
            done

            echo ""
            echo "---"
            input_idx=$((input_idx + 1))
        done
    fi

    echo ""
    echo "=========================================="
    echo "Summary:"
    echo "  - Transaction: $txid"
    echo "  - Size: $(echo "$decoded" | jq -r '.size') bytes"
    echo "  - Virtual Size: $(echo "$decoded" | jq -r '.vsize') vbytes"
    echo "  - Inputs: $(echo "$decoded" | jq -r '.vin | length')"
    echo "  - Outputs: $(echo "$decoded" | jq -r '.vout | length')"
    echo "=========================================="
}

# Main execution
# Default transaction ID if none provided
DEFAULT_TXID="d8786af1e7e597d77c073905fd6fd7053e4d12894eefa19c5deb45842fc2a8a2"

if [ -z "$1" ]; then
    echo "No transaction ID provided, using default: $DEFAULT_TXID"
    echo ""
    view_spell "$DEFAULT_TXID"
else
    view_spell "$1"
fi
