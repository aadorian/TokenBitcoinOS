# NFTCharm Quick Start Guide

## Prerequisites

1. **Bitcoin Core** running on testnet4
2. **Node.js** (>= 14.0.0)
3. **NFTCharm wallet** loaded (`nftcharm_wallet`)

## Setup

### 1. Install Dependencies

```bash
cd gui
npm install
```

### 2. Start the GUI

```bash
./start.sh
```

Or manually:

```bash
node server-enhanced.js
```

### 3. Open in Browser

Navigate to:
```
http://localhost:3000/app.html
```

## Usage

### Dashboard
- View your BTC balance
- See your wallet address
- Check recent transactions
- Monitor Bitcoin Core connection status

### Send BTC
1. Go to "Send BTC" tab
2. Enter recipient address (e.g., `tb1q...`)
3. Enter amount in BTC (e.g., `0.001`)
4. Set fee rate in sat/vB (default: `1`)
5. Click "Send Transaction"
6. Transaction automatically confirms and broadcasts

### Check Token Balance
1. Go to "Token Balance" tab
2. Click "Check Balance"
3. View all token and NFT UTXOs in terminal output

### NFT Management

#### Create NFT
1. Go to "NFT Management" tab
2. Click "Create NFT"
3. Wait for transaction to complete
4. Note the NFT UTXO for minting

#### Mint Tokens
1. Update `mint-tokens.sh` with your NFT UTXO
2. Click "Mint Tokens"
3. Tokens will be minted from your NFT

#### Transfer Tokens
1. Click "Transfer Tokens"
2. Follow prompts in terminal output
3. Enter source UTXOs and destination addresses

### View Transaction Spell
1. Go to "Transactions" tab
2. Enter transaction ID
3. Click "View"
4. See decoded spell content

## Available Scripts

All scripts can be run from the GUI or command line:

- `./check-balance.sh` - Check token balances
- `./send-btc.sh <address> <amount> [fee_rate]` - Send BTC
- `./create-nft.sh` - Create new NFT
- `./mint-tokens.sh` - Mint tokens from NFT
- `./transfer-tokens.sh` - Transfer tokens
- `./spell.sh <txid>` - View transaction spell

## Troubleshooting

### Port Already in Use
```bash
# Kill process on port 3000
lsof -ti:3000 | xargs kill -9
```

### Bitcoin Core Not Connected
```bash
# Check Bitcoin Core is running
bitcoin-cli -testnet4 getblockchaininfo

# Load wallet
bitcoin-cli -testnet4 loadwallet "nftcharm_wallet"
```

### Dependencies Missing
```bash
cd gui
npm install
```

### Scripts Not Executing
```bash
# Make scripts executable
chmod +x *.sh
```

## API Testing

Test endpoints with curl:

```bash
# Check status
curl http://localhost:3000/status

# Get balance
curl http://localhost:3000/balance

# Send BTC
curl -X POST http://localhost:3000/scripts/send-btc \
  -H "Content-Type: application/json" \
  -d '{"address":"tb1q...", "amount":"0.001", "feeRate":"1"}'

# Check token balance
curl -X POST http://localhost:3000/scripts/check-balance

# View spell
curl -X POST http://localhost:3000/scripts/spell \
  -H "Content-Type: application/json" \
  -d '{"txid":"abc123..."}'
```

## Features

✅ Real-time Bitcoin Core connection monitoring
✅ Automatic balance updates
✅ WebSocket support for live script output
✅ Terminal-style output for all scripts
✅ Auto-confirmation for transactions
✅ Modern UI with Tailwind CSS + Flowbite
✅ Responsive design
✅ Error handling and notifications

## Security Notes

⚠️ This GUI is for **testnet only**
⚠️ Auto-confirms transactions - review before using on mainnet
⚠️ Runs locally on port 3000 - not exposed to internet
⚠️ Uses local Bitcoin Core RPC - ensure proper authentication

## Need Help?

Check the full documentation:
- [GUI README](gui/README.md)
- [Main README](README.md)

## License

MIT
