# User Stories for BOS Discord Bot

**Project:** CHARMS Token Airdrop & Bitcoin Testnet Wallet Bot
**Platform:** Discord
**Network:** Bitcoin Testnet4
**Date:** 2025-12-28

---

## Table of Contents

1. [User Personas](#user-personas)
2. [User Stories by Persona](#user-stories-by-persona)
   - [New User (First-Time Participant)](#1-new-user-first-time-participant)
   - [Active Token Holder](#2-active-token-holder-regular-user)
   - [Bitcoin Transaction User](#3-bitcoin-transaction-user)
   - [Technical User / Developer](#4-technical-user--developer)
   - [Token Developer / Advanced User](#5-token-developer--advanced-user)
3. [Error Handling Stories](#error-handling-stories)
4. [Technical Implementation Stories](#technical-implementation-stories)
5. [User Flow Examples](#user-flow-examples)
6. [Summary Statistics](#summary-statistics)

---

## User Personas

### 👤 New User
Discord members joining the CHARMS airdrop for the first time, need guidance on getting started.

### 💰 Active Token Holder
Regular participants who manage their token balance and monitor their mining statistics.

### 🔄 Bitcoin Transaction User
Users who actively send and receive Bitcoin on testnet4 for testing or participation.

### 👨‍💻 Technical User / Developer
Developers learning Bitcoin transaction structures, data types, and blockchain analysis.

### 🔬 Token Developer / Advanced User
Advanced users working with token protocols and UTXO-based token standards.

---

## User Stories by Persona

## 1. New User (First-Time Participant)

### Epic: Getting Started with CHARMS Airdrop

#### US-001: Join the Airdrop

**As a** Discord server member
**I want to** join the CHARMS token airdrop
**So that** I can start earning tokens and participate in the community

**Command:** `/airdrop-start`

**Acceptance Criteria:**
- ✅ User runs `/airdrop-start` command
- ✅ Bot creates a Bitcoin testnet4 wallet for the user
- ✅ User receives welcome message with their wallet address
- ✅ User sees next steps to check balance
- ✅ User is informed about seed phrase security
- ✅ If wallet already exists, returns existing wallet

**Example Output:**
```
🎉 **Welcome to the CHARMS Airdrop!**

✅ Your wallet has been created!
📍 **Address:** `tb1q...`

**Next Steps:**
1️⃣ Use `/airdrop-balance` to check your balance

⚠️ **Keep your seed phrase safe!** Use `/airdrop-wallet` to view it privately.
```

---

#### US-002: View Wallet Credentials Securely

**As a** new participant
**I want to** view my wallet credentials securely
**So that** I can safely store my seed phrase and address

**Command:** `/airdrop-wallet`

**Acceptance Criteria:**
- ✅ User runs `/airdrop-wallet` command
- ✅ Bot sends ephemeral (private) message visible only to user
- ✅ Seed phrase is hidden with spoiler tags `||...||`
- ✅ Bitcoin balance (confirmed/unconfirmed/total) is displayed
- ✅ Security warning is shown about not sharing seed phrase
- ✅ Error message if wallet doesn't exist

**Example Output (Ephemeral):**
```
🔐 **Your Wallet Information**

**Address:** `tb1q...`
**Seed Phrase:** ||`word1 word2 word3 ... word12`||

**Bitcoin Balance (Testnet4):**
• Confirmed: `0.00100000` BTC
• Unconfirmed: `0.00000000` BTC
• Total: `0.00100000` BTC

⚠️ **NEVER share your seed phrase with anyone!**
```

---

## 2. Active Token Holder (Regular User)

### Epic: Managing Token Balance and Wallet

#### US-003: Check CHARMS Token Balance

**As a** token holder
**I want to** check my CHARMS token balance
**So that** I can track my earnings and progress

**Command:** `/airdrop-balance`

**Acceptance Criteria:**
- ✅ User runs `/airdrop-balance` command
- ✅ Bot displays current CHARMS balance
- ✅ Statistics shown: total mined, total claims, mining sessions, best zero bits
- ✅ All balances formatted to 2 decimal places
- ✅ Error message shown if no wallet exists

**Example Output:**
```
💰 **Your Token Balance**

**Balance:** `1234.56` CHARMS

📊 **Statistics:**
• Total Mined: `1234.56` CHARMS
• Total Claims: `5`
• Mining Sessions: `10`
• Best Zero Bits: `12`
```

---

#### US-004: View Bitcoin Balance

**As a** wallet owner
**I want to** view my Bitcoin balance on testnet4
**So that** I can see how much BTC I have available for transactions

**Command:** `/airdrop-wallet`

**Acceptance Criteria:**
- ✅ User runs `/airdrop-wallet` command
- ✅ Bot fetches balance from mempool.space testnet4 API
- ✅ Displays confirmed, unconfirmed, and total BTC balances
- ✅ Shows balance in BTC (8 decimal places), not satoshis
- ✅ Gracefully handles API failures with fallback message

**Technical Details:**
- API Endpoint: `https://mempool.space/testnet4/api/address/{address}`
- Balance calculation: `(funded_txo_sum - spent_txo_sum) / 100000000`

---

## 3. Bitcoin Transaction User

### Epic: Sending Bitcoin on Testnet

#### US-005: Send Transaction to Self

**As a** wallet owner
**I want to** send a transaction to myself
**So that** I can test the wallet functionality without losing funds

**Command:** `/airdrop-myself`

**Acceptance Criteria:**
- ✅ User runs `/airdrop-myself` command
- ✅ Bot creates transaction from user's address to same address
- ✅ Transaction includes proper fee calculation (3 sat/vB, minimum 500 sats)
- ✅ Bot displays transaction ID and mempool explorer link
- ✅ Error shown if insufficient UTXOs or balance
- ✅ Progress indicator shown during transaction creation

**Example Output:**
```
✅ **Transaction Sent Successfully!**

📍 **From:** `tb1q...`
📍 **To:** `tb1q...`
🔗 **Transaction ID:** `d8786af1...`

🌐 **View on Explorer:**
https://mempool.space/testnet4/tx/d8786af1...

⏳ The transaction has been broadcast to the Bitcoin testnet4 network.
```

**Error Scenarios:**
- No UTXOs: "No UTXOs available. You need to fund your wallet first."
- UTXO too small: "UTXO value too small to cover fees"
- Broadcast failure: "Failed to broadcast transaction: {error details}"

---

#### US-006: Send Bitcoin with Default Recipient

**As a** wallet owner
**I want to** send Bitcoin to another address with a default recipient
**So that** I can quickly send funds without typing an address

**Command:** `/airdrop-send`

**Acceptance Criteria:**
- ✅ User runs `/airdrop-send` command without parameters
- ✅ Bot sends to default address: `tb1pyry0g642yr7qlhe82qd342lr0aztywhth62lnjttxgks8wmgsc9svf9xx2`
- ✅ Transaction sends maximum available minus fees
- ✅ Bot displays sender, recipient, amount (in sats and BTC), fee, and txid
- ✅ Explorer link provided to mempool.space
- ✅ Change output created if >= 546 sats remain

**Example Output:**
```
✅ **Transaction Sent Successfully!**

📍 **From:** `tb1q...`
📍 **To:** `tb1pyry0g642yr7qlhe82qd342lr0aztywhth62lnjttxgks8wmgsc9svf9xx2`
💰 **Amount:** `100000` satoshis (0.00100000 BTC)
⚡ **Fee:** `500` satoshis
🔗 **Transaction ID:** `abc123...`

🌐 **View on Explorer:**
https://mempool.space/testnet4/tx/abc123...

⏳ The transaction has been broadcast to the Bitcoin testnet4 network.
```

---

#### US-007: Send Specific Amount to Custom Address

**As a** wallet owner
**I want to** send a specific amount of Bitcoin to a custom address
**So that** I can control exactly how much I send

**Command:** `/airdrop-send address:<address> amount:<satoshis>`

**Acceptance Criteria:**
- ✅ User specifies custom recipient address
- ✅ User specifies amount in satoshis
- ✅ Bot validates recipient address for testnet
- ✅ Bot validates amount is at least 546 satoshis (dust limit)
- ✅ Bot checks sufficient balance (amount + fee)
- ✅ Transaction broadcast with confirmation details
- ✅ Change returned to sender if applicable

**Validation Rules:**
- Minimum amount: 546 satoshis (dust limit)
- Address must be valid Bitcoin testnet address
- Total balance must cover amount + estimated fee

**Example Command:**
```
/airdrop-send address:tb1q9x8y7z6... amount:10000
```

---

#### US-008: Use Bitcoin CLI Style Command

**As a** Bitcoin user familiar with CLI tools
**I want to** use a bitcoin-cli style command
**So that** I can send transactions using familiar syntax

**Command:** `/sendto address:<address> [amount:<satoshis>]`

**Acceptance Criteria:**
- ✅ User runs `/sendto address:<address>` (required parameter)
- ✅ Optionally add `amount:<satoshis>`
- ✅ Command behaves identically to `/airdrop-send`
- ✅ Error shown if address parameter missing
- ✅ If amount omitted, sends maximum (all UTXOs minus fees)

**Example Commands:**
```
/sendto address:tb1q9x8y7z6...
/sendto address:tb1q9x8y7z6... amount:50000
```

**Error Message (Missing Address):**
```
❌ Recipient address is required.
Usage: `/sendto address:<address> [amount:<satoshis>]`
```

---

## 4. Technical User / Developer

### Epic: Understanding Bitcoin Technical Details

#### US-009: Learn Bitcoin Data Structures

**As a** developer learning Bitcoin
**I want to** see Bitcoin data structure definitions
**So that** I can understand transaction components and types

**Command:** `/btc-info`

**Acceptance Criteria:**
- ✅ User runs `/btc-info` command
- ✅ Bot displays organized information about Bitcoin data structures
- ✅ Covers: Core types, Script types, Transaction components, Advanced types
- ✅ User's wallet address and network shown at bottom
- ✅ Information is educational and well-formatted

**Example Output:**
```
🔧 **Bitcoin Technical Data Structures**

**Core Types:**
• **Address**: Bitcoin address for receiving/sending
• **Amount**: Value in satoshis (1 BTC = 100,000,000 sats)
• **FeeRate**: Transaction fee per virtual byte (sat/vB)
• **Network**: Bitcoin network (mainnet/testnet/regtest)

**Script & Signature Types:**
• **ScriptBuf**: Script containing spending conditions
• **TapLeafHash**: Hash of a Taproot script leaf
• **TapSighashType**: Taproot signature hash type
• **XOnlyPublicKey**: 32-byte x-only public key for Taproot

**Transaction Components:**
• **Transaction**: Complete Bitcoin transaction
• **TxIn**: Transaction input (spending previous output)
• **TxOut**: Transaction output (receiving address + amount)
• **Txid**: Transaction identifier (32-byte hash)

**Advanced Types:**
• **OutPoint**: Reference to a specific output (txid + index)
• **Witness**: Segregated witness data for SegWit txs
• **Weight**: Transaction weight units (max 400,000)

📍 **Your Address:** `tb1q...`
🌐 **Network:** Bitcoin Testnet4
```

---

#### US-010: View Transaction History

**As a** blockchain analyst
**I want to** view my transaction history
**So that** I can track all activity on my wallet

**Command:** `/transactions [limit:<1-20>]`

**Acceptance Criteria:**
- ✅ User runs `/transactions` with optional limit (1-20, default 5)
- ✅ Bot displays last N transactions for user's address
- ✅ Each transaction shows: confirmation status, block height, txid, value change, fee, size
- ✅ Explorer link provided for each transaction
- ✅ Message shown if no transactions exist
- ✅ Transactions sorted by most recent first

**Example Output:**
```
📋 **Last 3 Transactions**

📍 **Address:** `tb1q...`

1. **✅ Confirmed (Block: 1234567)**
   🔗 TXID: `abc123...`
   💰 Value Change: +0.00100000 BTC
   ⚡ Fee: 500 sats
   📦 Size: 141 bytes
   🌐 https://mempool.space/testnet4/tx/abc123...

2. **⏳ Unconfirmed**
   🔗 TXID: `def456...`
   💰 Value Change: -0.00050000 BTC
   ⚡ Fee: 300 sats
   📦 Size: 168 bytes
   🌐 https://mempool.space/testnet4/tx/def456...

3. **✅ Confirmed (Block: 1234560)**
   🔗 TXID: `ghi789...`
   💰 Value Change: +0.00200000 BTC
   ⚡ Fee: 450 sats
   📦 Size: 141 bytes
   🌐 https://mempool.space/testnet4/tx/ghi789...
```

**Empty State:**
```
📋 **Transaction History**

📍 **Address:** `tb1q...`

❌ No transactions found for this address.
```

---

#### US-011: Analyze Raw Transaction Data

**As a** blockchain researcher
**I want to** view raw transaction data
**So that** I can analyze transaction structure and token standard spells

**Command:** `/tx-raw [txid:<transaction_id>]`

**Acceptance Criteria:**
- ✅ User runs `/tx-raw` with optional txid
- ✅ Uses default example txid if not provided: `d8786af1e7e597d77c073905fd6fd7053e4d12894eefa19c5deb45842fc2a8a2`
- ✅ Bot displays raw hex data (truncated if > 500 chars)
- ✅ Shows transaction size, weight, and fee
- ✅ Lists all inputs with: previous txid, vout, sequence, scriptSig, witness data
- ✅ Lists all outputs with: value, address, scriptPubKey, OP_RETURN data
- ✅ Parses and displays charms.dev Token Standard spell as formatted JSON
- ✅ Shows status information: confirmed, block height, block hash, timestamp
- ✅ Searches both OP_RETURN and witness data for spell

**Example Output:**
```
📋 **Transaction Raw Data**

**Transaction ID:** `d8786af1...`
**Size:** `250` bytes
**Weight:** `1000`
**Fee:** `500` satoshis

**Status:**
• Confirmed: ✅ Yes
• Block Height: `1234567`
• Block Hash: `00000000...`
• Block Time: `2025-12-28T10:30:00.000Z`

**Raw Hex:**
```
0200000001a1b2c3d4e5f6...
```

**Inputs (1):**

**Input 1:**
• Previous TXID: `a1b2c3d4...`
• Vout: `0`
• Sequence: `4294967295`
• Witness: 2 item(s)
  - Witness[0]: `304402...` (72 bytes)
  - Witness[1]: `03ab12...` (33 bytes)

**Outputs (2):**

**Output 1:**
• Value: `100000` satoshis (0.00100000 BTC)
• Address: `tb1q...`
• ScriptPubKey: `0014ab12cd34...`

**Output 2:**
• Value: `0` satoshis (0.00000000 BTC)
• OP_RETURN: `{"version": "1.0", "apps": [...], ...}`
• ScriptPubKey: `6a4c50...`

🔮 **Charms.dev Token Standard Spell:**
```json
{
  "version": "1.0",
  "apps": [...],
  "ins": [...],
  "outs": [...]
}
```

🌐 **View on Explorer:**
https://mempool.space/testnet4/tx/d8786af1...
```

**Spell Not Found:**
```
🔮 **Charms.dev Token Standard Spell:**
❌ No spell found in transaction (checked OP_RETURN and witness data)
```

---

## 5. Token Developer / Advanced User

### Epic: Querying Token Information

#### US-012: Query Token UTXO Information

**As a** token protocol developer
**I want to** query token UTXO information
**So that** I can verify app identity and token state

**Command:** `/query-tokens [app_id:<id>] [app_vk:<key>] [token_utxo:<txid:vout>] [witness_utxo:<txid:vout>]`

**Acceptance Criteria:**
- ✅ User runs `/query-tokens` with optional parameters
- ✅ Bot uses default values if parameters not provided:
  - app_id: `2ed3939eceafa9cdd5495e224c64f20b17e517bb7629153f1d5b5b0e3e87d2f5`
  - app_vk: `175affa66db36da14c819c6e7396e5bc21d5315a878b4f6800f980e646c9e649`
  - token_utxo: `d8786af1e7e597d77c073905fd6fd7053e4d12894eefa19c5deb45842fc2a8a2:0`
  - witness_utxo: `f62d75e7c52c1929c63033b797947d8af0f4e720cc5d67be5198e24491818941:0`
- ✅ Bot fetches transaction data from mempool for both UTXOs
- ✅ Displays app identity and verification key
- ✅ Shows token UTXO transaction details (status, size, weight)
- ✅ Shows witness UTXO transaction details
- ✅ Provides explorer links for both transactions
- ✅ UTXO format validated as `txid:vout`

**Example Output:**
```
🔍 **Token Query Results**

**App Identity:**
• App ID: `2ed3939e...`
• App Verification Key: `175affa6...`

**Token UTXO Transaction:**
• TXID: `d8786af1...`
• Vout: `0`
• Status: ✅ Confirmed
• Size: `250` bytes
• Weight: `1000`

**Witness UTXO Transaction:**
• TXID: `f62d75e7...`
• Vout: `0`
• Status: ✅ Confirmed
• Size: `300` bytes
• Weight: `1200`

**UTXO References:**
• Token UTXO: `d8786af1e7e597d77c073905fd6fd7053e4d12894eefa19c5deb45842fc2a8a2:0`
• Witness UTXO: `f62d75e7c52c1929c63033b797947d8af0f4e720cc5d67be5198e24491818941:0`

🌐 **View on Explorer:**
• Token TX: https://mempool.space/testnet4/tx/d8786af1...
• Witness TX: https://mempool.space/testnet4/tx/f62d75e7...
```

---

## Error Handling Stories

### US-E01: No Wallet Error

**As a** user without a wallet
**I want to** receive helpful error messages
**So that** I know how to proceed

**Affected Commands:**
- `/airdrop-wallet`
- `/airdrop-balance`
- `/btc-info`
- `/airdrop-myself`
- `/airdrop-send`
- `/sendto`
- `/transactions`

**Error Message:**
```
❌ You don't have a wallet yet! Use `/airdrop-start` to create one.
```

---

### US-E02: Insufficient Balance Errors

**As a** user with insufficient balance
**I want to** understand why my transaction failed
**So that** I can take appropriate action

**Scenarios:**

1. **No UTXOs Available:**
```
❌ **Transaction Failed**

No UTXOs available. You need to fund your wallet first.
```

2. **Balance Too Low:**
```
❌ **Transaction Failed**

Insufficient balance. Available: 50000 sats, Requested: 100000 sats + 500 sats fee
```

3. **UTXO Too Small for Fees:**
```
❌ **Transaction Failed**

UTXO value too small to cover fees
```

4. **Amount Below Dust Limit:**
```
❌ **Transaction Failed**

Amount must be at least 546 satoshis (dust limit)
```

5. **Balance Too Low After Fees:**
```
❌ **Transaction Failed**

Balance too low to send transaction after fees
```

---

### US-E03: Progress Indicators

**As a** user
**I want to** see progress indicators for slow operations
**So that** I know the bot is working

**Progress Messages:**

1. **Transaction Creation:**
```
🔄 **Creating Transaction...**

Fetching UTXOs and building transaction...
```

2. **Token Query:**
```
🔄 **Querying Token Information...**

Fetching token data from blockchain...
```

3. **Transaction History:**
```
🔄 **Fetching Transactions...**

Retrieving last 5 transactions for your address...
```

4. **Raw Transaction Data:**
```
🔄 **Fetching Transaction Raw Data...**

Retrieving transaction details and parsing charms.dev Token Standard...
```

---

### US-E04: Invalid Address Error

**As a** user entering an incorrect address
**I want to** be notified that the address is invalid
**So that** I can correct it

**Error Message:**
```
❌ **Transaction Failed**

Invalid recipient address for testnet
```

---

### US-E05: Broadcast Failure Error

**As a** user whose transaction failed to broadcast
**I want to** see the specific error from the network
**So that** I can understand what went wrong

**Error Message:**
```
❌ **Transaction Failed**

Failed to broadcast transaction: {error details from mempool API}
```

**Common Broadcast Errors:**
- "min relay fee not met"
- "bad-txns-inputs-missingorspent"
- "insufficient priority"

---

### US-E06: API Failure Handling

**As a** user
**I want to** see graceful error handling when external APIs fail
**So that** I understand the service is temporarily unavailable

**Scenarios:**

1. **Balance Fetch Failure:**
```
**Bitcoin Balance:** Unable to fetch
```

2. **Transaction Query Failure:**
```
❌ **Failed to Fetch Transactions**

Failed to fetch Bitcoin balance from mempool
```

3. **Raw Data Fetch Failure:**
```
❌ **Failed to Fetch Transaction Raw Data**

Failed to fetch transaction hex: 404 Not Found
```

---

## Technical Implementation Stories

### TS-001: Wallet Architecture

**As the** system
**The bot** uses a shared default wallet for all users
**Because** this is a testnet demonstration environment

**Implementation Details:**
- All users share same Bitcoin testnet4 address
- Seed phrase from `DEFAULT_SEED_PHRASE` environment variable
- BIP39 mnemonic → BIP32 derivation → BIP84 native SegWit (P2WPKH)
- Derivation path: `m/84'/1'/0'/0/0` (testnet)
- Private key stored in hex format for transaction signing
- Wallet initialization happens at bot startup

**Technical Stack:**
- `bip39`: Mnemonic generation and validation
- `bip32`: Hierarchical deterministic key derivation
- `bitcoinjs-lib`: Bitcoin transaction creation
- `ecpair`: Elliptic curve key pair operations
- `tiny-secp256k1`: Low-level cryptographic primitives

**Code Reference:**
- [wallet.ts:69-84](src/wallet.ts#L69-L84) - `initializeDefaultWallet()`
- [wallet.ts:86-116](src/wallet.ts#L86-L116) - `generateKeysFromSeed()`

---

### TS-002: Transaction Broadcasting

**As the** system
**The bot** constructs and broadcasts Bitcoin transactions
**Using** mempool.space testnet4 API

**Implementation Details:**

**UTXO Fetching:**
- Endpoint: `https://mempool.space/testnet4/api/address/{address}/utxo`
- Returns: Array of unspent outputs with txid, vout, value, status

**Transaction Construction:**
- Uses PSBT (Partially Signed Bitcoin Transaction) format
- P2WPKH (Pay to Witness Public Key Hash) inputs
- Witness data for SegWit transactions
- Fee calculation: 3 sat/vB with minimum 500 satoshis
- Change output created only if >= 546 sats (dust limit)

**Transaction Broadcasting:**
- Endpoint: `https://mempool.space/testnet4/api/tx` (POST)
- Body: Raw transaction hex
- Returns: Transaction ID (txid)

**Fee Estimation Formula:**
```
estimatedSize = baseSize + (numInputs * inputSize) + (numOutputs * outputSize)
estimatedSize = 10 + (utxos.length * 68) + (2 * 31)
estimatedFee = max(estimatedSize * feeRate, 500)
```

**Size Parameters:**
- Base transaction: 10 vB
- P2WPKH input: 68 vB (includes witness data)
- P2WPKH output: 31 vB

**Code Reference:**
- [wallet.ts:196-298](src/wallet.ts#L196-L298) - `createSelfTransaction()`
- [wallet.ts:300-473](src/wallet.ts#L300-L473) - `createTransaction()`

---

### TS-003: Token Standard Integration

**As the** system
**The bot** parses charms.dev Token Standard spells
**From** Bitcoin transaction data

**Implementation Details:**

**Spell Search Locations:**
1. OP_RETURN outputs (script starting with 0x6a)
2. Witness data in transaction inputs

**Parsing Strategy:**
1. Extract hex data from OP_RETURN or witness
2. Convert to UTF-8 string
3. Check if starts with `{` (JSON)
4. Validate contains token standard fields: "version", "apps", "ins", "outs"
5. Parse as JSON

**Spell Structure Example:**
```json
{
  "version": "1.0",
  "apps": [...],
  "ins": [...],
  "outs": [...]
}
```

**Code Reference:**
- [wallet.ts:678-712](src/wallet.ts#L678-L712) - Spell parsing logic in `getTransactionRawData()`

---

### TS-004: Database Management

**As the** system
**The bot** stores user data in memory
**Using** DatabaseManager singleton

**Data Stored:**
- User wallets (address, seed phrase, private key, creation date)
- Token balances (CHARMS tokens)
- Mining statistics (total mined, claims, sessions, best zero bits)
- Claim history (amount, timestamp, transaction ID)
- Leaderboard rankings

**Key Methods:**
- `saveWallet()` - Store user wallet
- `getWallet()` - Retrieve user wallet
- `getBalance()` - Get CHARMS token balance
- `addTokens()` - Add tokens to balance
- `getUserStats()` - Get mining and claim statistics
- `getLeaderboard()` - Get top users by balance
- `recordClaim()` - Record token claim event

**Note:** Data is stored in-memory and will be lost on bot restart.

**Code Reference:**
- [database.ts](src/database.ts) - DatabaseManager implementation

---

### TS-005: Mining System

**As the** system
**The bot** implements proof-of-work mining
**To** reward users with CHARMS tokens

**Implementation Details:**

**Mining Algorithm:**
1. Hash input: `userId:nonce:timestamp`
2. Use SHA-256 hash function
3. Count leading zero bits in hash
4. Find hash with maximum leading zero bits within time limit
5. Calculate reward based on zero bits found

**Reward Formula:**
```
reward = (baseReward * zeroBits²) / 2^hashDifficulty
baseReward = 1,000,000
hashDifficulty = 12
minimumReward = 10
```

**Example:**
- 8 zero bits: (1000000 * 64) / 4096 = 15,625 CHARMS
- 12 zero bits: (1000000 * 144) / 4096 = 35,156 CHARMS

**Leading Zero Bits Counting:**
- Iterate through hex characters
- Count consecutive 0 characters (each = 4 bits)
- For non-zero hex, count leading zero bits within nibble

**Code Reference:**
- [mining.ts:18-58](src/mining.ts#L18-L58) - `mine()` method
- [mining.ts:60-80](src/mining.ts#L60-L80) - `countLeadingZeroBits()`
- [mining.ts:82-92](src/mining.ts#L82-L92) - `calculateReward()`

---

### TS-006: Command Registration

**As the** system
**The bot** registers slash commands with Discord
**On** bot startup

**Implementation Details:**

**Command Registration Process:**
1. Define commands using SlashCommandBuilder
2. Set command name, description, and options
3. Convert to JSON format
4. Register globally via Discord REST API
5. Commands available to all servers with bot

**Registration Endpoint:**
```
PUT /applications/{applicationId}/commands
```

**Command Types:**
- Simple commands (no parameters)
- Commands with optional string parameters
- Commands with optional integer parameters (with min/max values)
- Commands with required parameters

**Code Reference:**
- [index.ts:19-120](src/index.ts#L19-L120) - Command definitions
- [index.ts:125-141](src/index.ts#L125-L141) - Command registration in `clientReady` event

---

### TS-007: Error Handling Pattern

**As the** system
**The bot** implements consistent error handling
**Across** all commands

**Implementation Pattern:**
```typescript
try {
  await interaction.deferReply({ ephemeral: false })

  // Command logic here

  await interaction.editReply({
    content: // Success message
  })
} catch (error) {
  const errorMessage = error instanceof Error ? error.message : "Unknown error occurred"

  if (interaction.deferred) {
    await interaction.editReply({
      content: `❌ **Error:** ${errorMessage}`
    })
  } else {
    await interaction.reply({
      content: `❌ **Error:** ${errorMessage}`,
      ephemeral: true
    })
  }
}
```

**Error Message Format:**
- Always prefixed with ❌
- Uses bold for "Error" label
- Includes specific error message from exception
- Falls back to generic message if error type unknown

**Code Reference:**
- [index.ts:607-622](src/index.ts#L607-L622) - Global error handler

---

## User Flow Examples

### Flow 1: Complete Onboarding Flow

**Persona:** New User

**Scenario:** User joins Discord server and gets started with the airdrop

**Steps:**

1. User joins Discord server with BOS bot
2. User runs `/airdrop-start`
   - Bot creates wallet
   - Shows wallet address
   - Prompts to check balance and view seed phrase
3. User runs `/airdrop-wallet` to see seed phrase privately
   - Ephemeral message displays address and seed phrase
   - User copies and stores seed phrase securely
4. User runs `/airdrop-balance` to check CHARMS tokens
   - Shows 0 balance (just started)
   - Shows 0 mining sessions
5. User visits Bitcoin testnet faucet (external)
   - Sends testnet Bitcoin to their address
6. User runs `/transactions` to verify funding received
   - Sees incoming transaction with value
   - Transaction may be unconfirmed initially
7. User runs `/airdrop-send` to test sending Bitcoin
   - Sends to default address
   - Sees transaction broadcast successfully
8. User runs `/tx-raw` to inspect transaction details
   - Views raw hex, inputs, outputs
   - Examines transaction structure

**Duration:** 10-15 minutes
**Prerequisites:** Discord account, basic crypto knowledge
**Outcome:** User has funded wallet and understands basic operations

---

### Flow 2: Developer Research Flow

**Persona:** Technical User / Developer

**Scenario:** Developer wants to learn Bitcoin transaction structure and token standards

**Steps:**

1. Developer runs `/btc-info` to learn Bitcoin types
   - Reviews core types (Address, Amount, FeeRate)
   - Learns about script types (ScriptBuf, TapLeafHash)
   - Understands transaction components (TxIn, TxOut, Txid)
2. Developer runs `/query-tokens` to see token UTXO example
   - Examines default app identity and verification key
   - Views token UTXO and witness UTXO references
   - Clicks explorer links to see transactions on blockchain
3. Developer runs `/tx-raw` with specific txid to analyze spell structure
   - Examines raw transaction hex
   - Reviews inputs with witness data
   - Analyzes outputs with OP_RETURN
   - Sees parsed charms.dev Token Standard spell JSON
4. Developer uses explorer links to cross-reference data
   - Compares bot output with blockchain explorer
   - Validates spell parsing accuracy
5. Developer examines witness data and OP_RETURN parsing
   - Understands where spell data is embedded
   - Learns how to extract and parse spell JSON

**Duration:** 30-60 minutes
**Prerequisites:** Bitcoin development knowledge, JSON familiarity
**Outcome:** Developer understands transaction structure and token standard implementation

---

### Flow 3: Active Transaction Flow

**Persona:** Bitcoin Transaction User

**Scenario:** User wants to send Bitcoin to specific address with specific amount

**Steps:**

1. User runs `/airdrop-balance` to check if they have funds
   - Confirms CHARMS balance (informational)
2. User runs `/airdrop-wallet` to check Bitcoin balance
   - Sees confirmed balance: 0.00500000 BTC
   - Confirms sufficient funds for transaction
3. User decides to send 0.001 BTC (100,000 sats) to friend
4. User runs `/sendto address:tb1q... amount:100000`
   - Bot shows progress indicator
   - Fetches UTXOs from mempool
   - Builds transaction with proper fee
   - Signs and broadcasts transaction
5. User receives confirmation with:
   - From/To addresses
   - Sent amount and fee
   - Transaction ID
   - Explorer link
6. User clicks explorer link to watch confirmation
   - Sees transaction in mempool
   - Waits for confirmation
7. User runs `/transactions` later to verify
   - Sees sent transaction in history
   - Shows confirmed status with block height

**Duration:** 5-10 minutes
**Prerequisites:** Funded wallet, recipient address
**Outcome:** Successfully sent Bitcoin transaction

---

### Flow 4: Token Developer Flow

**Persona:** Token Developer / Advanced User

**Scenario:** Developer wants to inspect token UTXO chain and verify app identity

**Steps:**

1. Developer has token UTXO information from off-chain system
   - Token UTXO: `abc123...:0`
   - Witness UTXO: `def456...:1`
   - App ID: `2ed3939e...`
2. Developer runs `/query-tokens` with custom parameters:
   ```
   /query-tokens
     app_id:2ed3939e...
     token_utxo:abc123...:0
     witness_utxo:def456...:1
   ```
3. Bot fetches both transactions from mempool
4. Developer receives:
   - App identity confirmation
   - Token UTXO transaction details (size, weight, status)
   - Witness UTXO transaction details
   - Explorer links to both transactions
5. Developer clicks token UTXO explorer link
6. Developer runs `/tx-raw txid:abc123...` to see full transaction
   - Examines spell in OP_RETURN or witness
   - Validates spell structure matches expectations
   - Verifies app identity in spell
7. Developer cross-references with witness UTXO
8. Developer confirms token state is valid

**Duration:** 15-20 minutes
**Prerequisites:** Token protocol knowledge, UTXO tracking system
**Outcome:** Verified token chain integrity and app identity

---

### Flow 5: Error Recovery Flow

**Persona:** New User (experiencing errors)

**Scenario:** User encounters errors and learns how to resolve them

**Steps:**

1. User tries to run `/airdrop-send` without creating wallet
   - Error: "❌ You don't have a wallet yet! Use `/airdrop-start` to create one."
2. User runs `/airdrop-start`
   - Wallet created successfully
3. User tries to run `/airdrop-send` again
   - Error: "No UTXOs available. You need to fund your wallet first."
4. User asks in Discord: "How do I get testnet Bitcoin?"
5. Community member provides testnet faucet link
6. User visits faucet and sends BTC to their address
7. User runs `/transactions` to check if received
   - Sees transaction still unconfirmed
8. User waits 10 minutes and checks again
   - Transaction now confirmed
9. User runs `/airdrop-send amount:100`
   - Error: "Amount must be at least 546 satoshis (dust limit)"
10. User runs `/airdrop-send amount:1000`
    - Success! Transaction broadcast

**Duration:** 30-45 minutes (including faucet wait time)
**Prerequisites:** Patience, willingness to learn
**Outcome:** User understands wallet funding and transaction requirements

---

## Summary Statistics

### Commands Overview

**Total Commands:** 11

**By Category:**

1. **Wallet Management** (3 commands)
   - `/airdrop-start` - Create wallet and join airdrop
   - `/airdrop-wallet` - View wallet credentials (ephemeral)
   - `/airdrop-balance` - Check CHARMS token balance

2. **Bitcoin Transactions** (4 commands)
   - `/airdrop-myself` - Send transaction to self
   - `/airdrop-send` - Send to address (default or custom)
   - `/sendto` - Bitcoin CLI style send command
   - `/transactions` - View transaction history

3. **Technical/Developer** (4 commands)
   - `/btc-info` - Bitcoin data structure reference
   - `/query-tokens` - Query token UTXO information
   - `/tx-raw` - View raw transaction data and spell

### User Personas

**Total Personas:** 5

1. **New User** - First-time participants
2. **Active Token Holder** - Regular balance checkers
3. **Bitcoin Transaction User** - Active senders/receivers
4. **Technical User/Developer** - Learning Bitcoin tech
5. **Token Developer/Advanced User** - Working with token protocols

### User Stories Breakdown

**Total User Stories:** 17
- Feature Stories: 12 (US-001 to US-012)
- Error Handling Stories: 6 (US-E01 to US-E06)
- Technical Implementation Stories: 7 (TS-001 to TS-007)

### Key Features

**Wallet Architecture:**
- Shared testnet wallet for all users
- BIP39 mnemonic seed phrases
- BIP32 hierarchical deterministic derivation
- BIP84 native SegWit (P2WPKH) addresses
- Path: `m/84'/1'/0'/0/0`

**Transaction Capabilities:**
- Self-transactions (testing)
- Send to custom addresses
- Send specific amounts or max
- Fee estimation (3 sat/vB, min 500 sats)
- Change output handling
- Dust limit enforcement (546 sats)

**Blockchain Integration:**
- mempool.space testnet4 API
- UTXO fetching and management
- Transaction broadcasting
- Balance queries
- Transaction history
- Raw transaction data

**Token Standard:**
- charms.dev Token Standard support
- Spell parsing from OP_RETURN
- Spell parsing from witness data
- App identity and verification
- UTXO-based token tracking

**Security Features:**
- Ephemeral messages for sensitive data
- Seed phrase spoiler tags
- Private key never displayed
- Testnet-only operations
- Address validation

### Technical Stack

**Core Libraries:**
- `discord.js` v14.16.3 - Discord bot framework
- `bitcoinjs-lib` v6.1.7 - Bitcoin transaction handling
- `bip32` - HD key derivation
- `bip39` - Mnemonic generation
- `ecpair` - Elliptic curve operations
- `tiny-secp256k1` - Cryptographic primitives

**External APIs:**
- mempool.space testnet4 API
  - Address balance
  - UTXO queries
  - Transaction broadcast
  - Transaction details
  - Raw transaction hex

**Development Tools:**
- TypeScript - Type safety
- Node.js - Runtime environment
- dotenv - Environment configuration

### Success Metrics

**User Engagement:**
- Wallet creation rate
- Daily active users
- Transaction volume
- Command usage frequency

**Technical Performance:**
- Transaction broadcast success rate
- API response time
- Error rate by command
- Average transaction confirmation time

**Educational Impact:**
- Developer command usage (`/btc-info`, `/tx-raw`)
- Token query usage (`/query-tokens`)
- Transaction analysis engagement

---

## Appendix

### Command Reference Quick Table

| Command | Parameters | Description | Persona |
|---------|-----------|-------------|---------|
| `/airdrop-start` | None | Create wallet and join airdrop | New User |
| `/airdrop-wallet` | None | View wallet credentials (ephemeral) | New User |
| `/airdrop-balance` | None | Check CHARMS token balance | Token Holder |
| `/btc-info` | None | Bitcoin data structure reference | Developer |
| `/airdrop-myself` | None | Send transaction to self | TX User |
| `/airdrop-send` | `address` (opt), `amount` (opt) | Send Bitcoin with defaults | TX User |
| `/sendto` | `address` (req), `amount` (opt) | Bitcoin CLI style send | TX User |
| `/query-tokens` | `app_id` (opt), `app_vk` (opt), `token_utxo` (opt), `witness_utxo` (opt) | Query token UTXO info | Token Dev |
| `/transactions` | `limit` (opt, 1-20, default 5) | View transaction history | Developer |
| `/tx-raw` | `txid` (opt, has default) | View raw transaction data | Developer |

### Glossary

**Bitcoin Terms:**
- **Satoshi (sats):** Smallest unit of Bitcoin (0.00000001 BTC)
- **UTXO:** Unspent Transaction Output
- **P2WPKH:** Pay to Witness Public Key Hash (SegWit address)
- **Testnet4:** Bitcoin test network version 4
- **SegWit:** Segregated Witness (transaction format)
- **Dust Limit:** Minimum output value (546 sats)
- **vB:** Virtual Byte (transaction size metric)
- **PSBT:** Partially Signed Bitcoin Transaction

**Token Standard Terms:**
- **Spell:** charms.dev token standard transaction data
- **App Identity:** Unique identifier for token application
- **Witness UTXO:** Original UTXO containing app identity
- **Token UTXO:** UTXO representing token ownership

**Bot Terms:**
- **CHARMS:** Token name for this airdrop
- **Ephemeral Message:** Message visible only to command user
- **Zero Bits:** Leading zero bits in hash (mining metric)

---

**Document Version:** 1.0
**Last Updated:** 2025-12-28
**Maintainer:** Development Team
**Related Files:** [README.md](README.md), [src/index.ts](src/index.ts)
