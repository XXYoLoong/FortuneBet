import { BET_GRID, ROUND_DURATION_MS } from '../../common/constants';
import type { BetOption, BetTicket, UserProfile, GameRound } from '../../common/types';
import { useHistoryService } from '../../services/ServiceLocator';
import { ensureStorage, StorageService } from '../../services/StorageService';

@Entry
@Component
export struct GamePage {
  @Prop account: string = '';
  @State bets: Map<number, number> = new Map();
  @State countdownMs: number = 0;
  @State isRoundActive: boolean = false;
  @State resultValue: number | undefined = undefined;
  @State winnings: number = 0;
  @State showRules: boolean = false;
  @State showSettleDialog: boolean = false;
  @State balance: number = 0;
  @State profile: UserProfile | undefined = undefined;

  private timer: number = 0;
  private storage?: StorageService;
  private roundStartTime: number = 0;

  async aboutToAppear(): Promise<void> {
    this.storage = await ensureStorage(getContext(this));
    await this.loadData();
    this.startTimer();
  }

  onPageShow(): void {
    this.loadData();
  }

  aboutToDisappear(): void {
    if (this.timer) {
      clearInterval(this.timer);
    }
  }

  private async loadData(): Promise<void> {
    if (!this.storage) return;
    const targetAccount = this.account || await this.storage.getLoginAccount();
    if (!targetAccount) return;

    // 获取数据并处理每日低保
    const user = await this.storage.ensureDailyCoins(targetAccount);
    if (user) {
      this.profile = user;
      this.balance = user.balance ?? 0;
    }
  }

  private startTimer(): void {
    this.timer = setInterval(() => {
      if (this.isRoundActive) {
        const elapsed = Date.now() - this.roundStartTime;
        const remaining = ROUND_DURATION_MS - elapsed;
        this.countdownMs = Math.max(0, remaining);

        if (this.countdownMs === 0 && !this.showSettleDialog) {
          this.handleSettle();
        }
      }
    }, 100);
  }

  private async handleStartRound(): Promise<void> {
    // 开始前再次刷新数据，防止余额不同步
    await this.loadData();
    if (this.balance <= 0) return;

    this.isRoundActive = true;
    this.roundStartTime = Date.now();
    this.countdownMs = ROUND_DURATION_MS;
    this.resultValue = undefined;
    this.winnings = 0;
    this.showSettleDialog = false;
    this.bets = new Map();
  }

  private updateBet(value: number, amount: number): void {
    if (!this.isRoundActive) return;
    if (amount < 0) return;

    const currentBet = this.bets.get(value) || 0;
    const totalBet = this.getTotalBet();
    const newTotal = totalBet - currentBet + amount;

    // 简单的客户端校验，实际扣款在结算
    if (newTotal > this.balance) return;

    if (amount === 0) {
      this.bets.delete(value);
    } else {
      this.bets.set(value, amount);
    }
  }

  private getBetAmount(value: number): number {
    return this.bets.get(value) || 0;
  }

  private getTotalBet(): number {
    let total = 0;
    this.bets.forEach((amount) => total += amount);
    return total;
  }

  private getRemainingCoins(): number {
    return this.balance - this.getTotalBet();
  }

  // 核心结算逻辑
  private async handleSettle(): Promise<void> {
    if (!this.isRoundActive) return;

    this.isRoundActive = false;
    const totalBet = this.getTotalBet();
    const resultValue = this.pickRandomValue();
    this.resultValue = resultValue;

    const betAmount = this.bets.get(resultValue) || 0;
    // 计算奖金 (如果压中)
    this.winnings = betAmount > 0 ? betAmount * resultValue : 0;

    // 数据库操作：扣款与发奖
    if (this.storage) {
      // 1. 扣除本金
      await this.storage.updateBalance(this.account, -totalBet);
      // 2. 发放奖金
      if (this.winnings > 0) {
        await this.storage.updateBalance(this.account, this.winnings);
      }
      // 3. 立即刷新本地内存中的余额，以便存入历史记录
      await this.loadData();
    }

    // 记录历史
    const historySvc = useHistoryService();
    try {
      const roundNumber = await historySvc.getNextRoundNumber(this.account);
      const betsArray: BetTicket[] = [];
      this.bets.forEach((amount, value) => betsArray.push({ value, amount }));

      const round: GameRound = {
        id: `${Date.now()}-${Math.random()}`,
        roundNumber,
        account: this.account,
        coinsUsed: totalBet,
        coinsEarned: this.winnings,
        resultValue,
        bets: betsArray,
        createdAt: Date.now(),
        // 【重要】记录当前这一刻的余额快照
        balanceSnapshot: this.balance
      };
      await historySvc.saveRound(round);
    } catch (e) {
      console.error('保存历史记录失败:', e);
    }

    this.showSettleDialog = true;
  }

  // 加权随机算法
  private pickRandomValue(): number {
    const totalWeight = BET_GRID.reduce((sum, item) => sum + item.weight, 0);
    let random = Math.random() * totalWeight;
    for (const item of BET_GRID) {
      random -= item.weight;
      if (random <= 0) return item.value;
    }
    return BET_GRID[BET_GRID.length - 1].value;
  }

  private async closeSettleDialog(): Promise<void> {
    this.showSettleDialog = false;
    this.resultValue = undefined;
    this.winnings = 0;
    this.bets = new Map();
    // 关闭弹窗后再次确认余额
    await this.loadData();
  }

  private formatCountdown(): string {
    const sec = Math.floor(this.countdownMs / 1000);
    const m = Math.floor(sec / 60).toString().padStart(2, '0');
    const s = (sec % 60).toString().padStart(2, '0');
    return `${m}:${s}`;
  }

  build() {
    Stack() {
      // 底层游戏界面
      Column() {
        this.renderHeader();
        this.renderGameArea();
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#0a0e27');

      // 遮罩层 (用于规则或结算)
      if (this.showSettleDialog || this.showRules) {
        Rect()
          .width('100%')
          .height('100%')
          .fill('#99000000') // 半透明黑背景
          .onClick(() => {
            // 点击空白处关闭规则，但不能关闭结算结果
            if (this.showRules) this.showRules = false;
          })
      }

      // 弹窗层
      if (this.showSettleDialog) {
        this.renderSettleDialog();
      }

      if (this.showRules) {
        this.renderRulesDialog();
      }
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  private renderHeader() {
    Row() {
      Column() {
        Text('鸿运押宝')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff');
        Text(`余额: ${this.balance} 币`)
          .fontSize(13)
          .fontColor('#a0a0a0')
          .margin({ top: 4 });
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1);

      Button('规则')
        .type(ButtonType.Normal)
        .fontSize(13)
        .fontColor('#ffffff')
        .backgroundColor('#1a1f3a')
        .borderRadius(16)
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .onClick(() => this.showRules = true);
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 12, bottom: 12 }) // 顶部留白适配
    .backgroundColor('#15182e');
  }

  @Builder
  private renderGameArea() {
    Column() {
      if (!this.isRoundActive) {
        // --- 待机状态 ---
        Column() {
          Text('准备开始新一轮')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor('#ffffff')
            .margin({ bottom: 40 });

          Button('开始游戏', { type: ButtonType.Capsule })
            .width(240)
            .height(56)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .backgroundColor('#e04542')
            .fontColor('#ffffff')
            .enabled(this.balance > 0)
            .onClick(async () => await this.handleStartRound());

          if (this.balance <= 0) {
            Text('余额不足，系统正在为您补给...')
              .fontSize(12)
              .fontColor('#ff6b6b')
              .margin({ top: 20 });
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1);
      } else {
        // --- 游戏进行中 ---
        Column() {
          // 倒计时区域
          Column() {
            Text('距离开奖仅剩')
              .fontSize(14)
              .fontColor('#a0a0a0')
              .margin({ bottom: 8 });
            Text(this.formatCountdown())
              .fontSize(60)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.countdownMs < 10000 ? '#ff6b6b' : '#4ecdc4');
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#1a1f3a')
          .margin({ bottom: 20 });

          // 下注区 - 使用 List 包裹 Grid 防止小屏溢出
          List() {
            ListItem() {
              Grid() {
                ForEach(BET_GRID, (item: BetOption) => {
                  GridItem() {
                    this.renderBetCard(item);
                  }
                }, (item: BetOption) => item.value.toString())
              }
              .columnsTemplate('1fr 1fr 1fr 1fr')
              .columnsGap(10)
              .rowsGap(10)
              .width('100%')
              .padding({ left: 16, right: 16 });
            }
          }
          .layoutWeight(1);

          // 底部统计栏
          Row() {
            Text(`总下注: ${this.getTotalBet()}`)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#ffffff');
            Blank();
            Text(`剩余: ${this.getRemainingCoins()}`)
              .fontSize(16)
              .fontColor('#a0a0a0');
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 16, bottom: 24 })
          .backgroundColor('#15182e');
        }
        .width('100%')
        .layoutWeight(1);
      }
    }
    .width('100%')
    .layoutWeight(1);
  }

  @Builder
  private renderBetCard(item: BetOption) {
    Column() {
      // 高倍率用金色显示
      Text(`${item.value}x`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(item.value >= 50 ? '#ffd700' : '#ffffff')
        .margin({ bottom: 4 });

      Text(`胜率 ${(item.weight / 10).toFixed(1)}%`)
        .fontSize(10)
        .fontColor('#888888')
        .margin({ bottom: 8 });

      // 输入框
      TextInput({
        placeholder: '0',
        text: this.getBetAmount(item.value) > 0 ? this.getBetAmount(item.value).toString() : ''
      })
        .type(InputType.Number)
        .width('100%')
        .height(32)
        .backgroundColor(this.getBetAmount(item.value) > 0 ? '#ffffff' : '#252a42')
        .borderRadius(6)
        .padding({ left: 0, right: 0 })
        .textAlign(TextAlign.Center)
        .fontSize(14)
        .fontColor('#333333')
        .enabled(this.isRoundActive && this.getRemainingCoins() > 0)
        .onChange((v: string) => {
          const numStr = v.replace(/[^0-9]/g, '');
          const amount = Number.parseInt(numStr) || 0;
          this.updateBet(item.value, amount);
        });
    }
    .width('100%')
    .padding(10)
    .backgroundColor(this.getBetAmount(item.value) > 0 ? '#e04542' : '#1a1f3a')
    .borderRadius(10)
    .border({ width: 1, color: this.getBetAmount(item.value) > 0 ? '#e04542' : '#252a42' });
  }

  @Builder
  private renderSettleDialog() {
    Column() {
      Text(this.winnings > 0 ? '🎉 大获全胜！' : '💔 运气欠佳')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#ffffff')
        .margin({ bottom: 24 });

      Text(`开奖号码: ${this.resultValue}x`)
        .fontSize(40)
        .fontWeight(FontWeight.Bold)
        .fontColor('#ffd700')
        .margin({ bottom: 32 });

      if (this.winnings > 0) {
        Column() {
          Text(`+ ${this.winnings}`)
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4ecdc4')
            .margin({ bottom: 8 });
          Text('赢得游戏币')
            .fontSize(14)
            .fontColor('#a0a0a0')
            .margin({ bottom: 32 });
        }
      } else {
        Column() {
          Text(`- ${this.getTotalBet()}`)
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor('#ff6b6b')
            .margin({ bottom: 8 });
          Text('损失本金')
            .fontSize(14)
            .fontColor('#a0a0a0')
            .margin({ bottom: 32 });
        }
      }

      Button('收入囊中 (返回)')
        .width(200)
        .height(48)
        .backgroundColor('#e04542')
        .fontColor('#ffffff')
        .onClick(async () => await this.closeSettleDialog());
    }
    .width('80%')
    .padding(32)
    .backgroundColor('#1a1f3a')
    .borderRadius(24)
    .shadow({ radius: 20, color: '#aa000000' });
  }

  @Builder
  private renderRulesDialog() {
    Column() {
      Text('游戏规则')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#ffffff')
        .margin({ bottom: 16, top: 8 });

      // 限制高度并允许滑动
      Scroll() {
        Column({ space: 12 }) {
          Text('1. 极速开奖：\n点击开始后，您有1分钟时间进行分析和下注。')
            .fontSize(14).fontColor('#cccccc').lineHeight(20);

          Text('2. 赔率说明：\n表格中的数字（如50x）代表倍率。如果您在"50x"下注100币，且最终开奖为50x，您将获得 100 * 50 = 5000 币！')
            .fontSize(14).fontColor('#cccccc').lineHeight(20);

          Text('3. 风险提示：\n倍率越高（如100x），出现的概率越低；倍率越低（如2x），出现的概率越高。请合理分配您的筹码。')
            .fontSize(14).fontColor('#cccccc').lineHeight(20);

          Text('4. 结算机制：\n倒计时结束后系统自动开奖。若中奖，奖励自动存入余额；若未中奖，扣除下注本金。')
            .fontSize(14).fontColor('#cccccc').lineHeight(20);

          Text('5. 每日福利：\n每日首次登录或余额不足时，系统会自动发放30币低保。')
            .fontSize(14).fontColor('#cccccc').lineHeight(20);

          Text('概率公示：\n100x(0.1%), 50x(0.3%), 30x(0.6%), 20x(1.5%)\n15x(2.5%), 12x(5.0%), 10x(8.0%), 8x(12.0%)\n6x(15.0%), 5x(20.0%), 4x(25.0%), 2x(10.0%)')
            .fontSize(12).fontColor('#666666').margin({ top: 10 });
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 8, right: 8 })
      }
      .height('300vp') // 限制高度
      .scrollBar(BarState.Auto);

      Button('我明白了')
        .width('100%')
        .height(44)
        .margin({ top: 20 })
        .backgroundColor('#e04542')
        .fontColor('#ffffff')
        .onClick(() => this.showRules = false);
    }
    .width('85%')
    .padding(24)
    .backgroundColor('#1a1f3a')
    .borderRadius(20)
    .shadow({ radius: 20, color: '#aa000000' });
  }
}