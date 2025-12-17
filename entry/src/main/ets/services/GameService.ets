import { BET_GRID, ROUND_DURATION_MS } from '../common/constants';
import type { BetTicket, GameRound, SettleResult } from '../common/types';
import { ProbabilityPredictor } from './ProbabilityPredictor';
import { useHistoryService } from './ServiceLocator';
import { ensureStorage, StorageService } from './StorageService';
import type { Context } from '@kit.AbilityKit';

export class GameService {
  private predictor = new ProbabilityPredictor(BET_GRID);
  private isRoundActive: boolean = false;
  private currentBets: BetTicket[] = [];
  private roundStartTime: number = 0;
  private roundNumber: number = 1;
  private storage?: StorageService;

  async init(context: Context): Promise<void> {
    this.storage = await ensureStorage(context);
    this.isRoundActive = false;
  }

  startRound(): void {
    if (this.isRoundActive) return;
    this.isRoundActive = true;
    this.currentBets = [];
    this.roundStartTime = Date.now();
  }

  getCountdown(): number {
    if (!this.isRoundActive) return 0;
    const elapsed = Date.now() - this.roundStartTime;
    const remaining = ROUND_DURATION_MS - elapsed;
    return Math.max(0, remaining);
  }

  isBettingPhase(): boolean {
    return this.isRoundActive && this.getCountdown() > 0;
  }

  async addBet(account: string, ticket: BetTicket): Promise<boolean> {
    if (!this.isBettingPhase()) return false;
    if (!this.storage) return false;

    const user = await this.storage.getUser(account);
    if (!user) return false;

    const totalBet = this.getTotalBet();
    const existingBet = this.currentBets.find(b => b.value === ticket.value);
    const existingAmount = existingBet ? existingBet.amount : 0;
    const newTotal = totalBet - existingAmount + ticket.amount;
    const balance = user.balance ?? 0;

    if (newTotal > balance) {
      return false;
    }

    const idx = this.currentBets.findIndex(b => b.value === ticket.value);
    if (idx >= 0) {
      this.currentBets[idx].amount = ticket.amount;
    } else {
      this.currentBets.push({ value: ticket.value, amount: ticket.amount });
    }
    return true;
  }

  getTotalBet(): number {
    return this.currentBets.reduce((sum, b) => sum + b.amount, 0);
  }

  getBetAmount(value: number): number {
    const bet = this.currentBets.find(b => b.value === value);
    return bet ? bet.amount : 0;
  }

  getCurrentBets(): BetTicket[] {
    return [...this.currentBets];
  }

  async settle(account: string): Promise<SettleResult> {
    if (!this.isRoundActive) throw new Error('游戏未开始');
    if (!this.storage) throw new Error('存储未初始化');

    const resultValue = this.predictor.pick();
    const totalBet = this.getTotalBet();
    const winningBet = this.currentBets.find(b => b.value === resultValue);

    let coinsEarned = 0;
    if (winningBet) {
      coinsEarned = winningBet.amount * resultValue;
    }

    // 1. 扣除下注
    await this.storage.updateBalance(account, -totalBet);

    // 2. 添加奖励 (注意：updateUserTotalCoins 已被移除，逻辑包含在 updateBalance 中)
    if (coinsEarned > 0) {
      await this.storage.updateBalance(account, coinsEarned);
    }

    // 保存游戏轮次
    const historySvc = useHistoryService();
    const roundNumber = await historySvc.getNextRoundNumber(account);
    const round: GameRound = {
      id: `${Date.now()}-${Math.random()}`,
      roundNumber,
      account,
      coinsUsed: totalBet,
      coinsEarned,
      resultValue,
      bets: [...this.currentBets],
      createdAt: Date.now(),
      balanceSnapshot: 0
    };
    await historySvc.saveRound(round);

    this.isRoundActive = false;
    this.currentBets = [];
    this.roundNumber = roundNumber + 1;

    const result: SettleResult = {
      result: resultValue,
      winnings: coinsEarned,
      round
    };
    return result;
  }

  reset(): void {
    this.isRoundActive = false;
    this.currentBets = [];
    this.roundStartTime = 0;
  }

  simulate(times: number) {
    return this.predictor.simulate(times);
  }
}

export async function createGameService(context: Context): Promise<GameService> {
  const svc = new GameService();
  await svc.init(context);
  return svc;
}