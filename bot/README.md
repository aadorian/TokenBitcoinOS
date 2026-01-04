# Discord Charms Airdrop Bot

A TypeScript Discord bot with airdrop functionality inspired by [bro.charms.dev](https://bro.charms.dev). Features proof-of-work mining, wallet management, and token distribution.

## Features

- 🎁 **Airdrop System**: Users can mine and claim tokens through Discord
- ⛏️ **Proof-of-Work Mining**: Find hashes with maximum leading zero bits
- 💰 **Wallet Management**: Automatic wallet creation with seed phrases
- 📊 **Leaderboard**: Track top miners and compete for rewards
- 🔐 **Secure**: Private key and seed phrase management
- 📈 **Statistics**: Track mining performance and rewards

## Commands

- `/airdrop-start` - Create your wallet and start the airdrop process
- `/airdrop-wallet` - View your wallet address and seed phrase (private)
- `/airdrop-mine [duration]` - Mine tokens for specified duration (10-300 seconds)
- `/airdrop-claim` - Claim your mined tokens
- `/airdrop-balance` - Check your current token balance
- `/airdrop-leaderboard` - View the top 10 miners
- `/airdrop-stats` - View your detailed mining statistics

## Setup

### Prerequisites

- Node.js 18+ installed
- Discord Bot Token ([create one here](https://discord.com/developers/applications))

### Installation

1. Clone the repository:
```bash
git clone <your-repo-url>
cd discord-charms-airdrop-bot
```

2. Install dependencies:
```bash
npm install
```

3. Create a `.env` file:
```bash
cp .env.example .env
```

4. Add your Discord bot token to `.env`:
```
DISCORD_TOKEN=your_bot_token_here
```

5. Enable the following bot permissions in Discord Developer Portal:
   - `applications.commands` (Slash Commands)
   - `bot` scope with permissions:
     - Send Messages
     - Use Slash Commands
     - Read Message History

### Running the Bot

**Development mode:**
```bash
npm run dev
```

**Production build:**
```bash
npm run build
npm start
```

## How It Works

### 1. Wallet Creation
When users run `/airdrop-start`, the bot creates a unique wallet with:
- Bitcoin-style address
- 12-word seed phrase
- Private key (derived from seed)

### 2. Mining Process
Users mine tokens by running `/airdrop-mine`:
- The bot searches for hashes with maximum leading zero bits
- More zero bits = higher reward
- Mining runs for specified duration (10-300 seconds)
- Results are stored as pending rewards

### 3. Reward Calculation
Rewards are calculated using the formula:
```
reward = (1M * zeroBits²) / 2^12
```
This is inspired by the BRO token formula: `100M * clz² / 2^h`

### 4. Claiming Tokens
Users claim their mined tokens with `/airdrop-claim`:
- Generates a transaction ID
- Adds tokens to balance
- Records claim history

## Architecture

```
src/
├── index.ts          # Main bot file with command handlers
├── wallet.ts         # Wallet creation and management
├── mining.ts         # Proof-of-work mining logic
├── airdrop.ts        # Token claiming and distribution
└── database.ts       # In-memory data storage
```

### Key Components

- **WalletManager**: Handles wallet creation, seed phrase generation, and key derivation
- **MiningManager**: Implements PoW algorithm to find best hashes
- **AirdropManager**: Manages token claims, balances, and statistics
- **DatabaseManager**: In-memory storage for user data (can be replaced with a real database)

## Customization

### Adjust Mining Rewards
Edit the reward calculation in `src/mining.ts`:
```typescript
private calculateReward(zeroBits: number): number {
  const baseReward = 1000000; // Adjust base reward
  const hashDifficulty = 12;  // Adjust difficulty
  
  const reward = (baseReward * Math.pow(zeroBits, 2)) / Math.pow(2, hashDifficulty);
  return Math.max(reward, 10); // Minimum reward
}
```

### Add Persistent Storage
Replace the in-memory `DatabaseManager` with a real database:
- PostgreSQL with Prisma
- MongoDB with Mongoose
- SQLite for simpler setups

### Add More Features
Consider adding:
- Token transfers between users
- Daily mining limits
- Special events with bonus rewards
- Integration with actual blockchain
- NFT rewards for top miners

## Security Notes

⚠️ **Important:**
- This bot uses in-memory storage - data is lost on restart
- Seed phrases are generated for demonstration purposes
- Not connected to real blockchain
- For production use, implement proper database and security measures
- Never expose bot token or private keys

## License

MIT License - feel free to use and modify for your projects!

## Credits

Inspired by [Charms.dev](https://charms.dev) and [BRO Token](https://bro.charms.dev)
