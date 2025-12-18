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
import { common, Want } from '@kit.AbilityKit';
import type { GameRound, UserProfile } from '../../common/types';
import { useAuthService, useHistoryService } from '../../services/ServiceLocator';
import { ensureStorage, StorageService } from '../../services/StorageService';
import { AVATAR_LIST } from '../../common/constants';

// 定义页面枚举，用于简单的页面路由
enum ProfileView {
  MAIN = 0,
  SETTINGS = 1,
  EDIT_PROFILE = 2,
  CHANGE_PASSWORD = 3,
  VERSION = 4,
  LICENSE = 5,
  ABOUT = 6,
  RULES = 7
}

@Component
export struct ProfilePage {
  @Prop account: string = '';
  // 绑定全局账户状态，用于退出登录
  @StorageLink('currentAccount') currentAccount: string = '';

  @State profile: UserProfile | undefined = undefined;
  @State rounds: GameRound[] = [];

  // 页面导航控制
  @State currentView: ProfileView = ProfileView.MAIN;

  // 编辑资料表单
  @State editNickname: string = '';
  @State editQuote: string = '';
  @State editAvatarId: string = 'avatar_default'; // 【新增】编辑时的头像ID

  // 修改密码表单
  @State oldPassword: string = '';
  @State newPassword: string = '';

  // 动画控制
  @State aboutAnimOpacity: number = 0;
  @State aboutAnimTranslateY: number = 50;
  @State aboutAnimTranslateX: number = 50;

  private storage?: StorageService;

  async aboutToAppear(): Promise<void> {
    this.storage = await ensureStorage(getContext(this));
    await this.ensureProfile();
    await this.loadRounds();
  }

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
      // 【新增】初始化编辑头像ID，如果没有则用默认
      this.editAvatarId = user.avatarId ?? 'avatar_default';
    }
  }

  private async loadRounds(): Promise<void> {
    if (!this.profile) return;
    const historySvc = useHistoryService();
    this.rounds = await historySvc.listRounds(this.profile.account);
  }

  // 保存资料
  private async saveProfile(): Promise<void> {
    if (!this.profile || !this.storage) return;
    this.profile.nickname = this.editNickname.trim() || undefined;
    this.profile.quote = this.editQuote.trim() || undefined;
    // 【新增】保存选择的头像ID
    this.profile.avatarId = this.editAvatarId;
    await this.storage.saveUser(this.profile);
    // 返回设置页
    this.currentView = ProfileView.SETTINGS;
  }

  // 修改密码
  private async handleChangePassword(): Promise<void> {
    if (!this.oldPassword || !this.newPassword) return;
    const auth = useAuthService();
    const res = await auth.updatePassword(this.account, this.oldPassword, this.newPassword);
    if (res.ok) {
      // 密码修改成功，返回
      this.oldPassword = '';
      this.newPassword = '';
      this.currentView = ProfileView.SETTINGS;
    } else {
      // 实际开发应弹窗提示，这里简单打日志
      console.error(res.message);
    }
  }

  // 退出登录
  private async handleLogout(): Promise<void> {
    const auth = useAuthService();
    // 清除 Storage 中的登录态
    if (this.storage) {
      await this.storage.setLoginAccount('');
    }
    // 【关键】置空全局状态，Index.ets 会监听到并切换回登录页
    this.currentAccount = '';
  }

  // 打开外部链接
  private openLink(url: string) {
    const context = getContext(this) as common.UIAbilityContext;
    let want: Want = {
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: url
    };
    context.startAbility(want);
  }

  // 播放关于我们入场动画
  private playAboutAnimation() {
    this.aboutAnimOpacity = 0;
    this.aboutAnimTranslateY = 50;
    this.aboutAnimTranslateX = 50;

    animateTo({ duration: 800, curve: Curve.EaseOut }, () => {
      this.aboutAnimOpacity = 1;
      this.aboutAnimTranslateY = 0;
      this.aboutAnimTranslateX = 0;
    });
  }

  // 【新增】辅助函数：根据ID获取图片资源
  private getAvatarResource(avatarId?: string): Resource {
    const id = avatarId ?? 'avatar_default';
    switch (id) {
      case 'avatar_1': return $r('app.media.avatar_1');
      case 'avatar_2': return $r('app.media.avatar_2');
      case 'avatar_3': return $r('app.media.avatar_3');
      case 'avatar_4': return $r('app.media.avatar_4');
      case 'avatar_5': return $r('app.media.avatar_5');
      case 'avatar_6': return $r('app.media.avatar_6');
      case 'avatar_7': return $r('app.media.avatar_7');
      case 'avatar_8': return $r('app.media.avatar_8');
      default: return $r('app.media.avatar_default');
    }
  }

  // ---------------- UI 构建 ----------------

  build() {
    Column() {
      if (this.currentView === ProfileView.MAIN) {
        this.renderMainProfile();
      } else if (this.currentView === ProfileView.SETTINGS) {
        this.renderSettingsPage();
      } else if (this.currentView === ProfileView.EDIT_PROFILE) {
        this.renderEditProfilePage();
      } else if (this.currentView === ProfileView.CHANGE_PASSWORD) {
        this.renderChangePasswordPage();
      } else if (this.currentView === ProfileView.RULES) {
        this.renderRulesPage();
      } else if (this.currentView === ProfileView.VERSION) {
        this.renderVersionPage();
      } else if (this.currentView === ProfileView.LICENSE) {
        this.renderLicensePage();
      } else if (this.currentView === ProfileView.ABOUT) {
        this.renderAboutPage();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0a0e27');
  }

  // --- 1. 主个人中心 ---
  @Builder
  private renderMainProfile() {
    Column() {
      // 顶部栏
      Row() {
        Blank();
        // 设置按钮
        Image($r('app.media.set_icon'))
          .width(24)
          .height(24)
          .fillColor('#ffffff') // 如果是svg图标，可以设置颜色，png则不需要
          .onClick(() => this.currentView = ProfileView.SETTINGS);
      }
      .width('100%')
      .padding({ top: 20, right: 20, bottom: 10 })
      .justifyContent(FlexAlign.End);

      if (this.profile) {
        Scroll() {
          Column() {
            this.renderUserInfo();
            this.renderChart();
          }
          .padding({ left: 16, right: 16, bottom: 32 })
        }
        .scrollBar(BarState.Off)
        .layoutWeight(1);
      }
    }
  }

  // 用户信息卡片 (不可编辑，仅展示)
  @Builder
  private renderUserInfo() {
    Column() {
      Row() {
        // 【修改】使用 Image 展示头像，替代原来的 Circle
        Image(this.getAvatarResource(this.profile?.avatarId))
          .width(64)
          .height(64)
          .borderRadius(32) // 圆形头像
          .margin({ right: 16 })
          .border({ width: 2, color: '#1a1f3a' }); // 加个边框更有质感

        Column() {
          Text(this.profile!.nickname || `玩家 ${this.profile!.account}`)
            .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#ffffff');
          Text(`账号: ${this.profile!.account}`)
            .fontSize(13).fontColor('#a0a0a0').margin({ top: 6 });

          if (this.profile!.quote) {
            Text(`"${this.profile!.quote}"`)
              .fontSize(14).fontColor('#888888').fontStyle(FontStyle.Italic).margin({ top: 8 });
          }
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1);
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#15182e')
      .borderRadius(16)
      .margin({ bottom: 16 });
    }
  }

  // 资产走势图 (逻辑与之前一致)
  @Builder
  private renderChart() {
    Column() {
      Text('资产走势 (最近10局)').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#ffffff').margin({ bottom: 16 });
      if (this.rounds.length === 0) {
        Text('暂无数据').fontSize(14).fontColor('#666666').height(200).textAlign(TextAlign.Center);
      } else {
        this.renderChartContent();
      }
    }
    .padding(20).width('100%').backgroundColor('#15182e').borderRadius(16);
  }

  // 图表内容绘制
  @Builder
  private renderChartContent() {
    Column() {
      Row() {
        ForEach(this.getRecentRounds(), (round: GameRound) => {
          Column() {
            Text(`${round.balanceSnapshot ?? 0}`).fontSize(9).fontColor('#a0a0a0').margin({ bottom: 2 });
            Column()
              .width(12)
              .height(`${Math.max(10, (round.balanceSnapshot ?? 0) / this.getMaxBalance(this.getRecentRounds()) * 100)}%`)
              .backgroundColor(round.coinsEarned > 0 ? '#4ecdc4' : '#666666')
              .borderRadius({ topLeft: 4, topRight: 4 });
          }
          .height('100%')
          .justifyContent(FlexAlign.End)
        }, (round: GameRound) => round.id)
      }
      .width('100%').height(150).justifyContent(FlexAlign.SpaceBetween).alignItems(VerticalAlign.Bottom);
    }.width('100%');
  }

  // --- 2. 设置页面 ---
  @Builder
  private renderSettingsPage() {
    Column() {
      // 1. 渲染顶部栏（现在它在文档流中，会占据空间）
      this.renderBackHeader('设置', () => this.currentView = ProfileView.MAIN);

      // 2. 渲染设置列表，并使用 layoutWeight(1) 让其占满剩余空间
      // 使用 Scroll 包裹，防止小屏幕内容溢出
      Scroll() {
        Column({ space: 12 }) {
          this.renderSettingItem('修改资料', () => {
            this.editNickname = this.profile?.nickname ?? '';
            this.editQuote = this.profile?.quote ?? '';
            this.currentView = ProfileView.EDIT_PROFILE;
          });

          this.renderSettingItem('修改密码', () => {
            this.oldPassword = '';
            this.newPassword = '';
            this.currentView = ProfileView.CHANGE_PASSWORD;
          });

          this.renderSettingItem('游戏规则', () => this.currentView = ProfileView.RULES);

          this.renderSettingItem('版本信息', () => this.currentView = ProfileView.VERSION);

          this.renderSettingItem('开源协议', () => this.currentView = ProfileView.LICENSE);

          this.renderSettingItem('关于我们', () => {
            this.currentView = ProfileView.ABOUT;
            this.playAboutAnimation();
          });

          Button('退出登录')
            .width('100%')
            .height(50)
            .backgroundColor('#ff6b6b')
            .margin({ top: 32 })
            .onClick(() => this.handleLogout());
        }
        .padding({ left: 20, right: 20, top: 20, bottom: 32 }) // 调整 padding
      }
      .layoutWeight(1) // 占满剩余空间
      .scrollBar(BarState.Auto)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%') // 确保占满全屏
  }

  @Builder
  private renderSettingItem(title: string, onClick: () => void) {
    Row() {
      Text(title).fontSize(16).fontColor('#ffffff');
      Blank();
      Text('›').fontSize(20).fontColor('#666666');
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#15182e')
    .borderRadius(12)
    .onClick(onClick);
  }

  // --- 3. 编辑资料页面 ---
  @Builder
  private renderEditProfilePage() {
    Column() {
      this.renderBackHeader('修改资料', () => this.currentView = ProfileView.SETTINGS);
      Scroll(){
      Column({ space: 20 }) {
        Column() {
          Text('选择头像').fontSize(14).fontColor('#a0a0a0').margin({ bottom: 12 }).width('100%');
          Grid() {
            ForEach(AVATAR_LIST, (id: string) => {
              GridItem() {
                Stack({ alignContent: Alignment.BottomEnd }) {
                  Image(this.getAvatarResource(id))
                    .width(60)
                    .height(60)
                    .borderRadius(30)
                    // 选中高亮边框
                    .border({ width: this.editAvatarId === id ? 3 : 0, color: '#4ecdc4' })
                    .onClick(() => this.editAvatarId = id);

                  // 选中时显示一个小对勾图标
                  if (this.editAvatarId === id) {
                    Image($r('app.media.startIcon')) // 这里用 app_icon 代替对勾，你可以换成专门的 icon
                      .width(16).height(16)
                      .borderRadius(8).backgroundColor('#4ecdc4').padding(2)
                      .fillColor('#ffffff')
                      .margin({ bottom: 2, right: 2 })
                  }
                }
              }
            }, (id: string) => id)
          }
          .columnsTemplate('1fr 1fr 1fr 1fr') // 4列布局
          .rowsGap(12)
          .columnsGap(12)
          .width('100%')
          .height(140); // 固定 Grid 高度
        }

        TextInput({ placeholder: '昵称', text: this.editNickname })
          .height(48).backgroundColor('#1a1f3a').fontColor('#ffffff').borderRadius(8)
          .onChange(v => this.editNickname = v);

        TextInput({ placeholder: '个性签名', text: this.editQuote })
          .height(48).backgroundColor('#1a1f3a').fontColor('#ffffff').borderRadius(8)
          .onChange(v => this.editQuote = v);

        Button('保存')
          .width('100%').height(48).backgroundColor('#e04542')
          .onClick(() => this.saveProfile());
      }.padding(20);
    }.layoutWeight(1).width('100%');
  }
}
  // --- 4. 修改密码页面 ---
  @Builder
  private renderChangePasswordPage() {
    Column() {
      this.renderBackHeader('修改密码', () => this.currentView = ProfileView.SETTINGS);
      Column({ space: 20 }) {
        TextInput({ placeholder: '旧密码', text: this.oldPassword })
          .type(InputType.Password)
          .height(48).backgroundColor('#1a1f3a').fontColor('#ffffff').borderRadius(8)
          .onChange(v => this.oldPassword = v);

        TextInput({ placeholder: '新密码', text: this.newPassword })
          .type(InputType.Password)
          .height(48).backgroundColor('#1a1f3a').fontColor('#ffffff').borderRadius(8)
          .onChange(v => this.newPassword = v);

        Button('确认修改')
          .width('100%').height(48).backgroundColor('#e04542')
          .enabled(this.oldPassword.length > 0 && this.newPassword.length >= 6)
          .onClick(() => this.handleChangePassword());
      }.padding(20);
    }
  }

  // --- 5. 规则页面 (复用) ---
  @Builder
  private renderRulesPage() {
    Column() {
      this.renderBackHeader('游戏规则', () => this.currentView = ProfileView.SETTINGS);
      Scroll() {
        Column({ space: 16 }) {
          Text('1. 极速开奖：\n点击开始后，您有1分钟时间进行分析和下注。')
            .fontSize(14).fontColor('#cccccc').lineHeight(20);
          Text('2. 赔率说明：\n表格中的数字（如50x）代表倍率。如果您在"50x"下注100币，且最终开奖为50x，您将获得 100 * 50 = 5000 币！')
            .fontSize(14).fontColor('#cccccc').lineHeight(20);
          Text('3. 风险提示：\n倍率越高（如100x），出现的概率越低；倍率越低（如2x），出现的概率越高。请合理分配您的筹码。')
            .fontSize(14).fontColor('#cccccc').lineHeight(20);
          Text('4. 每日福利：\n每日首次登录或余额不足时，系统会自动发放30币低保。')
            .fontSize(14).fontColor('#cccccc').lineHeight(20);
        }.padding(20).alignItems(HorizontalAlign.Start);
      }
    }
  }

  // --- 6. 版本信息 ---
  @Builder
  private renderVersionPage() {
    Column() {
      this.renderBackHeader('版本信息', () => this.currentView = ProfileView.SETTINGS);
      Column() {
        // 确保你有一个 app_icon 在 resources/base/media 中，否则删除此 Image
        Image($r('app.media.startIcon'))
          .width(80).height(80).margin({ bottom: 16 }).fillColor('#e04542');
        Text('鸿运押宝')
          .fontSize(24).fontWeight(FontWeight.Bold).fontColor('#ffffff').margin({ bottom: 8 });
        Text('Version 1.0.2 Beta')
          .fontSize(16).fontColor('#a0a0a0').margin({ bottom: 32 });

        Text('内测版本，仅供学习交流使用')
          .fontSize(14).fontColor('#666666');
      }
      .width('100%').height('80%').justifyContent(FlexAlign.Center);
    }
  }

  // --- 7. 开源协议 ---
  @Builder
  private renderLicensePage() {
    Column() {
      this.renderBackHeader('开源协议', () => this.currentView = ProfileView.SETTINGS);
      Scroll() {
        Column({ space: 10 }) {
          Text('Copyright 2025 Jiacheng Ni')
            .fontSize(14).fontColor('#ffffff').fontWeight(FontWeight.Bold);

          Text('Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at')
            .fontSize(13).fontColor('#cccccc').lineHeight(20);

          Text('http://www.apache.org/licenses/LICENSE-2.0')
            .fontSize(13).fontColor('#5083ff').lineHeight(20)
            .onClick(() => this.openLink('http://www.apache.org/licenses/LICENSE-2.0'));

          Text('Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.')
            .fontSize(13).fontColor('#cccccc').lineHeight(20);
        }
        .padding(20).alignItems(HorizontalAlign.Start);
      }
    }
  }

  // --- 8. 关于我们 (炫酷动画) ---
  @Builder
  private renderAboutPage() {
    //Stack() {
      // 背景层
      //Column().width('100%').height('100%').backgroundColor('#0a0e27');

      this.renderBackHeader('关于我们', () => this.currentView = ProfileView.SETTINGS);

      // 内容层
      Column() {
        Row() {
          // 右列：既见游龙
          Text('既\n见\n游\n龙')
            .fontSize(40)
            .fontWeight(FontWeight.Bold)
            .fontColor('#e04542')
            .lineHeight(60)
            .margin({ right: 30 })
            .opacity(this.aboutAnimOpacity)

          // 左列：为何不拜
          Text('为\n何\n不\n拜')
            .fontSize(40)
            .fontWeight(FontWeight.Bold)
            .fontColor('#ffffff')
            .lineHeight(60)
            .opacity(this.aboutAnimOpacity)
        }
        .margin({ top: 150 })
        .translate({ x: this.aboutAnimTranslateX, y: this.aboutAnimTranslateY });

        //Blank();
        //这里没有修改好捏
        // Text('小小游龙')
        //   .fontSize(14)
        //   .fontColor('#5083ff')
        //   .margin({ bottom: 40 })
        //   .onClick(() => this.openLink('https://github.com/XXYoLoong'));
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center);
    //}
  }


  // 通用顶部返回栏
  @Builder
  private renderBackHeader(title: string, onBack: () => void) {
    Row() {
      Text('< 返回')
        .fontSize(16).fontColor('#ffffff')
        .onClick(onBack);

      Text(title)
        .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#ffffff')
        .margin({ left: 20 });

      Blank();
    }
    .width('100%')
    .height(56) // 固定高度 56
    .padding({ left: 16, right: 16 })
    .backgroundColor('#15182e'); // 恢复背景色，使其不透明
    // 【重要】移除 position, zIndex 和 backgroundColor('transparent')
  }

  // 辅助函数
  private getRecentRounds(): GameRound[] {
    const recent = this.rounds.slice(0, 10);
    return recent.reverse();
  }

  private getMaxBalance(rounds: GameRound[]): number {
    let max = 100;
    rounds.forEach(r => {
      const bal = r.balanceSnapshot ?? 0;
      if (bal > max) max = bal;
    });
    return max;
  }
}