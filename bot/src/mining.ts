import * as crypto from "crypto"

export interface MiningResult {
  userId: string
  hash: string
  nonce: number
  zeroBits: number
  attempts: number
  reward: number
  timestamp: Date
}

export class MiningManager {
  /**
   * Mine for tokens using proof-of-work algorithm
   * Find hash with maximum leading zero bits
   */
  async mine(userId: string, durationSeconds: number): Promise<MiningResult> {
    const startTime = Date.now()
    const endTime = startTime + durationSeconds * 1000

    let bestHash = ""
    let bestNonce = 0
    let bestZeroBits = 0
    let attempts = 0
    let currentNonce = 0

    // Mining loop - find hash with most leading zero bits
    while (Date.now() < endTime) {
      const data = `${userId}:${currentNonce}:${Date.now()}`
      const hash = crypto.createHash("sha256").update(data).digest("hex")

      const zeroBits = this.countLeadingZeroBits(hash)
      attempts++

      if (zeroBits > bestZeroBits) {
        bestZeroBits = zeroBits
        bestHash = hash
        bestNonce = currentNonce
      }

      currentNonce++
    }

    // Calculate reward based on proof of work
    // Formula similar to BRO: 100M * clz² / 2^h
    const reward = this.calculateReward(bestZeroBits)

    return {
      userId,
      hash: bestHash,
      nonce: bestNonce,
      zeroBits: bestZeroBits,
      attempts,
      reward,
      timestamp: new Date(),
    }
  }

  private countLeadingZeroBits(hash: string): number {
    let count = 0

    for (let i = 0; i < hash.length; i++) {
      const hex = Number.parseInt(hash[i], 16)

      if (hex === 0) {
        count += 4
      } else {
        // Count leading zeros in the nibble
        let mask = 8 // 1000 in binary
        while (mask > 0 && (hex & mask) === 0) {
          count++
          mask >>= 1
        }
        break
      }
    }

    return count
  }

  private calculateReward(zeroBits: number): number {
    // Reward formula: 100M * zeroBits² / 2^hashDifficulty
    // Adjusted for reasonable rewards
    const baseReward = 1000000 // 1M base
    const hashDifficulty = 12 // Difficulty parameter

    const reward = (baseReward * Math.pow(zeroBits, 2)) / Math.pow(2, hashDifficulty)

    // Ensure minimum reward
    return Math.max(reward, 10)
  }
}
