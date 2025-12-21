# NFTCharm Viewer

A modern web-based GUI for viewing NFTs and tokens on Bitcoin Testnet4 using the NFTCharm system.

## Features

- **Wallet Balance Display**: Real-time balance of nftcharm_wallet prominently displayed
- **Current Address Display**: Shows your wallet's receiving address with click-to-copy functionality
- **Real-time NFT Viewing**: Display NFTs with ticker symbols and remaining supply
- **Token Display**: View fungible tokens minted from NFTs
- **UTXO Explorer**: Browse all unspent transaction outputs in your wallet
- **Address Filtering**: View UTXOs for specific addresses
- **Beautiful UI**: Modern, responsive design with cards and animations
- **Live Status**: Real-time connection status to Bitcoin Core
- **Transaction Details**: View full transaction information

## Screenshots

The viewer displays:
- **Wallet balance** in the status bar (auto-updates every 10 seconds)
- **Current receiving address** with click-to-copy functionality
- NFT cards with ticker, remaining supply, and UTXO details
- Token cards with token amounts and addresses
- Plain Bitcoin UTXOs
- Real-time connection status

## Prerequisites

1. **Bitcoin Core** - Running on testnet4
2. **Node.js** - Version 14.0.0 or higher
3. **NFTCharm Wallet** - Wallet named `nftcharm_wallet` loaded in Bitcoin Core

## Installation

1. Navigate to the gui directory:
```bash
cd gui
```

2. Install dependencies:
```bash
npm install
```

## Configuration

### Bitcoin Core Setup

Ensure your Bitcoin Core is running with:
- Network: testnet4
- Wallet: `nftcharm_wallet` loaded
- RPC enabled

Example `bitcoin.conf`:
```
testnet4=1
server=1
rpcuser=your_username
rpcpassword=your_password
```

Load the wallet:
```bash
bitcoin-cli -testnet4 loadwallet "nftcharm_wallet"
```

## Usage

### Start the Server

```bash
npm start
```

Or for development with auto-reload:
```bash
npm run dev
```

### Access the GUI

Open your browser and navigate to:
```
http://localhost:3000
```

### Using the Interface

1. **View Wallet Balance**: The balance is displayed prominently in the status bar and auto-updates every 10 seconds
2. **View Current Address**: Your wallet's current receiving address is displayed - click to copy to clipboard
3. **View All Wallet UTXOs**: Click "Refresh" without entering an address
4. **View Specific Address**: Enter a testnet4 address (tb1p...) and click "Refresh"
5. **Check Connection**: The status indicator shows Bitcoin Core connection status
6. **Browse NFTs**: NFT cards show ticker, remaining supply, and UTXO details
7. **Browse Tokens**: Token cards display token amounts and addresses

## API Endpoints

The server provides the following REST API endpoints:

### Status & Info
- `GET /status` - Bitcoin Core connection status and blockchain info
- `GET /health` - Server health check
- `GET /wallet` - Wallet information
- `GET /balance` - Wallet balance

### UTXOs & Addresses
- `GET /address` - Get current wallet receiving address
- `GET /addresses` - List all wallet addresses
- `GET /utxos` - List all wallet UTXOs with charm data
- `GET /utxos/:address` - List UTXOs for a specific address

### Transactions
- `GET /transactions` - Recent transactions (default: 10)
- `GET /transaction/:txid` - Full transaction details
- `GET /charm/:txid/:vout` - Charm data for specific UTXO

## How It Works

### Backend (server.js)

The Node.js server:
1. Connects to Bitcoin Core via RPC (`bitcoin-cli`)
2. Fetches UTXOs from the wallet
3. Parses transactions to identify NFT and token UTXOs
4. Serves the REST API for the frontend
5. Provides real-time blockchain status

### Frontend (index.html)

The web interface:
1. Polls the server for UTXO data
2. Displays NFTs, tokens, and plain UTXOs in separate sections
3. Shows real-time connection status
4. Provides address filtering
5. Auto-refreshes data

### NFT/Token Detection

The system identifies NFT and token UTXOs by:
1. Checking for Taproot outputs (witness_v1_taproot)
2. Matching known NFT/token addresses
3. Parsing transaction witness data (future enhancement)

**Note**: Full charm data parsing requires integration with the Charms SDK. The current implementation uses address patterns for demonstration.

## Known Addresses (From Your Example)

The viewer recognizes these addresses from your minting operation:

- **NFT Address**: `tb1p40c5eywchazxa4t3jdytnc39c3g8l2tzegzk7zgrzcdm324xce3qww4eud`
  - Ticker: MY-TOKEN
  - Remaining: 30,580

- **Token Address**: `tb1px6jrge3dynx9tjp6vwp7xrq9a3gm9dqpz9jts4jezhvlulayvrqq9rcrz3`
  - Ticker: MY-TOKEN
  - Amount: 69,420 tokens

## Enhancing Charm Detection

To improve NFT/token detection, you can enhance the `parseUtxoWithTransaction` function in [server.js](server.js) to:

1. **Parse Taproot Witness Data**: Extract charm data from witness scripts
2. **Integrate Charms SDK**: Use the SDK to decode charm structures
3. **Query App Contracts**: Verify UTXOs against app verification keys
4. **Cache Results**: Store parsed charm data for faster loading

Example enhancement:
```javascript
// In parseUtxoWithTransaction function
const charmData = await parseCharmFromWitness(tx, vout);
if (charmData) {
    result.type = charmData.type; // 'nft' or 'token'
    result.ticker = charmData.ticker;
    result.remaining = charmData.remaining;
    result.tokenAmount = charmData.amount;
}
```

## Troubleshooting

### Server won't start
- Check if Node.js is installed: `node --version`
- Ensure dependencies are installed: `npm install`
- Check if port 3000 is available

### Cannot connect to Bitcoin Core
- Verify Bitcoin Core is running: `bitcoin-cli -testnet4 getblockchaininfo`
- Check wallet is loaded: `bitcoin-cli -testnet4 listwallets`
- Load wallet if needed: `bitcoin-cli -testnet4 loadwallet "nftcharm_wallet"`

### No UTXOs shown
- Ensure the wallet has UTXOs: `bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" listunspent`
- Check if addresses have been used in the wallet
- Try refreshing without an address to see all wallet UTXOs

### NFTs/Tokens not detected
- The current implementation uses hardcoded address patterns
- Enhance the parser to integrate with Charms SDK for automatic detection
- Check transaction details manually using the `/transaction/:txid` endpoint

## Security Notes

- This is a **development tool** for testnet4 only
- Never use on mainnet without proper security review
- The server runs locally and is not production-ready
- Add authentication/authorization for production use
- Enable HTTPS for production deployments

## Future Enhancements

- [ ] Integrate Charms SDK for automatic charm parsing
- [ ] Add transaction building and sending
- [ ] Support for multiple wallets
- [ ] Token transfer interface
- [ ] NFT minting interface
- [ ] Transaction history with charm annotations
- [ ] Export UTXO data to CSV/JSON
- [ ] WebSocket support for real-time updates
- [ ] Dark mode toggle
- [ ] Mobile-responsive improvements

## Related Files

- [create-nft.sh](../create-nft.sh) - Script to create new NFTs
- [mint-tokens.sh](../mint-tokens.sh) - Script to mint tokens
- [transfer-tokens.sh](../transfer-tokens.sh) - Script to transfer tokens
- [PROOF_NFT_TRANSFERS.md](../docs/PROOF_NFT_TRANSFERS.md) - NFT transfer documentation

## Example Usage

After starting the server and opening the GUI:

1. **View your recent NFT minting**:
   - The NFT UTXO from your example will appear with:
     - Ticker: MY-TOKEN
     - Remaining: 30,580
     - UTXO: `b8471ec2c860a12e78a97409e8c43e5498456799a379e86f61af63c7a766044d:0`

2. **View your minted tokens**:
   - Token UTXO will show:
     - Ticker: MY-TOKEN
     - Amount: 69,420 tokens
     - UTXO: `d6e5f0212be34134ae51e0a595aa573e68a948f79d634175430888183bdf92c5:0`

3. **Filter by address**:
   - Enter `tb1px6jrge3dynx9tjp6vwp7xrq9a3gm9dqpz9jts4jezhvlulayvrqq9rcrz3`
   - See only the token UTXO

## License

MIT

## Contributing

Contributions are welcome! Please ensure:
- Code follows existing style
- API endpoints are documented
- Error handling is comprehensive
- Security best practices are followed
