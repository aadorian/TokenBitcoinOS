import type { DatabaseManager } from "./database"
import type { WalletManager } from "./wallet"
import * as crypto from "crypto"

export interface ClaimResult {
  success: boolean
  message: string
  amount?: number
  newBalance?: number
  txId?: string
}

export interface UserStats {
  balance: number
  totalMined: number
  totalClaims: number
  miningSessions: number
  bestZeroBits: number
  averageReward: number
}

export interface LeaderboardEntry {
  userId: string
  username: string
  balance: number
  totalMined: number
}

export class AirdropManager {
  constructor(
    private db: DatabaseManager,
    private walletManager: WalletManager,
  ) {}

  async claimTokens(userId: string): Promise<ClaimResult> {
    const wallet = await this.walletManager.getWallet(userId)

    if (!wallet) {
      return {
        success: false,
        message: "Wallet not found. Use `/airdrop-start` to create one.",
      }
    }

    const pendingReward = await this.db.getPendingReward(userId)

    if (pendingReward <= 0) {
      return {
        success: false,
        message: "No tokens to claim.",
      }
    }

    // Generate transaction ID
    const txId = this.generateTransactionId(userId, pendingReward)

    // Add tokens to balance
    const newBalance = await this.db.addTokens(userId, pendingReward)

    // Clear pending rewards
    await this.db.clearPendingReward(userId)

    // Record claim
    await this.db.recordClaim(userId, pendingReward, txId)

    return {
      success: true,
      message: "Tokens claimed successfully!",
      amount: pendingReward,
      newBalance,
      txId,
    }
  }

  async getBalance(userId: string): Promise<number | null> {
    return this.db.getBalance(userId)
  }

  async getUserStats(userId: string): Promise<UserStats> {
    return this.db.getUserStats(userId)
  }

  async getLeaderboard(limit: number): Promise<LeaderboardEntry[]> {
    return this.db.getLeaderboard(limit)
  }

  async getUserRank(userId: string): Promise<number> {
    return this.db.getUserRank(userId)
  }

  private generateTransactionId(userId: string, amount: number): string {
    const data = `${userId}:${amount}:${Date.now()}`
    const hash = crypto.createHash("sha256").update(data).digest("hex")
    return hash.substring(0, 64)
  }
}
