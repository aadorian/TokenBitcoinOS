# Test Transfer Guide

This guide explains how to test your NFTCharm token by sending it from your default address back to itself.

## Prerequisites

1. You have already minted tokens using [workflow.sh](workflow.sh)
2. Your wallet (`nftcharm_wallet`) has tokens at UTXO: `d8786af1e7e597d77c073905fd6fd7053e4d12894eefa19c5deb45842fc2a8a2:0`
3. You have additional UTXOs for paying transaction fees

## Quick Start

Simply run the quick transfer script:

```bash
./quick-transfer.sh
```

This script will:
1. Load your app verification key
2. Use the token UTXO from your minting transaction
3. Send tokens to the same address (proving the transfer mechanism works)
4. Create and broadcast both commit and spell transactions
5. Display the transaction IDs for verification

## What the Script Does

The script performs a token transfer using the [send.yaml](my-token/spells/send.yaml) spell template:

- **From**: UTXO `d8786af1e7e597d77c073905fd6fd7053e4d12894eefa19c5deb45842fc2a8a2:0` (contains 69,420 tokens)
- **To**: Same address (split into two outputs)
  - Output 1: 420 tokens
  - Output 2: 69,000 tokens (change)

## Understanding the Transfer

### The Two-Transaction Model

Like Bitcoin Ordinals, Charms use a two-transaction model:

1. **Commit Transaction**: Sets up the transfer by creating a Taproot output
2. **Spell Transaction**: Reveals the spell and proof, spending the Taproot output

Both transactions are broadcast together as a package.

### Key Parameters

The script uses these key values (automatically configured):

```bash
# App identity (from original witness UTXO)
app_id="2ed3939eceafa9cdd5495e224c64f20b17e517bb7629153f1d5b5b0e3e87d2f5"

# App verification key (from your build)
app_vk="175affa66db36da14c819c6e7396e5bc21d5315a878b4f6800f980e646c9e649"

# Token UTXO (from minting)
in_utxo_1="d8786af1e7e597d77c073905fd6fd7053e4d12894eefa19c5deb45842fc2a8a2:0"

# Original witness UTXO (defines app identity)
original_witness_utxo="f62d75e7c52c1929c63033b797947d8af0f4e720cc5d67be5198e24491818941:0"
```

## Viewing the Transfer

After the script completes, you can view the spell transaction:

```bash
./spell.sh <spell_txid>
```

This will show:
- Transaction summary
- Token ticker (MY-TOKEN)
- Witness data with spell content
- Token amounts in outputs

## Customizing the Transfer

If you want to modify the transfer amounts or addresses, edit [my-token/spells/send.yaml](my-token/spells/send.yaml):

```yaml
version: 8

apps:
  $01: t/${app_id}/${app_vk}

ins:
  - utxo_id: ${in_utxo_1}
    charms:
      $01: 69420  # Total tokens in input

outs:
  - address: ${addr_3}
    charms:
      $01: 420    # Tokens to recipient

  - address: ${addr_4}
    charms:
      $01: 69000  # Change tokens
```

Then run the script again.

## Manual Transfer (Step-by-Step)

If you prefer to run the transfer manually, use [test-transfer.sh](test-transfer.sh) which provides an interactive mode:

```bash
./test-transfer.sh
```

This will prompt you to enter the token UTXO manually and shows more detailed information at each step.

## Troubleshooting

### "No suitable funding UTXO found"

You need a UTXO with at least 0.0001 BTC that isn't the token UTXO. Generate one:

```bash
bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" sendtoaddress $(bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" getnewaddress) 0.001
```

### "Transaction rejected by mempool"

Check the error reason. Common issues:
- Insufficient fees (increase funding UTXO amount)
- Invalid spell (verify app_id and app_vk match your build)
- UTXO already spent (use a different token UTXO)

### "Could not fetch transaction"

The transaction might not be in your local node or mempool.space. Options:
1. Wait for the transaction to be broadcast/confirmed
2. Enable `-txindex` on your Bitcoin node
3. Check if you're on the correct network (testnet4)

## Token Information

Your current token setup:

- **Ticker**: MY-TOKEN
- **Original Supply**: 100,000 tokens (NFT remaining count)
- **Minted**: 69,420 tokens
- **Current UTXO**: `d8786af1e7e597d77c073905fd6fd7053e4d12894eefa19c5deb45842fc2a8a2:0`

## Next Steps

After successfully testing the transfer:

1. ✓ Verify the token is working
2. Send tokens to different addresses
3. Implement additional token features
4. Create a frontend for easier transfers
5. Deploy to mainnet (when ready)

## Additional Resources

- [Workflow Documentation](docs/README_Workflow.md) - Complete workflow details
- [Proof Onboarding](docs/PROOF_ONBOARDING.md) - Understanding proofs
- [Spell Viewer](spell.sh) - View transaction details
- [Main README](README.md) - Project overview
