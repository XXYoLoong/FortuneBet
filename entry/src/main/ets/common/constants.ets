import { BetOption, Milestone } from './types';

export const MAX_ACCOUNT = 20;
export const MIN_ACCOUNT = 3;
export const MAX_PASSWORD = 20;
export const MIN_PASSWORD = 6;

export const TEST_ACCOUNT = '1';
export const TEST_PASSWORD = '1';

// 每日登录奖励
export const DAILY_COINS = 30;

// 每轮游戏时长 (毫秒) - 设为 60秒
export const ROUND_DURATION_MS = 60 * 1000;

// 【优化】阶梯式赔率规则
// 总权重 1000，计算概率方便
export const BET_GRID: BetOption[] = [
  { value: 100, weight: 1 },   // 0.1%  顶级大奖
  { value: 50, weight: 3 },    // 0.3%
  { value: 30, weight: 6 },    // 0.6%
  { value: 20, weight: 15 },   // 1.5%

  { value: 15, weight: 25 },   // 2.5%
  { value: 12, weight: 50 },   // 5.0%
  { value: 10, weight: 80 },   // 8.0%
  { value: 8, weight: 120 },   // 12.0%

  { value: 6, weight: 150 },   // 15.0%
  { value: 5, weight: 200 },   // 20.0%
  { value: 4, weight: 250 },   // 25.0%  防守主力
  { value: 2, weight: 100 }    // 10.0%  保本位
];

export const AVATAR_LIST: string[] = [
  'avatar_default',
  'avatar_1', 'avatar_2', 'avatar_3', 'avatar_4',
  'avatar_5', 'avatar_6', 'avatar_7', 'avatar_8'
];

// 里程碑配置
export const MILESTONES: Milestone[] = [
  { id: 1, threshold: 100, title: '初出茅庐', description: '累计获得100游戏币', unlocked: false },
  { id: 2, threshold: 1000, title: '小有成就', description: '累计获得1,000游戏币', unlocked: false },
  { id: 3, threshold: 10000, title: '财源滚滚', description: '累计获得10,000游戏币', unlocked: false },
  { id: 4, threshold: 100000, title: '富甲一方', description: '累计获得100,000游戏币', unlocked: false },
  { id: 5, threshold: 1000000, title: '首富传说', description: '累计获得1,000,000游戏币', unlocked: false },
];