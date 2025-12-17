import { Context } from '@kit.AbilityKit';
import { UserProfile, AuthResult } from '../common/types';
import { ensureStorage, StorageService } from './StorageService';
import { DAILY_COINS } from '../common/constants';

export class AuthService {
  private storage?: StorageService;

  async init(context: Context): Promise<void> {
    this.storage = await ensureStorage(context);
  }

  private simpleHash(password: string): string {
    let hash = 0;
    for (let i = 0; i < password.length; i++) {
      const char = password.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    return Math.abs(hash).toString(16);
  }

  async login(account: string, password: string): Promise<AuthResult> {
    if (!this.storage) return { ok: false, message: '系统未初始化' };

    if (account === '1' && password === '1') {
      return this.handleTestAccountLogin();
    }

    const user = await this.storage.getUser(account);
    if (!user) {
      return { ok: false, message: '账号不存在' };
    }

    if (user.password !== this.simpleHash(password)) {
      return { ok: false, message: '密码错误' };
    }

    await this.storage.setLoginAccount(account);

    const updatedUser = await this.storage.ensureDailyCoins(account);

    return { ok: true, profile: updatedUser ?? user };
  }

  async register(account: string, password: string): Promise<AuthResult> {
    if (!this.storage) return { ok: false, message: '系统未初始化' };

    const existing = await this.storage.getUser(account);
    if (existing) {
      return { ok: false, message: '账号已存在' };
    }

    const newUser: UserProfile = {
      account: account,
      password: this.simpleHash(password),
      nickname: '玩家' + account,
      balance: DAILY_COINS,
      totalCoins: 0,
      lastLogin: Date.now(),
      lastDailyDate: Date.now()
    };

    await this.storage.saveUser(newUser);
    await this.storage.setLoginAccount(account);

    return { ok: true, profile: newUser };
  }

  async currentUser(): Promise<UserProfile | undefined> {
    if (!this.storage) return undefined;
    const account = await this.storage.getLoginAccount();
    if (!account) return undefined;

    return (await this.storage.ensureDailyCoins(account)) ?? undefined;
  }

  private async handleTestAccountLogin(): Promise<AuthResult> {
    if (!this.storage) return { ok: false };

    let user = await this.storage.getUser('1');

    if (!user) {
      user = {
        account: '1',
        password: this.simpleHash('1'),
        nickname: '内测管理员',
        balance: 9999,
        totalCoins: 0,
        lastLogin: Date.now(),
        lastDailyDate: Date.now()
      };
      await this.storage.saveUser(user);
    } else {
      // 修复：user.balance 可能是 undefined
      const currentBalance = user.balance ?? 0;
      if (currentBalance < 10) {
        user.balance = 5000;
        await this.storage.saveUser(user);
      }
    }

    await this.storage.setLoginAccount('1');
    return { ok: true, profile: user };
  }
}

export async function createAuthService(context: Context): Promise<AuthService> {
  const svc = new AuthService();
  await svc.init(context);
  return svc;
}