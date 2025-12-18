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
// See the License for the specific language governing permissions and
// limitations under the License.

import type { Context } from '@kit.AbilityKit';
import type { GameRound } from '../common/types';
import { ensureStorage, StorageService } from './StorageService';

/**
 * 历史记录服务：管理用户游戏轮次历史
 */
export class HistoryService {
  private storage?: StorageService;

  async init(context: Context): Promise<void> {
    this.storage = await ensureStorage(context);
  }

  async listRounds(account: string): Promise<GameRound[]> {
    if (!this.storage) return [];
    // 现在 StorageService 中已经有了 listGameRounds
    return await this.storage.listGameRounds(account);
  }

  async saveRound(round: GameRound): Promise<void> {
    if (!this.storage) return;
    // 现在 StorageService 中已经有了 saveGameRound
    await this.storage.saveGameRound(round);
  }

  async getNextRoundNumber(account: string): Promise<number> {
    if (!this.storage) return 1;
    // 现在 StorageService 中已经有了 getNextRoundNumber
    return await this.storage.getNextRoundNumber(account);
  }
}

export async function createHistoryService(context: Context): Promise<HistoryService> {
  const svc = new HistoryService();
  await svc.init(context);
  return svc;
}