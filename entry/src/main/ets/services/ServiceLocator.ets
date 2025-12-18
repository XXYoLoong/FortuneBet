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
