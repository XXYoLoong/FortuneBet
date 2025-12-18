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

  // 【核心修改】使用 StorageLink 建立全局双向绑定
  // 当任何地方修改 'currentAccount' 时，这里会自动更新
  @StorageLink('currentAccount') account: string = '';

  @State loginAccount: string = '';
  @State loginPassword: string = '';
  @State loginError: string = '';
  @State isLoading: boolean = false;
  @State isRegisterMode: boolean = false;

  async aboutToAppear(): Promise<void> {
    try {
      await initServices(getContext(this));
      // 【核心修改】初始化服务后，不再自动读取 currentUser 赋值给 account
      // 从而强制用户必须在界面上手动点击登录
      this.initialized = true;
    } catch (e) {
      console.error('Initialization failed:', e);
    }
  }

  private async handleLogin(): Promise<void> {
    if (this.isLoading) return;

    // 内测账号快捷通道
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
      let res: AuthResult;

      if (isInternalTest) {
        res = await auth.login(this.loginAccount, this.loginPassword);
        if (!res.ok) {
          res = await auth.register(this.loginAccount, this.loginPassword);
        }
      } else {
        res = this.isRegisterMode
          ? await auth.register(this.loginAccount.trim(), this.loginPassword.trim())
          : await auth.login(this.loginAccount.trim(), this.loginPassword.trim());
      }

      if (!res.ok) {
        this.loginError = res.message ?? '操作失败';
        this.isLoading = false;
        return;
      }

      if (res.profile) {
        // 【核心修改】登录成功后，更新全局状态，UI 会自动切换到 Tab 页
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

  build() {
    Column() {
      if (!this.initialized) {
        Column() {
          Text('资源加载中...').fontSize(16).fontColor('#666666');
        }
        .width('100%').height('100%')
        .justifyContent(FlexAlign.Center);
      } else if (!this.account) {
        // 没有账号时，强制显示登录页
        this.renderLogin();
      } else {
        // 有账号时，显示主界面
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
        Column() {
          Text('账号').fontSize(14).fontColor('#333333').alignSelf(ItemAlign.Start).margin({ bottom: 8 });
          TextInput({ placeholder: '请输入账号', text: this.loginAccount })
            .width('100%').height(48)
            .backgroundColor('#f8f8f8').borderRadius(8)
            .padding({ left: 12, right: 12 })
            .onChange(v => { this.loginAccount = v; this.loginError = ''; })
            .enabled(!this.isLoading);
        }.width('100%').margin({ bottom: 20 });

        Column() {
          Text('密码').fontSize(14).fontColor('#333333').alignSelf(ItemAlign.Start).margin({ bottom: 8 });
          TextInput({ placeholder: '请输入密码', text: this.loginPassword })
            .type(InputType.Password)
            .width('100%').height(48)
            .backgroundColor('#f8f8f8').borderRadius(8)
            .padding({ left: 12, right: 12 })
            .showPasswordIcon(true)
            .onChange(v => { this.loginPassword = v; this.loginError = ''; })
            .enabled(!this.isLoading);
        }.width('100%').margin({ bottom: 12 });

        if (this.loginError) {
          Text(this.loginError)
            .fontColor('#ff3333').fontSize(13).width('100%')
            .textAlign(TextAlign.Start).margin({ bottom: 12 });
        }

        Button(this.isLoading ? (this.isRegisterMode ? '处理中...' : '登录中...') : (this.isRegisterMode ? '注册' : '登录'), {
          type: ButtonType.Capsule, stateEffect: true
        })
          .width('100%').height(50)
          .fontSize(16).fontWeight(FontWeight.Medium)
          .enabled(!this.isLoading && this.loginAccount.length > 0 && this.loginPassword.length > 0)
          .onClick(async () => await this.handleLogin());

        Row() {
          Text('忘记密码').fontSize(14).fontColor('#5083ff'); // 简单提示
          Blank();
          Text(this.isRegisterMode ? '已有账号？去登录' : '没有账号？去注册')
            .fontSize(14).fontColor('#5083ff')
            .onClick(() => {
              this.isRegisterMode = !this.isRegisterMode;
              this.loginError = '';
            });
        }.width('100%').margin({ top: 20 });
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