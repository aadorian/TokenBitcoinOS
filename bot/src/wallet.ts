import * as bip39 from "bip39"
import * as bitcoin from "bitcoinjs-lib"
import { BIP32Factory } from "bip32"
import * as ecc from "tiny-secp256k1"
//ecpair package for elliptic curve cryptography operations needed for transaction signing

import { ECPairFactory } from "ecpair"
import type { DatabaseManager } from "./database"

// Initialize BIP32 factory with the ECC library
const bip32 = BIP32Factory(ecc)
const ECPair = ECPairFactory(ecc)

// Type definition for mempool.space API transaction response
interface MempoolTransaction {
  txid: string
  version?: number
  locktime?: number
  size?: number
  weight?: number
  fee?: number
  status?: {
    confirmed: boolean
    block_height?: number
    block_hash?: string
    block_time?: number
  }
  vin?: Array<{
    txid: string
    vout: number
    prevout?: {
      scriptpubkey: string
      scriptpubkey_asm?: string
      scriptpubkey_type?: string
      scriptpubkey_address?: string
      value?: number
    }
    scriptsig?: string
    scriptsig_asm?: string
    witness?: string[]
    is_coinbase?: boolean
    sequence?: number
  }>
  vout?: Array<{
    scriptpubkey: string
    scriptpubkey_asm?: string
    scriptpubkey_type?: string
    scriptpubkey_address?: string
    value?: number
  }>
}

export interface Wallet {
  userId: string
  address: string
  seedPhrase: string
  privateKey: string
  createdAt: Date
}

export class WalletManager {
  private defaultWallet: { address: string; privateKey: string } | null = null

  constructor(private db: DatabaseManager) {
    // Initialize default wallet from seed phrase
    this.initializeDefaultWallet()
  }

  private initializeDefaultWallet(): void {
    const seedPhrase = process.env.DEFAULT_SEED_PHRASE

    if (!seedPhrase) {
      throw new Error("DEFAULT_SEED_PHRASE environment variable is not set")
    }

    // Validate seed phrase
    const normalizedSeedPhrase = seedPhrase.trim().toLowerCase()
    if (!bip39.validateMnemonic(normalizedSeedPhrase)) {
      throw new Error("Invalid DEFAULT_SEED_PHRASE in environment variables")
    }

    // Generate wallet from seed phrase
    this.defaultWallet = this.generateKeysFromSeed(normalizedSeedPhrase)
  }

  private generateKeysFromSeed(seedPhrase: string): { privateKey: string; address: string } {
    // Convert mnemonic to seed
    const seed = bip39.mnemonicToSeedSync(seedPhrase)

    // Use BIP32 to derive the key
    const network = bitcoin.networks.testnet
    const root = bip32.fromSeed(seed)

    // Derive path m/84'/1'/0'/0/0 (BIP84 for native SegWit on testnet)
    const path = "m/84'/1'/0'/0/0"
    const child = root.derivePath(path)

    if (!child.privateKey) {
      throw new Error("Failed to derive private key")
    }

    // Get private key as hex
    const privateKey = Buffer.from(child.privateKey).toString("hex")

    // Create P2WPKH (native SegWit) address for testnet
    const { address: btcAddress } = bitcoin.payments.p2wpkh({
      pubkey: Buffer.from(child.publicKey),
      network: network,
    })

    if (!btcAddress) {
      throw new Error("Failed to generate address")
    }

    return { privateKey, address: btcAddress }
  }

  async getBitcoinBalance(address: string): Promise<{ confirmed: number; unconfirmed: number; total: number }> {
    try {
      // Use mempool.space API for testnet4
      const response = await fetch(`https://mempool.space/testnet4/api/address/${address}`)

      if (!response.ok) {
        throw new Error(`Failed to fetch balance: ${response.statusText}`)
      }

      const data = (await response.json()) as {
        chain_stats: { funded_txo_sum: number; spent_txo_sum: number }
        mempool_stats: { funded_txo_sum: number; spent_txo_sum: number }
      }

      // Convert satoshis to BTC
      const confirmed = (data.chain_stats.funded_txo_sum - data.chain_stats.spent_txo_sum) / 100000000
      const unconfirmed = (data.mempool_stats.funded_txo_sum - data.mempool_stats.spent_txo_sum) / 100000000
      const total = confirmed + unconfirmed

      return { confirmed, unconfirmed, total }
    } catch (error) {
      console.error("Error fetching Bitcoin balance:", error)
      throw new Error("Failed to fetch Bitcoin balance from mempool")
    }
  }

  async createWallet(userId: string, username: string): Promise<Wallet> {
    // Check if wallet already exists
    const existing = await this.db.getWallet(userId)
    if (existing) {
      return existing
    }

    if (!this.defaultWallet) {
      throw new Error("Default wallet not initialized")
    }

    // Use default address for all users
    const wallet: Wallet = {
      userId,
      address: this.defaultWallet.address,
      seedPhrase: process.env.DEFAULT_SEED_PHRASE || "default-wallet",
      privateKey: this.defaultWallet.privateKey,
      createdAt: new Date(),
    }

    await this.db.saveWallet(wallet, username)
    return wallet
  }

  async getWallet(userId: string): Promise<Wallet | null> {
    return this.db.getWallet(userId)
  }

  async importWallet(userId: string, username: string, seedPhrase: string): Promise<Wallet> {
    // Check if wallet already exists
    const existing = await this.db.getWallet(userId)
    if (existing) {
      throw new Error("You already have a wallet. Cannot import when a wallet exists.")
    }

    if (!this.defaultWallet) {
      throw new Error("Default wallet not initialized")
    }

    // Use default address for all users (import functionality disabled for shared wallet)
    const wallet: Wallet = {
      userId,
      address: this.defaultWallet.address,
      seedPhrase: process.env.DEFAULT_SEED_PHRASE || "default-wallet",
      privateKey: this.defaultWallet.privateKey,
      createdAt: new Date(),
    }

    await this.db.saveWallet(wallet, username)
    return wallet
  }

  async createSelfTransaction(userId: string): Promise<{ txid: string; rawTx: string }> {
    const wallet = await this.getWallet(userId)
    if (!wallet) {
      throw new Error("Wallet not found")
    }

    // Fetch UTXOs for the address
    const utxosResponse = await fetch(`https://mempool.space/testnet4/api/address/${wallet.address}/utxo`)
    if (!utxosResponse.ok) {
      throw new Error("Failed to fetch UTXOs")
    }

    const utxos = (await utxosResponse.json()) as Array<{
      txid: string
      vout: number
      status: { confirmed: boolean }
      value: number
    }>

    if (utxos.length === 0) {
      throw new Error("No UTXOs available. You need to fund your wallet first.")
    }

    // Use the first UTXO
    const utxo = utxos[0]

    // Create the transaction
    const network = bitcoin.networks.testnet
    const psbt = new bitcoin.Psbt({ network })

    // Fetch the transaction hex for the input
    const txResponse = await fetch(`https://mempool.space/testnet4/api/tx/${utxo.txid}/hex`)
    if (!txResponse.ok) {
      throw new Error("Failed to fetch transaction hex")
    }
    const txHex = await txResponse.text()

    // Add input
    psbt.addInput({
      hash: utxo.txid,
      index: utxo.vout,
      witnessUtxo: {
        script: bitcoin.payments.p2wpkh({
          pubkey: Buffer.from(
            bip32.fromSeed(bip39.mnemonicToSeedSync(wallet.seedPhrase)).derivePath("m/84'/1'/0'/0/0").publicKey,
          ),
          network,
        }).output!,
        value: utxo.value,
      },
    })

    // Calculate fee based on transaction size
    // P2WPKH input: ~68 vB, output: ~31 vB, base: ~10 vB
    // For 1 input, 1 output: ~109 vB
    const estimatedSize = 10 + 68 + 31 // base + input + output
    const feeRate = 3 // sat/vB
    const estimatedFee = Math.max(estimatedSize * feeRate, 500) // Ensure minimum 500 sats

    // Add output (send to same address, minus fee)
    const outputAmount = utxo.value - estimatedFee
    if (outputAmount <= 0) {
      throw new Error("UTXO value too small to cover fees")
    }

    psbt.addOutput({
      address: wallet.address,
      value: outputAmount,
    })

    // Sign the transaction
    const privateKeyBuffer = Buffer.from(wallet.privateKey, "hex")
    const keyPair = ECPair.fromPrivateKey(privateKeyBuffer, { network })

    // Create a signer compatible with PSBT
    const signer = {
      publicKey: Buffer.from(keyPair.publicKey),
      sign: (hash: Buffer) => Buffer.from(keyPair.sign(hash)),
    }

    psbt.signInput(0, signer)
    psbt.finalizeAllInputs()

    // Extract the transaction
    const tx = psbt.extractTransaction()
    const rawTx = tx.toHex()
    const txid = tx.getId()

    // Broadcast the transaction
    const broadcastResponse = await fetch("https://mempool.space/testnet4/api/tx", {
      method: "POST",
      body: rawTx,
    })

    if (!broadcastResponse.ok) {
      const errorText = await broadcastResponse.text()
      throw new Error(`Failed to broadcast transaction: ${errorText}`)
    }

    const broadcastedTxid = await broadcastResponse.text()

    return { txid: broadcastedTxid, rawTx }
  }

  async createTransaction(
    userId: string,
    recipientAddress: string,
    amount: number | null,
  ): Promise<{ txid: string; rawTx: string; sentAmount: number; fee: number }> {
    const wallet = await this.getWallet(userId)
    if (!wallet) {
      throw new Error("Wallet not found")
    }

    // Validate recipient address
    try {
      bitcoin.address.toOutputScript(recipientAddress, bitcoin.networks.testnet)
    } catch (error) {
      throw new Error("Invalid recipient address for testnet")
    }

    // Fetch UTXOs for the address
    const utxosResponse = await fetch(`https://mempool.space/testnet4/api/address/${wallet.address}/utxo`)
    if (!utxosResponse.ok) {
      throw new Error("Failed to fetch UTXOs")
    }

    const utxos = (await utxosResponse.json()) as Array<{
      txid: string
      vout: number
      status: { confirmed: boolean }
      value: number
    }>

    if (utxos.length === 0) {
      throw new Error("No UTXOs available. You need to fund your wallet first.")
    }

    // Calculate total available balance
    const totalBalance = utxos.reduce((sum, utxo) => sum + utxo.value, 0)

    // Estimate transaction size in virtual bytes (vB)
    // P2WPKH input: ~68 vB (witness data included)
    // P2WPKH output: ~31 vB
    // Base transaction: ~10 vB
    const inputSize = 68 // vB per P2WPKH input
    const outputSize = 31 // vB per output
    const baseSize = 10 // vB base transaction overhead
    
    // Estimate number of outputs (at least 1 for recipient, possibly 1 for change)
    const estimatedOutputs = 2 // recipient + potential change
    const estimatedSize = baseSize + (utxos.length * inputSize) + (estimatedOutputs * outputSize)
    
    // Use fee rate of 3 sat/vB to ensure we meet minimum relay fee
    // Minimum relay fee is typically 1 sat/vB, but we use 3 to be safe
    const feeRate = 3 // sat/vB
    let estimatedFee = estimatedSize * feeRate
    
    // Ensure minimum fee of 500 satoshis (based on error message requirement)
    estimatedFee = Math.max(estimatedFee, 500)

    // Determine the amount to send
    let sendAmount: number
    if (amount !== null) {
      // User specified an amount
      if (amount < 546) {
        throw new Error("Amount must be at least 546 satoshis (dust limit)")
      }
      if (amount + estimatedFee > totalBalance) {
        throw new Error(
          `Insufficient balance. Available: ${totalBalance} sats, Requested: ${amount} sats + ${estimatedFee} sats fee`,
        )
      }
      sendAmount = amount
    } else {
      // Send maximum (all UTXOs minus fee)
      sendAmount = totalBalance - estimatedFee
      if (sendAmount < 546) {
        throw new Error("Balance too low to send transaction after fees")
      }
    }

    // Create the transaction
    const network = bitcoin.networks.testnet
    const psbt = new bitcoin.Psbt({ network })

    // Add all UTXOs as inputs
    for (const utxo of utxos) {
      psbt.addInput({
        hash: utxo.txid,
        index: utxo.vout,
        witnessUtxo: {
          script: bitcoin.payments.p2wpkh({
            pubkey: Buffer.from(
              bip32.fromSeed(bip39.mnemonicToSeedSync(wallet.seedPhrase)).derivePath("m/84'/1'/0'/0/0").publicKey,
            ),
            network,
          }).output!,
          value: utxo.value,
        },
      })
    }

    // Add output to recipient
    psbt.addOutput({
      address: recipientAddress,
      value: sendAmount,
    })

    // Add change output if needed
    const changeAmount = totalBalance - sendAmount - estimatedFee
    if (changeAmount >= 546) {
      // Only add change if it's above dust limit
      psbt.addOutput({
        address: wallet.address,
        value: changeAmount,
      })
    }

    // Sign all inputs
    const privateKeyBuffer = Buffer.from(wallet.privateKey, "hex")
    const keyPair = ECPair.fromPrivateKey(privateKeyBuffer, { network })

    // Create a signer compatible with PSBT
    const signer = {
      publicKey: Buffer.from(keyPair.publicKey),
      sign: (hash: Buffer) => Buffer.from(keyPair.sign(hash)),
    }

    // Sign each input
    for (let i = 0; i < utxos.length; i++) {
      psbt.signInput(i, signer)
    }

    psbt.finalizeAllInputs()

    // Extract the transaction and calculate actual fee
    const tx = psbt.extractTransaction()
    const actualSize = tx.virtualSize()
    const requiredFee = Math.max(actualSize * feeRate, 500) // Ensure minimum 500 sats
    
    // Calculate actual fee from transaction (sum inputs - sum outputs)
    const totalInput = totalBalance
    const totalOutput = tx.outs.reduce((sum, out) => sum + out.value, 0)
    let actualFee = totalInput - totalOutput
    
    // If actual fee is less than required, we need to adjust
    // This shouldn't happen often, but if it does, the change output will be smaller
    if (actualFee < requiredFee) {
      // The fee is already baked into the outputs, so we can't easily adjust
      // But we've already set estimatedFee to be at least 500, so this should be rare
      // For now, we'll proceed - the network will reject if fee is too low
      // In practice, with feeRate of 2 sat/vB and min 500, this should work
    }
    
    const rawTx = tx.toHex()
    const txid = tx.getId()

    // Broadcast the transaction
    const broadcastResponse = await fetch("https://mempool.space/testnet4/api/tx", {
      method: "POST",
      body: rawTx,
    })

    if (!broadcastResponse.ok) {
      const errorText = await broadcastResponse.text()
      throw new Error(`Failed to broadcast transaction: ${errorText}`)
    }

    const broadcastedTxid = await broadcastResponse.text()

    return {
      txid: broadcastedTxid,
      rawTx,
      sentAmount: sendAmount,
      fee: actualFee,
    }
  }

  async queryTokens(
    appId?: string,
    appVk?: string,
    tokenUtxo?: string,
    witnessUtxo?: string,
  ): Promise<{
    appId: string
    appVk: string
    tokenUtxo: string
    witnessUtxo: string
    tokenInfo?: any
    utxoData?: any
  }> {
    // Default values from provided info
    const defaultAppId = "2ed3939eceafa9cdd5495e224c64f20b17e517bb7629153f1d5b5b0e3e87d2f5"
    const defaultAppVk = "175affa66db36da14c819c6e7396e5bc21d5315a878b4f6800f980e646c9e649"
    const defaultTokenUtxo = "d8786af1e7e597d77c073905fd6fd7053e4d12894eefa19c5deb45842fc2a8a2:0"
    const defaultWitnessUtxo = "f62d75e7c52c1929c63033b797947d8af0f4e720cc5d67be5198e24491818941:0"

    const finalAppId = appId || defaultAppId
    const finalAppVk = appVk || defaultAppVk
    const finalTokenUtxo = tokenUtxo || defaultTokenUtxo
    const finalWitnessUtxo = witnessUtxo || defaultWitnessUtxo

    // Parse UTXO (format: txid:vout)
    const [tokenTxid, tokenVout] = finalTokenUtxo.split(":")
    const [witnessTxid, witnessVout] = finalWitnessUtxo.split(":")

    // Query UTXO information from mempool
    let tokenInfo = null
    let utxoData = null

    try {
      // Query token UTXO
      const tokenUtxoResponse = await fetch(`https://mempool.space/testnet4/api/tx/${tokenTxid}`)
      if (tokenUtxoResponse.ok) {
        tokenInfo = await tokenUtxoResponse.json()
      }

      // Query witness UTXO
      const witnessUtxoResponse = await fetch(`https://mempool.space/testnet4/api/tx/${witnessTxid}`)
      if (witnessUtxoResponse.ok) {
        utxoData = await witnessUtxoResponse.json()
      }
    } catch (error) {
      console.error("Error querying UTXO data:", error)
    }

    return {
      appId: finalAppId,
      appVk: finalAppVk,
      tokenUtxo: finalTokenUtxo,
      witnessUtxo: finalWitnessUtxo,
      tokenInfo,
      utxoData,
    }
  }

  async getAddressTransactions(address: string, limit: number = 5): Promise<Array<{
    txid: string
    status: { confirmed: boolean; block_height?: number; block_hash?: string; block_time?: number }
    fee?: number
    size?: number
    weight?: number
    value?: number
  }>> {
    try {
      // Use mempool.space API to get address transactions
      const response = await fetch(`https://mempool.space/testnet4/api/address/${address}/txs`)
      
      if (!response.ok) {
        throw new Error(`Failed to fetch transactions: ${response.statusText}`)
      }

      const transactions = (await response.json()) as Array<{
        txid: string
        status: { confirmed: boolean; block_height?: number; block_hash?: string; block_time?: number }
        fee?: number
        size?: number
        weight?: number
        vin: Array<{ prevout?: { value?: number } }>
        vout: Array<{ value?: number }>
      }>

      // Get the last N transactions (already sorted by most recent)
      const lastTransactions = transactions.slice(0, limit)

      // Map to return format - transactions from address endpoint already have most info
      return lastTransactions.map((tx) => {
        // Calculate total output value
        const totalOutput = tx.vout.reduce((sum, output) => sum + (output.value || 0), 0)
        
        return {
          txid: tx.txid,
          status: tx.status,
          fee: tx.fee,
          size: tx.size,
          weight: tx.weight,
          value: totalOutput, // Total output value
        }
      })
    } catch (error) {
      console.error("Error fetching address transactions:", error)
      throw new Error("Failed to fetch address transactions from mempool")
    }
  }

  async getTransactionRawData(txid: string): Promise<{
    txid: string
    rawHex: string
    transaction: any
    spell?: any
    inputs: Array<{
      txid: string
      vout: number
      scriptSig?: string
      witness?: string[]
      sequence: number
    }>
    outputs: Array<{
      value: number
      scriptPubKey: string
      address?: string
      opReturn?: string
    }>
    size: number
    weight: number
    fee?: number
    status?: any
  }> {
    try {
      // Fetch raw transaction hex
      const hexResponse = await fetch(`https://mempool.space/testnet4/api/tx/${txid}/hex`)
      if (!hexResponse.ok) {
        throw new Error(`Failed to fetch transaction hex: ${hexResponse.statusText}`)
      }
      const rawHex = await hexResponse.text()

      // Fetch transaction details
      const txResponse = await fetch(`https://mempool.space/testnet4/api/tx/${txid}`)
      if (!txResponse.ok) {
        throw new Error(`Failed to fetch transaction details: ${txResponse.statusText}`)
      }
      const txData = (await txResponse.json()) as MempoolTransaction

      // Parse the raw transaction using bitcoinjs-lib
      const network = bitcoin.networks.testnet
      const tx = bitcoin.Transaction.fromHex(rawHex)

      // Extract inputs - get witness data from API response
      const inputs = tx.ins.map((input, index) => {
        // Get witness from API response if available
        const vinData = txData.vin?.[index]
        const witness = vinData?.witness ? vinData.witness.map((w: string) => w) : undefined
        
        return {
          txid: Buffer.from(input.hash).reverse().toString('hex'),
          vout: input.index,
          scriptSig: input.script.length > 0 ? input.script.toString('hex') : undefined,
          witness,
          sequence: input.sequence,
        }
      })

      // Extract outputs and look for OP_RETURN (spell data)
      const outputs = tx.outs.map((output, index) => {
        const script = output.script
        const scriptHex = script.toString('hex')
        
        // Check for OP_RETURN (0x6a)
        let opReturn: string | undefined
        if (script[0] === 0x6a) {
          // OP_RETURN found, extract the data
          const data = script.slice(1)
          opReturn = data.toString('hex')
          
          // Try to parse as UTF-8 string (spell JSON)
          try {
            const text = data.toString('utf8')
            if (text.startsWith('{') || text.startsWith('[')) {
              opReturn = text
            }
          } catch (e) {
            // Not valid UTF-8, keep as hex
          }
        }

        // Try to decode address from script
        let address: string | undefined
        try {
          address = bitcoin.address.fromOutputScript(script, network)
        } catch (e) {
          // Script doesn't represent a standard address
        }

        return {
          value: output.value,
          scriptPubKey: scriptHex,
          address,
          opReturn,
        }
      })

      // Try to parse spell from OP_RETURN outputs
      let spell: any | undefined
      for (const output of outputs) {
        if (output.opReturn && output.opReturn.startsWith('{')) {
          try {
            spell = JSON.parse(output.opReturn)
            break
          } catch (e) {
            // Not valid JSON
          }
        }
      }

      // Also check witness data for spell (charms.dev may embed spells in witness)
      // Get witness data from API response
      if (!spell && txData.vin) {
        for (const vin of txData.vin) {
          if (vin.witness && Array.isArray(vin.witness)) {
            for (const witnessItem of vin.witness) {
              try {
                // Witness items from API are hex strings, convert to buffer then to text
                const buffer = Buffer.from(witnessItem, 'hex')
                const text = buffer.toString('utf8')
                if (text.startsWith('{') && (text.includes('"version"') || text.includes('"apps"') || text.includes('"ins"') || text.includes('"outs"'))) {
                  spell = JSON.parse(text)
                  break
                }
              } catch (e) {
                // Not valid JSON or not UTF-8
              }
            }
          }
          if (spell) break
        }
      }

      // Calculate size if not provided by API
      const txSize = txData.size || Buffer.from(rawHex, 'hex').length
      // Use weight from API, or estimate (weight ≈ size * 4 for non-SegWit, or use virtual size calculation)
      const txWeight = txData.weight || (txSize * 4)

      return {
        txid,
        rawHex,
        transaction: txData,
        spell,
        inputs,
        outputs,
        size: txSize,
        weight: txWeight,
        fee: txData.fee,
        status: txData.status,
      }
    } catch (error) {
      console.error("Error fetching transaction raw data:", error)
      throw new Error(`Failed to fetch transaction raw data: ${error instanceof Error ? error.message : 'Unknown error'}`)
    }
  }

}
