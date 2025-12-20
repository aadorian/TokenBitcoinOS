# Bitcoin CLI Guide for NFTCharm

This guide provides complete instructions for using Bitcoin Core CLI with the NFTCharm token application on Bitcoin testnet4.

## Table of Contents
- [Installation](#installation)
- [Configuration](#configuration)
- [Starting Bitcoin Daemon](#starting-bitcoin-daemon)
- [Wallet Setup](#wallet-setup)
- [Working with Addresses](#working-with-addresses)
- [Transactions](#transactions)
- [Common Operations](#common-operations)
- [Troubleshooting](#troubleshooting)

## Installation

### macOS
```bash
brew install bitcoin
```

### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install bitcoind bitcoin-cli
```

### From Source
Download from [bitcoincore.org](https://bitcoincore.org/en/download/)

Verify installation:
```bash
bitcoin-cli --version
bitcoind --version
```

## Configuration

Create a Bitcoin configuration file to optimize for testnet4:

**macOS/Linux:** `~/.bitcoin/bitcoin.conf`

```conf
# Network
testnet4=1

# RPC Settings
server=1
rpcuser=yourusername
rpcpassword=yourpassword
rpcallowip=127.0.0.1

# Performance
dbcache=450
maxmempool=300

# Logging
debug=0
```

**Note:** Replace `yourusername` and `yourpassword` with your own credentials.

## Starting Bitcoin Daemon

### Start on Testnet4
```bash
bitcoind -testnet4 -daemon
```

### Check if Running
```bash
bitcoin-cli -testnet4 getblockchaininfo
```

### Stop Daemon
```bash
bitcoin-cli -testnet4 stop
```

### View Logs
```bash
tail -f ~/.bitcoin/testnet4/debug.log
```

## Wallet Setup

### Create a New Wallet
```bash
bitcoin-cli -testnet4 createwallet "nftcharm_wallet"
```

### Load Existing Wallet
```bash
bitcoin-cli -testnet4 loadwallet "nftcharm_wallet"
```

### List Wallets
```bash
bitcoin-cli -testnet4 listwallets
```

### Get Wallet Info
```bash
bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" getwalletinfo
```

### Backup Wallet
```bash
bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" backupwallet "/path/to/backup/wallet.dat"
```

## Working with Addresses

### Generate New Address
```bash
bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" getnewaddress
```

Example output:
```
tb1q4hljlww9gw6vdk7gakw9r5ktplhxj5knecawqt
```

### Generate Legacy Address
```bash
bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" getnewaddress "" "legacy"
```

### Generate SegWit Address
```bash
bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" getnewaddress "" "bech32"
```

### Validate Address
```bash
bitcoin-cli -testnet4 validateaddress tb1q4hljlww9gw6vdk7gakw9r5ktplhxj5knecawqt
```

### Get Address Info
```bash
bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" getaddressinfo tb1q4hljlww9gw6vdk7gakw9r5ktplhxj5knecawqt
```

### List Receiving Addresses
```bash
bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" listreceivedbyaddress 0 true
```

## Transactions

### Get Wallet Balance
```bash
bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" getbalance
```

### Get Unconfirmed Balance
```bash
bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" getunconfirmedbalance
```

### Send to Address
```bash
bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" sendtoaddress \
  "tb1q4hljlww9gw6vdk7gakw9r5ktplhxj5knecawqt" \
  0.001
```

### Send with Comment
```bash
bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" sendtoaddress \
  "tb1q4hljlww9gw6vdk7gakw9r5ktplhxj5knecawqt" \
  0.001 \
  "NFT minting fee" \
  "Payment for token mint"
```

### List Transactions
```bash
bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" listtransactions
```

### Get Transaction Details
```bash
bitcoin-cli -testnet4 gettransaction <txid>
```

### Get Raw Transaction
```bash
bitcoin-cli -testnet4 getrawtransaction <txid> true
```

### Create Raw Transaction
```bash
bitcoin-cli -testnet4 createrawtransaction \
  '[{"txid":"<previous_txid>","vout":0}]' \
  '{"tb1q4hljlww9gw6vdk7gakw9r5ktplhxj5knecawqt":0.001}'
```

### Sign Raw Transaction
```bash
bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" signrawtransactionwithwallet <hex>
```

### Send Raw Transaction
```bash
bitcoin-cli -testnet4 sendrawtransaction <signed_hex>
```

## Common Operations

### Get Blockchain Info
```bash
bitcoin-cli -testnet4 getblockchaininfo
```

Expected output includes:
```json
{
  "chain": "testnet4",
  "blocks": 123456,
  "headers": 123456,
  "bestblockhash": "...",
  "difficulty": 1.0,
  "verification_progress": 0.9999
}
```

### Get Network Info
```bash
bitcoin-cli -testnet4 getnetworkinfo
```

### Get Peer Info
```bash
bitcoin-cli -testnet4 getpeerinfo
```

### Get Block Count
```bash
bitcoin-cli -testnet4 getblockcount
```

### Get Best Block Hash
```bash
bitcoin-cli -testnet4 getbestblockhash
```

### Get Block by Hash
```bash
bitcoin-cli -testnet4 getblock <blockhash>
```

### Estimate Smart Fee
```bash
bitcoin-cli -testnet4 estimatesmartfee 6
```

### Get Memory Pool Info
```bash
bitcoin-cli -testnet4 getmempoolinfo
```

### Get Raw Mempool
```bash
bitcoin-cli -testnet4 getrawmempool
```

## NFTCharm-Specific Operations

### Fund Testnet Wallet
Get testnet coins from a faucet:
- [https://testnet4.anyone.eu.org/](https://testnet4.anyone.eu.org/)
- [https://bitcoinfaucet.uo1.net/](https://bitcoinfaucet.uo1.net/)

Then check balance:
```bash
bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" getbalance
```

### Prepare for Token Minting

1. **Generate receiving address:**
```bash
ADDR=$(bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" getnewaddress)
echo "Your address: $ADDR"
# Example output: tb1q4hljlww9gw6vdk7gakw9r5ktplhxj5knecawqt
```

2. **Get funds from faucet**
[Faucet](https://faucet.testnet4.dev/)
 (paste your address, e.g., tb1q4hljlww9gw6vdk7gakw9r5ktplhxj5knecawqt)

3. **Wait for confirmation:**
```bash
bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" listunspent 1
```

4. **Check UTXO availability:**
```bash
bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" listunspent 0
```

### Create Token Transaction

1. **List available UTXOs:**
```bash
bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" listunspent
```

2. **Create transaction for token operation:**
```bash
bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" createrawtransaction \
  '[{"txid":"<utxo_txid>","vout":0}]' \
  '{"tb1q4hljlww9gw6vdk7gakw9r5ktplhxj5knecawqt":0.0001, "data":"<token_metadata_hex>"}'
```

3. **Sign and broadcast:**
```bash
SIGNED=$(bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" signrawtransactionwithwallet <raw_hex> | jq -r '.hex')
bitcoin-cli -testnet4 sendrawtransaction $SIGNED
```

### Monitor Token Transactions

1. **Watch for confirmations:**
```bash
bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" listtransactions "*" 10
```

2. **Check specific transaction:**
```bash
bitcoin-cli -testnet4 gettransaction <txid> true
```

3. **Get confirmation count:**
```bash
bitcoin-cli -testnet4 gettransaction <txid> | jq '.confirmations'
```

## Example Workflow: Minting NFT on Testnet4

```bash
# 1. Start daemon
bitcoind -testnet4 -daemon

# 2. Create/load wallet
bitcoin-cli -testnet4 createwallet "nftcharm_wallet"

# 3. Generate address
MINT_ADDR=$(bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" getnewaddress)
echo "Mint address: $MINT_ADDR"
# Example output: tb1q4hljlww9gw6vdk7gakw9r5ktplhxj5knecawqt

# 4. Fund from faucet (external step)
# Visit faucet and send to $MINT_ADDR

# 5. Wait for funds
watch -n 10 'bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" getbalance'

# 6. Verify UTXOs
bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" listunspent 1

# 7. Use with Charms app
cd my-token
charms app build

# 8. Create mint spell transaction (see spells/mint-nft.yaml)
# This integrates with the Charms SDK

# 9. Monitor transaction
bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" listtransactions
```

## Troubleshooting

### Daemon Won't Start
```bash
# Check if already running
ps aux | grep bitcoind

# Check logs
tail -f ~/.bitcoin/testnet4/debug.log

# Try with verbose output
bitcoind -testnet4 -printtoconsole
```

### Connection Refused
Ensure daemon is running:
```bash
bitcoin-cli -testnet4 getblockchaininfo
```

If it fails, restart:
```bash
bitcoind -testnet4 -daemon
```

### Insufficient Funds
```bash
# Check balance
bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" getbalance

# Check unconfirmed
bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" getunconfirmedbalance

# List all transactions
bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" listtransactions "*" 100
```

### Wallet Not Found
```bash
# List available wallets
bitcoin-cli -testnet4 listwalletdir

# Load wallet
bitcoin-cli -testnet4 loadwallet "nftcharm_wallet"
```

### Slow Synchronization
```bash
# Check sync progress
bitcoin-cli -testnet4 getblockchaininfo | jq '.verificationprogress'

# Increase dbcache in bitcoin.conf
# dbcache=2048

# Restart daemon
bitcoin-cli -testnet4 stop
bitcoind -testnet4 -daemon
```

### Transaction Not Confirming
```bash
# Check mempool
bitcoin-cli -testnet4 getmempoolentry <txid>

# Check fee rate
bitcoin-cli -testnet4 estimatesmartfee 6

# Bump fee (if RBF enabled)
bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" bumpfee <txid>
```

## Useful Resources

- **Bitcoin Core Documentation:** [https://bitcoin.org/en/bitcoin-core/](https://bitcoin.org/en/bitcoin-core/)
- **Bitcoin CLI Reference:** [https://developer.bitcoin.org/reference/rpc/](https://developer.bitcoin.org/reference/rpc/)
- **Testnet4 Explorer:** [https://mempool.space/testnet4](https://mempool.space/testnet4)
- **Testnet4 Faucets:**
  - [https://testnet4.anyone.eu.org/](https://testnet4.anyone.eu.org/)
  - [https://bitcoinfaucet.uo1.net/](https://bitcoinfaucet.uo1.net/)

## Security Notes

⚠️ **Important Security Reminders:**

1. **Never use testnet4 wallets on mainnet** - testnet coins have no real value
2. **Backup your wallet** regularly with `backupwallet`
3. **Use strong RPC credentials** in bitcoin.conf
4. **Don't expose RPC to the internet** - keep `rpcallowip=127.0.0.1`
5. **Keep private keys secure** - never share wallet files or seed phrases
6. **Test thoroughly on testnet4** before considering any mainnet operations

## Integration with NFTCharm

The NFTCharm token system uses Bitcoin testnet4 as the settlement layer. When you run the Charms application:

1. **Token minting** creates on-chain Bitcoin transactions
2. **Transfer operations** are validated against Bitcoin UTXOs
3. **State commitments** are anchored to the Bitcoin blockchain
4. **Verification keys** ensure token authenticity

For integration details, see:
- [my-token/src/lib.rs](my-token/src/lib.rs) - Token contract implementation
- [my-token/spells/](my-token/spells/) - Transaction spell definitions
- [README.md](README.md) - Main project documentation

## Quick Reference

| Operation | Command |
|-----------|---------|
| Start daemon | `bitcoind -testnet4 -daemon` |
| Stop daemon | `bitcoin-cli -testnet4 stop` |
| Get balance | `bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" getbalance` |
| New address | `bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" getnewaddress` |
| Send coins | `bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" sendtoaddress <addr> <amount>` |
| List transactions | `bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" listtransactions` |
| Blockchain info | `bitcoin-cli -testnet4 getblockchaininfo` |
| Validate address | `bitcoin-cli -testnet4 validateaddress <address>` |
| Estimate fee | `bitcoin-cli -testnet4 estimatesmartfee 6` |
| List UTXOs | `bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" listunspent` |

---

For questions or issues, please refer to [CONTRIBUTING.md](CONTRIBUTING.md) or open an issue on GitHub.
