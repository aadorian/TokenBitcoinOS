import type { Wallet } from "./wallet"
import type { MiningResult } from "./mining"
import type { UserStats, LeaderboardEntry } from "./airdrop"

interface UserData {
  userId: string
  username: string
  wallet: Wallet
  balance: number
  totalMined: number
  totalClaims: number
  miningSessions: number
  bestZeroBits: number
  pendingReward: number
  miningHistory: MiningResult[]
  claimHistory: ClaimRecord[]
  tipsSent: TipRecord[]
  tipsReceived: TipRecord[]
  totalTipped: number
  totalReceived: number
  transactionCount: number
  createdAt: Date
}

interface ClaimRecord {
  amount: number
  txId: string
  timestamp: Date
}

interface TipRecord {
  fromUserId: string
  fromUsername: string
  toUserId: string
  toUsername: string
  amount: number
  message?: string
  timestamp: Date
}

export class DatabaseManager {
  private users: Map<string, UserData> = new Map()

  async saveWallet(wallet: Wallet, username: string): Promise<void> {
    const userData: UserData = {
      userId: wallet.userId,
      username,
      wallet,
      balance: 0,
      totalMined: 0,
      totalClaims: 0,
      miningSessions: 0,
      bestZeroBits: 0,
      pendingReward: 0,
      miningHistory: [],
      claimHistory: [],
      tipsSent: [],
      tipsReceived: [],
      totalTipped: 0,
      totalReceived: 0,
      transactionCount: 0,
      createdAt: new Date(),
    }

    this.users.set(wallet.userId, userData)
  }

  async getWallet(userId: string): Promise<Wallet | null> {
    const user = this.users.get(userId)
    return user ? user.wallet : null
  }

  async saveMiningResult(result: MiningResult): Promise<void> {
    const user = this.users.get(result.userId)

    if (!user) {
      throw new Error("User not found")
    }

    user.miningHistory.push(result)
    user.miningSessions++
    user.pendingReward += result.reward

    if (result.zeroBits > user.bestZeroBits) {
      user.bestZeroBits = result.zeroBits
    }
  }

  async getPendingReward(userId: string): Promise<number> {
    const user = this.users.get(userId)
    return user ? user.pendingReward : 0
  }

  async addTokens(userId: string, amount: number): Promise<number> {
    const user = this.users.get(userId)

    if (!user) {
      throw new Error("User not found")
    }

    user.balance += amount
    user.totalMined += amount

    return user.balance
  }

  async clearPendingReward(userId: string): Promise<void> {
    const user = this.users.get(userId)

    if (user) {
      user.pendingReward = 0
    }
  }

  async recordClaim(userId: string, amount: number, txId: string): Promise<void> {
    const user = this.users.get(userId)

    if (!user) {
      throw new Error("User not found")
    }

    user.claimHistory.push({
      amount,
      txId,
      timestamp: new Date(),
    })

    user.totalClaims++
  }

  async getBalance(userId: string): Promise<number | null> {
    const user = this.users.get(userId)
    return user ? user.balance : null
  }

  async getUserStats(userId: string): Promise<UserStats> {
    const user = this.users.get(userId)

    if (!user) {
      return {
        balance: 0,
        totalMined: 0,
        totalClaims: 0,
        miningSessions: 0,
        bestZeroBits: 0,
        averageReward: 0,
      }
    }

    const averageReward = user.miningSessions > 0 ? user.totalMined / user.miningSessions : 0

    return {
      balance: user.balance,
      totalMined: user.totalMined,
      totalClaims: user.totalClaims,
      miningSessions: user.miningSessions,
      bestZeroBits: user.bestZeroBits,
      averageReward,
    }
  }

  async getLeaderboard(limit: number): Promise<LeaderboardEntry[]> {
    const entries = Array.from(this.users.values())
      .map((user) => ({
        userId: user.userId,
        username: user.username,
        balance: user.balance,
        totalMined: user.totalMined,
      }))
      .sort((a, b) => b.balance - a.balance)
      .slice(0, limit)

    return entries
  }

  async getUserRank(userId: string): Promise<number> {
    const user = this.users.get(userId)

    if (!user) {
      return 0
    }

    const sorted = Array.from(this.users.values()).sort((a, b) => b.balance - a.balance)

    const rank = sorted.findIndex((u) => u.userId === userId)
    return rank + 1
  }

  async clearUserData(userId: string): Promise<boolean> {
    return this.users.delete(userId)
  }

  async tipUser(fromUserId: string, toUserId: string, amount: number, message?: string): Promise<{ success: boolean; error?: string }> {
    const sender = this.users.get(fromUserId)
    const receiver = this.users.get(toUserId)

    if (!sender) {
      return { success: false, error: "Sender wallet not found" }
    }

    if (!receiver) {
      return { success: false, error: "Receiver wallet not found" }
    }

    if (sender.balance < amount) {
      return { success: false, error: `Insufficient balance. You have ${sender.balance.toFixed(2)} CHARMS` }
    }

    if (amount <= 0) {
      return { success: false, error: "Amount must be greater than 0" }
    }

    // Perform the tip
    sender.balance -= amount
    receiver.balance += amount

    // Record the tip
    const tipRecord: TipRecord = {
      fromUserId: sender.userId,
      fromUsername: sender.username,
      toUserId: receiver.userId,
      toUsername: receiver.username,
      amount,
      message,
      timestamp: new Date(),
    }

    sender.tipsSent.push(tipRecord)
    receiver.tipsReceived.push(tipRecord)
    sender.totalTipped += amount
    receiver.totalReceived += amount

    return { success: true }
  }

  async getUserData(userId: string): Promise<UserData | null> {
    return this.users.get(userId) || null
  }

  async getAllUsers(): Promise<UserData[]> {
    return Array.from(this.users.values())
  }

  async incrementTransactionCount(userId: string): Promise<void> {
    const user = this.users.get(userId)
    if (user) {
      user.transactionCount++
    }
  }
}
