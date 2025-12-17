import { AuthResult } from '../common/types';
import { initServices, useAuthService } from '../services/ServiceLocator';
import { GamePage } from './game/GamePage';
import { HistoryPage } from './history/HistoryPage';
import { MilestonePage } from './milestone/MilestonePage';
import { ProfilePage } from './profile/ProfilePage';

@Entry
@Component
struct Index {
  @State currentTab: string = 'game';
  @State initialized: boolean = false;
  @State account: string = '';
  @State loginAccount: string = '';
  @State loginPassword: string = '';
  @State loginError: string = '';
  @State isLoading: boolean = false;
  @State isRegisterMode: boolean = false;

  async aboutToAppear(): Promise<void> {
    try {
      await initServices(getContext(this));
      const auth = useAuthService();
      // Only check for existing session, do not auto-create
      const profile = await auth.currentUser();
      if (profile) {
        this.account = profile.account;
      }
    } catch (e) {
      const error = e instanceof Error ? e : new Error(String(e));
      console.error('Initialization failed:', error.message);
    } finally {
      this.initialized = true;
    }
  }

  private async handleLogin(): Promise<void> {
    if (this.isLoading) return;

    const isInternalTest = this.loginAccount === '1' && this.loginPassword === '1';

    if (!this.loginAccount.trim()) {
      this.loginError = '请输入账号';
      return;
    }
    if (!this.loginPassword.trim()) {
      this.loginError = '请输入密码';
      return;
    }

    this.isLoading = true;
    this.loginError = '';

    try {
      const auth = useAuthService();

      // CHANGE: Use the explicit interface instead of 'any'
      let res: AuthResult;

      if (isInternalTest) {
        // Try login first
        res = await auth.login(this.loginAccount, this.loginPassword);
        // If login fails, auto-register
        if (!res.ok) {
          res = await auth.register(this.loginAccount, this.loginPassword);
        }
      } else {
        // Standard user flow
        res = this.isRegisterMode
          ? await auth.register(this.loginAccount.trim(), this.loginPassword.trim())
          : await auth.login(this.loginAccount.trim(), this.loginPassword.trim());
      }

      if (!res.ok) {
        this.loginError = res.message ?? '操作失败';
        this.isLoading = false;
        return;
      }

      // Since we checked res.ok, we assume profile exists, but safe navigation is good
      if (res.profile) {
        this.account = res.profile.account;
      }

      this.loginAccount = '';
      this.loginPassword = '';
      this.loginError = '';
      this.isRegisterMode = false;
    } catch (e) {
      const error = e instanceof Error ? e : new Error(String(e));
      this.loginError = `操作失败: ${error.message}`;
    } finally {
      this.isLoading = false;
    }
  }

  private async handleForgetPassword(): Promise<void> {
    this.loginError = '本地应用，请记住您的密码';
  }

  build() {
    Column() {
      if (!this.initialized) {
        Column() {
          Text('加载中...').fontSize(16).fontColor('#666666');
        }
        .width('100%').height('100%')
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center);
      } else if (!this.account) {
        this.renderLogin();
      } else {
        this.renderTabs();
      }
    }.width('100%').height('100%')
  }

  @Builder
  private renderLogin() {
    Column() {
      Text('鸿运押宝')
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .fontColor('#e04542')
        .margin({ bottom: 50 });

      Column() {
        // Account Input
        Column() {
          Text('账号').fontSize(14).fontColor('#333333').alignSelf(ItemAlign.Start).margin({ bottom: 8 });
          TextInput({
            placeholder: '请输入账号',
            text: this.loginAccount
          })
            .width('100%').height(48)
            .backgroundColor('#f8f8f8').borderRadius(8)
            .padding({ left: 12, right: 12 })
            .border({ width: 1, color: this.loginAccount ? '#e04542' : '#e0e0e0' })
            .onChange(v => { this.loginAccount = v; this.loginError = ''; })
            .enabled(!this.isLoading);
        }.width('100%').margin({ bottom: 20 });

        // Password Input
        Column() {
          Text('密码').fontSize(14).fontColor('#333333').alignSelf(ItemAlign.Start).margin({ bottom: 8 });
          TextInput({
            placeholder: '请输入密码',
            text: this.loginPassword
          })
            .type(InputType.Password)
            .width('100%').height(48)
            .backgroundColor('#f8f8f8').borderRadius(8)
            .padding({ left: 12, right: 12 })
            .border({ width: 1, color: this.loginPassword ? '#e04542' : '#e0e0e0' })
            .showPasswordIcon(true)
            .onChange(v => { this.loginPassword = v; this.loginError = ''; })
            .enabled(!this.isLoading);
        }.width('100%').margin({ bottom: 12 });

        if (this.loginError) {
          Text(this.loginError)
            .fontColor('#ff3333').fontSize(13).width('100%')
            .textAlign(TextAlign.Start).margin({ bottom: 12 });
        }

        Button(this.isLoading ? (this.isRegisterMode ? '注册中...' : '登录中...') : (this.isRegisterMode ? '注册' : '登录'), {
          type: ButtonType.Capsule, stateEffect: true
        })
          .width('100%').height(50)
          .fontSize(16).fontWeight(FontWeight.Medium)
        // Allow simplified validation for "1"
          .enabled(!this.isLoading && this.loginAccount.length > 0 && this.loginPassword.length > 0)
          .onClick(async () => await this.handleLogin());

        Row() {
          Text('忘记密码').fontSize(14).fontColor('#5083ff')
            .onClick(async () => await this.handleForgetPassword());
          Blank();
          Text(this.isRegisterMode ? '已有账号？去登录' : '没有账号？去注册')
            .fontSize(14).fontColor('#5083ff')
            .onClick(() => {
              this.isRegisterMode = !this.isRegisterMode;
              this.loginError = '';
            });
        }.width('100%').margin({ top: 20 });

        // REMOVED: The visual hint for test account
      }
      .width('85%').padding(24)
      .backgroundColor('#ffffff').borderRadius(16)
      .shadow({ radius: 8, color: '#1f000000', offsetX: 0, offsetY: 2 });
    }
    .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    .width('100%').height('100%').backgroundColor('#f5f5f5');
  }

  @Builder
  private renderTabs() {
    Column() {
      Tabs({ index: this.getTabIndex() }) {
        TabContent() { GamePage({ account: this.account }) }.tabBar(this.buildTabBuilder('游戏', 'game'))
        TabContent() { HistoryPage({ account: this.account }) }.tabBar(this.buildTabBuilder('历史', 'history'))
        TabContent() { MilestonePage({ account: this.account }) }.tabBar(this.buildTabBuilder('里程碑', 'milestone'))
        TabContent() { ProfilePage({ account: this.account }) }.tabBar(this.buildTabBuilder('我的', 'profile'))
      }
      .barPosition(BarPosition.End)
      .onChange(index => {
        const map = ['game', 'history', 'milestone', 'profile'];
        this.currentTab = map[index] ?? 'game';
      });
    }.width('100%').height('100%')
  }

  private getTabIndex(): number {
    switch (this.currentTab) {
      case 'history': return 1;
      case 'milestone': return 2;
      case 'profile': return 3;
      default: return 0;
    }
  }

  @Builder
  private buildTabBuilder(label: string, key: string) {
    Column() {
      Text(label).fontSize(14).fontColor(this.currentTab === key ? '#e04542' : '#666666');
    }.padding(10);
  }
}