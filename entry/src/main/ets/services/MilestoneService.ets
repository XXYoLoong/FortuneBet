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
import { MILESTONES } from '../common/constants';
import type { Milestone } from '../common/types';
import { ensureStorage, StorageService } from './StorageService';

/**
 * 里程碑服务：管理用户成就系统
 */
export class MilestoneService {
  private storage?: StorageService;

  async init(context: Context): Promise<void> {
    this.storage = await ensureStorage(context);
  }

  async getUserMilestones(account: string): Promise<Milestone[]> {
    if (!this.storage) return [];
    const user = await this.storage.getUser(account);
    if (!user) return [];
    
    const totalCoins = user.totalCoins;
    return MILESTONES.map((m, index): Milestone => ({
      id: index + 1,
      threshold: m.threshold,
      title: m.title,
      description: m.description,
      unlocked: totalCoins >= m.threshold
    }));
  }

  async getUnlockedCount(account: string): Promise<number> {
    const milestones = await this.getUserMilestones(account);
    return milestones.filter(m => m.unlocked).length;
  }
}

export async function createMilestoneService(context: Context): Promise<MilestoneService> {
  const svc = new MilestoneService();
  await svc.init(context);
  return svc;
}

