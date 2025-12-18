export interface UserProfile {
  account: string;
  password?: string;
  nickname?: string;
  balance: number;
  totalCoins: number;
  lastLogin: number;
  lastDailyDate: number;
  quote?: string;     // 个性签名
  gameName?: string;  // 游戏绑定名
  avatarId?: string;  // 【新增】头像ID字符串
}

export interface BetOption {
  value: number;  // 倍率
  weight: number; // 权重（概率）
}

export interface BetTicket {
  value: number;
  amount: number;
}

export interface GameRound {
  id: string;
  roundNumber: number;
  account: string;
  coinsUsed: number;
  coinsEarned: number;
  resultValue: number;
  bets: BetTicket[];
  createdAt: number;
  balanceSnapshot: number; // 【新增】结算后的余额快照，用于绘制资产曲线
}

export interface SettleResult {
  result: number;
  winnings: number;
  round: GameRound;
}

export interface AuthResult {
  ok: boolean;
  message?: string;
  profile?: UserProfile;
}

export interface Milestone {
  id: number;
  threshold: number;
  title: string;
  description: string;
  unlocked: boolean;
}

export interface ProbabilityReport {
  total: number;
  counts: Map<number, number>;
  distribution: Map<number, number>;
}