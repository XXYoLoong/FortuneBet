import { createAuthService, AuthService } from './AuthService';
import { createGameService, GameService } from './GameService';
import { createHistoryService, HistoryService } from './HistoryService';
import { createMilestoneService, MilestoneService } from './MilestoneService';
import type { Context } from '@kit.AbilityKit';

let authSvc: AuthService | undefined;
let gameSvc: GameService | undefined;
let historySvc: HistoryService | undefined;
let milestoneSvc: MilestoneService | undefined;

export async function initServices(context: Context): Promise<void> {
  authSvc = await createAuthService(context);
  gameSvc = await createGameService(context);
  historySvc = await createHistoryService(context);
  milestoneSvc = await createMilestoneService(context);
}

export function useAuthService(): AuthService {
  if (!authSvc) throw new Error('AuthService not initialized');
  return authSvc;
}

export function useGameService(): GameService {
  if (!gameSvc) throw new Error('GameService not initialized');
  return gameSvc;
}

export function useHistoryService(): HistoryService {
  if (!historySvc) throw new Error('HistoryService not initialized');
  return historySvc;
}

export function useMilestoneService(): MilestoneService {
  if (!milestoneSvc) throw new Error('MilestoneService not initialized');
  return milestoneSvc;
}
