import type { GameRound, UserProfile } from '../../common/types';
import { useAuthService, useHistoryService } from '../../services/ServiceLocator';
import { ensureStorage, StorageService } from '../../services/StorageService';

@Component
export struct ProfilePage {
  @Prop account: string = '';
  @State profile: UserProfile | undefined = undefined;
  @State rounds: GameRound[] = [];
  @State isEditing: boolean = false;
  @State editNickname: string = '';
  @State editQuote: string = '';
  @State editGameName: string = '';
  private storage?: StorageService;

  async aboutToAppear(): Promise<void> {
    this.storage = await ensureStorage(getContext(this));
    await this.ensureProfile();
    await this.loadRounds();
  }

  // 确保每次进入页面，数据和图表都是最新的
  onPageShow(): void {
    this.ensureProfile();
    this.loadRounds();
  }

  private async ensureProfile(): Promise<void> {
    const auth = useAuthService();
    const user = await auth.currentUser();
    if (user) {
      this.profile = user;
      this.editNickname = user.nickname ?? '';
      this.editQuote = user.quote ?? '';
      this.editGameName = user.gameName ?? '';
    }
  }

  private async loadRounds(): Promise<void> {
    if (!this.profile) return;
    const historySvc = useHistoryService();
    this.rounds = await historySvc.listRounds(this.profile.account);
  }

  private async saveProfile(): Promise<void> {
    if (!this.profile || !this.storage) return;
    this.profile.nickname = this.editNickname.trim() || undefined;
    this.profile.quote = this.editQuote.trim() || undefined;
    this.profile.gameName = this.editGameName.trim() || undefined;

    await this.storage.saveUser(this.profile);

    this.isEditing = false;
    await this.loadRounds();
  }

  private getRecentRounds(): GameRound[] {
    // 获取最新的10条，但为了画图的时间轴从左到右，我们需要把时间倒回去
    const recent = this.rounds.slice(0, 10);
    return recent.reverse();
  }

  // 计算图表最大值，用于归一化高度
  private getMaxBalance(rounds: GameRound[]): number {
    let max = 100; // 默认基准高度
    rounds.forEach(r => {
      const bal = r.balanceSnapshot ?? 0;
      if (bal > max) max = bal;
    });
    return max;
  }

  build() {
    Column() {
      if (this.profile) {
        Scroll() {
          Column() {
            this.renderUserInfo();
            this.renderChart();
            this.renderAbout();
          }
          .padding({ left: 16, right: 16, top: 16, bottom: 32 })
        }
        .scrollBar(BarState.Off)
      } else {
        Column() {
          Text('加载用户信息...').fontSize(14).fontColor('#999999');
        }
        .width('100%').height('100%').justifyContent(FlexAlign.Center);
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0a0e27');
  }

  @Builder
  private renderUserInfo() {
    Column() {
      Row() {
        Column() {
          Text(this.profile!.nickname || this.profile!.account)
            .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#ffffff');
          Text(`账号: ${this.profile!.account}`)
            .fontSize(13).fontColor('#a0a0a0').margin({ top: 6 });

          // 个性签名展示
          if (this.profile!.quote) {
            Text(`"${this.profile!.quote}"`)
              .fontSize(14).fontColor('#888888').fontStyle(FontStyle.Italic).margin({ top: 12 });
          }
          // 游戏名展示
          if (this.profile!.gameName) {
            Text(`游戏绑定名: ${this.profile!.gameName}`)
              .fontSize(13).fontColor('#a0a0a0').margin({ top: 6 });
          }
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1);

        Button(this.isEditing ? '保存' : '编辑')
          .type(ButtonType.Normal).fontSize(14).fontColor('#ffffff').backgroundColor('#1a1f3a')
          .onClick(async () => {
            if (this.isEditing) {
              await this.saveProfile();
            } else {
              this.isEditing = true;
            }
          });
      }.width('100%');

      // 编辑模式下的输入框
      if (this.isEditing) {
        Column() {
          TextInput({ placeholder: '昵称', text: this.editNickname })
            .width('100%').height(44).backgroundColor('#1a1f3a').fontColor('#ffffff').margin({ top: 12 })
            .onChange((val) => this.editNickname = val);

          TextInput({ placeholder: '个性语录', text: this.editQuote })
            .width('100%').height(44).backgroundColor('#1a1f3a').fontColor('#ffffff').margin({ top: 12 })
            .onChange((val) => this.editQuote = val);

          TextInput({ placeholder: '游戏绑定名', text: this.editGameName })
            .width('100%').height(44).backgroundColor('#1a1f3a').fontColor('#ffffff').margin({ top: 12 })
            .onChange((val) => this.editGameName = val);
        }.margin({ top: 16 });
      }
    }
    .padding(20).width('100%').backgroundColor('#15182e').borderRadius(16).margin({ bottom: 16 });
  }

  @Builder
  private renderChart() {
    Column() {
      Text('资产走势 (最近10局)')
        .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#ffffff').margin({ bottom: 16 });

      if (this.rounds.length === 0) {
        Text('暂无数据，完成游戏后显示趋势图')
          .fontSize(14).fontColor('#666666').height(200).textAlign(TextAlign.Center);
      } else {
        this.renderChartContent();
      }
    }
    .padding(20).width('100%').backgroundColor('#15182e').borderRadius(16).margin({ bottom: 16 });
  }

  @Builder
  private renderChartContent() {
    Column() {
      // 柱状图区域
      Row() {
        ForEach(this.getRecentRounds(), (round: GameRound) => {
          Column() {
            // 显示该局结束后的余额数值
            Text(`${round.balanceSnapshot ?? 0}`)
              .fontSize(9).fontColor('#a0a0a0').margin({ bottom: 2 });

            // 柱子 (高度基于余额)
            // 赢了(coinsEarned > 0)显示亮色，输了显示暗色
            Column()
              .width(12)
              .height(`${Math.max(10, (round.balanceSnapshot ?? 0) / this.getMaxBalance(this.getRecentRounds()) * 100)}%`)
              .backgroundColor(round.coinsEarned > 0 ? '#4ecdc4' : '#666666')
              .borderRadius({ topLeft: 4, topRight: 4 });
          }
          .height('100%')
          .justifyContent(FlexAlign.End) // 底部对齐
        }, (round: GameRound) => round.id)
      }
      .width('100%')
      .height(150)
      .justifyContent(FlexAlign.SpaceBetween) // 在水平方向上均匀分布
      .alignItems(VerticalAlign.Bottom);

      // 底部装饰线
      Divider().color('#333333').margin({ top: 0, bottom: 8 });

      Text('时间推移 ->')
        .fontSize(10).fontColor('#444444').width('100%').textAlign(TextAlign.End);
    }
    .width('100%');
  }

  @Builder
  private renderAbout() {
    Column() {
      Text('当前资产').fontSize(14).fontColor('#a0a0a0').margin({ bottom: 8 });
      // 大号字体显示当前余额
      Text(`${this.profile?.balance ?? 0}`)
        .fontSize(32).fontWeight(FontWeight.Bold).fontColor('#ffd700').margin({ bottom: 24 });

      Row() {
        Text('累计总盈亏').fontSize(14).fontColor('#a0a0a0');
        Blank();
        // 根据正负显示颜色
        Text(`${(this.profile?.totalCoins ?? 0) > 0 ? '+' : ''}${this.profile?.totalCoins ?? 0}`)
          .fontSize(16).fontColor((this.profile?.totalCoins ?? 0) >= 0 ? '#4ecdc4' : '#ff6b6b');
      }.width('100%');

      Divider().color('#333333').margin({ top: 16, bottom: 16 });

      Text('Version 1.0.2 Beta').fontSize(12).fontColor('#444444').alignSelf(ItemAlign.Center);
    }
    .padding(20).width('100%').backgroundColor('#15182e').borderRadius(16);
  }
}