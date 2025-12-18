// Copyright 2025 Jiacheng Ni
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and limitations under the License.
import dataPreferences from '@ohos.data.preferences';
import { common } from '@kit.AbilityKit';
import { UserProfile, GameRound } from '../common/types'; // 确保这里包含 GameRound
import { DAILY_COINS } from '../common/constants';

const PREFERENCES_NAME = 'MyGameStore';
const KEY_USER_PREFIX = 'user_';
const KEY_ROUNDS_PREFIX = 'rounds_'; // 新增：历史记录前缀
const KEY_CURRENT_LOGIN = 'current_login_account';

export class StorageService {
  private pref: dataPreferences.Preferences | null = null;
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  async init(): Promise<void> {
    try {
      this.pref = await dataPreferences.getPreferences(this.context, PREFERENCES_NAME);
      console.info('StorageService: Database initialized successfully');
    } catch (e) {
      console.error('StorageService: Failed to init database', e);
    }
  }

  async getLoginAccount(): Promise<string> {
    if (!this.pref) await this.init();
    if (!this.pref) return '';
    return (await this.pref.get(KEY_CURRENT_LOGIN, '')) as string;
  }

  async setLoginAccount(account: string): Promise<void> {
    if (!this.pref) await this.init();
    if (this.pref) {
      await this.pref.put(KEY_CURRENT_LOGIN, account);
      await this.pref.flush();
    }
  }

  async getUser(account: string): Promise<UserProfile | null> {
    if (!account) return null;
    if (!this.pref) await this.init();
    if (!this.pref) return null;

    const key = KEY_USER_PREFIX + account;
    const jsonStr = (await this.pref.get(key, '')) as string;

    if (!jsonStr) return null;

    try {
      return JSON.parse(jsonStr) as UserProfile;
    } catch (e) {
      console.error('StorageService: JSON parse error', e);
      return null;
    }
  }

  async saveUser(user: UserProfile): Promise<void> {
    if (!this.pref) await this.init();
    if (this.pref) {
      const key = KEY_USER_PREFIX + user.account;
      const jsonStr = JSON.stringify(user);

      await this.pref.put(key, jsonStr);
      await this.pref.flush();
      console.info(`StorageService: Saved user ${user.account}`);
    }
  }

  async ensureDailyCoins(account: string): Promise<UserProfile | null> {
    const user = await this.getUser(account);
    if (!user) return null;

    const now = Date.now();
    // 修复：处理 undefined 日期，给默认值 0
    const lastDate = new Date(user.lastDailyDate ?? 0);
    const today = new Date(now);

    const isSameDay = lastDate.getFullYear() === today.getFullYear() &&
      lastDate.getMonth() === today.getMonth() &&
      lastDate.getDate() === today.getDate();

    let needsUpdate = false;
    // 修复：处理 undefined 余额
    const currentBalance = user.balance ?? 0;

    if (!isSameDay) {
      console.info('StorageService: New day detected, granting daily coins');
      user.balance = currentBalance + DAILY_COINS;
      user.lastDailyDate = now;
      needsUpdate = true;
    }
    else if (currentBalance <= 0) {
      console.info('StorageService: Zero balance detected, granting relief coins');
      user.balance = DAILY_COINS;
      user.lastDailyDate = now;
      needsUpdate = true;
    }

    if (needsUpdate) {
      await this.saveUser(user);
      return user;
    }

    return user;
  }

  async updateBalance(account: string, changeAmount: number): Promise<UserProfile | null> {
    const user = await this.getUser(account);
    if (!user) return null;

    // 修复：处理 undefined
    const currentBalance = user.balance ?? 0;
    let newBalance = currentBalance + changeAmount;

    if (newBalance < 0) newBalance = 0;
    user.balance = newBalance;

    // 自动累加历史总金币
    if (changeAmount > 0) {
      const currentTotal = user.totalCoins ?? 0;
      user.totalCoins = currentTotal + changeAmount;
    }

    await this.saveUser(user);
    return user;
  }

  // ==========================================================
  // 新增：历史记录相关方法 (解决 HistoryService 报错)
  // ==========================================================

  async listGameRounds(account: string): Promise<GameRound[]> {
    if (!account) return [];
    if (!this.pref) await this.init();
    if (!this.pref) return [];

    const key = KEY_ROUNDS_PREFIX + account;
    const jsonStr = (await this.pref.get(key, '')) as string;

    if (!jsonStr) return [];
    try {
      return JSON.parse(jsonStr) as GameRound[];
    } catch (e) {
      return [];
    }
  }

  async saveGameRound(round: GameRound): Promise<void> {
    if (!this.pref) await this.init();
    if (!this.pref) return;

    // 读取旧记录
    const rounds = await this.listGameRounds(round.account);
    // 插入新记录到头部
    rounds.unshift(round);

    // 限制存储数量（防止首选项过大）
    if (rounds.length > 50) {
      rounds.length = 50;
    }

    const key = KEY_ROUNDS_PREFIX + round.account;
    await this.pref.put(key, JSON.stringify(rounds));
    await this.pref.flush();
  }

  async getNextRoundNumber(account: string): Promise<number> {
    const rounds = await this.listGameRounds(account);
    return rounds.length + 1;
  }
}

let storageInstance: StorageService | null = null;

export async function ensureStorage(context: Context): Promise<StorageService> {
  if (!storageInstance) {
    storageInstance = new StorageService(context as common.UIAbilityContext);
    await storageInstance.init();
  }
  return storageInstance;
}