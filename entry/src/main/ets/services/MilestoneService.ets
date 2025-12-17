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

