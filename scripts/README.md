# NFTCharm Scripts

Utility scripts for working with Bitcoin testnet4 and NFTCharm token operations.

## Scripts

### setup-utxo-vars.sh

Interactive script that fetches UTXO information from your Bitcoin wallet and exports environment variables needed for NFT minting.

**Usage:**
```bash
# Run interactively
source ./scripts/setup-utxo-vars.sh

# Or run and save to file
./scripts/setup-utxo-vars.sh
source .env.utxo
```

**What it does:**
- Connects to Bitcoin testnet4 node
- Lists all confirmed UTXOs in the `nftcharm_wallet`
- Selects the first available UTXO
- Calculates the app_id (SHA256 hash of UTXO ID)
- Fetches the raw transaction data
- Exports environment variables
- Saves variables to `.env.utxo` file

**Exported Variables:**
- `in_utxo_0` - UTXO identifier (txid:vout)
- `app_id` - SHA256 hash of the UTXO ID (NFT identity)
- `addr_0` - Bitcoin address that owns the UTXO
- `prev_txs` - Raw transaction hex data

### export-utxo.sh

Minimal script that outputs export commands for UTXO variables. Designed to be used with `eval`.

**Usage:**
```bash
# Export variables to current shell
eval $(./scripts/export-utxo.sh)

# Check the exported variables
echo $in_utxo_0
echo $app_id
echo $addr_0
```

**Example Output:**
```bash
export in_utxo_0="d8fa4cdade7ac3dff64047dc73b58591ebe638579881b200d4fea68fc84521f0:0"
export app_id="f54f6d40bd4ba808b188963ae5d72769ad5212dd1d29517ecc4063dd9f033faa"
export addr_0="tb1q4hljlww9gw6vdk7gakw9r5ktplhxj5knecawqt"
export prev_txs="02000000000101..."
```

## Prerequisites

Before running these scripts, ensure you have:

1. **Bitcoin Core installed and running:**
   ```bash
   bitcoind -testnet4 -daemon
   ```

2. **Wallet created and funded:**
   ```bash
   bitcoin-cli -testnet4 createwallet "nftcharm_wallet"
   bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" getnewaddress
   # Fund the address from a testnet4 faucet
   ```

3. **Required tools:**
   - `jq` - JSON processor
     ```bash
     # macOS
     brew install jq

     # Ubuntu/Debian
     sudo apt-get install jq
     ```
   - `sha256sum` (usually pre-installed on Linux/macOS)

## Workflow Example

Complete workflow for minting an NFT on testnet4:

```bash
# 1. Start Bitcoin daemon
bitcoind -testnet4 -daemon

# 2. Create and fund wallet
bitcoin-cli -testnet4 createwallet "nftcharm_wallet"
ADDR=$(bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" getnewaddress)
echo "Fund this address: $ADDR"
# Visit https://faucet.testnet4.dev/ and send funds

# 3. Wait for confirmation
bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" listunspent 1

# 4. Export UTXO variables
eval $(./scripts/export-utxo.sh)

# 5. Verify variables
echo "UTXO: $in_utxo_0"
echo "App ID: $app_id"
echo "Address: $addr_0"

# 6. Build and run NFTCharm app
cd my-token
charms app build

# 7. Use variables in your spell files
# Update spells/mint-nft.yaml with the exported variables
```

## Understanding the Variables

### in_utxo_0
The UTXO (Unspent Transaction Output) identifier in the format `txid:vout`.
- **txid**: Transaction ID (64-character hex string)
- **vout**: Output index (usually 0 or 1)

Example: `d8fa4cdade7ac3dff64047dc73b58591ebe638579881b200d4fea68fc84521f0:0`

### app_id
The NFT identity derived from hashing the UTXO ID. This ensures each NFT has a unique identity tied to a specific Bitcoin UTXO.

Calculation: `SHA256(in_utxo_0)`

Example: `f54f6d40bd4ba808b188963ae5d72769ad5212dd1d29517ecc4063dd9f033faa`

### addr_0
The Bitcoin testnet4 address (bech32m format) that owns the UTXO. This is where the NFT will be created.

Example: `tb1q4hljlww9gw6vdk7gakw9r5ktplhxj5knecawqt`

### prev_txs
The raw transaction data in hexadecimal format. This is used to prove the existence of the UTXO.

Example: `02000000000101a3a4c09a03f771e863517b8169ad6c08784d419e...`

## Troubleshooting

### "bitcoin-cli not found"
Install Bitcoin Core: `brew install bitcoin` (macOS) or see [bitcoincore.org](https://bitcoincore.org/en/download/)

### "Bitcoin daemon is not running"
Start the daemon: `bitcoind -testnet4 -daemon`

### "No confirmed UTXOs found"
1. Check if wallet is funded: `bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" getbalance`
2. Wait for confirmations (at least 1 block)
3. Get a new address and fund it from a faucet

### "jq: command not found"
Install jq: `brew install jq` (macOS) or `sudo apt-get install jq` (Ubuntu/Debian)

## Related Documentation

- [README_BITCOIN_CLI.md](../README_BITCOIN_CLI.md) - Complete Bitcoin CLI guide
- [my-token/spells/](../my-token/spells/) - Spell file examples
- [my-token/src/lib.rs](../my-token/src/lib.rs) - NFT contract implementation
