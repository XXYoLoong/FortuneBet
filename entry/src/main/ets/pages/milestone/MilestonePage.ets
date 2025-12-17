import { useMilestoneService, useAuthService } from '../../services/ServiceLocator';
import type { Milestone } from '../../common/types';

@Component
export struct MilestonePage {
  @Prop account: string = '';
  @State milestones: Milestone[] = [];
  @State unlockedCount: number = 0;
  @State totalCoins: number = 0;
  @State isLoading: boolean = false;

  async aboutToAppear(): Promise<void> {
    await this.loadMilestones();
  }

  onPageShow(): void {
    // 页面显示时刷新里程碑数据
    this.loadMilestones();
  }

  private async loadMilestones(): Promise<void> {
    this.isLoading = true;
    try {
      const svc = useMilestoneService();
      this.milestones = await svc.getUserMilestones(this.account);
      this.unlockedCount = await svc.getUnlockedCount(this.account);
      
      const auth = useAuthService();
      const profile = await auth.currentUser();
      this.totalCoins = profile?.totalCoins ?? 0;
    } catch (e) {
      const error = e instanceof Error ? e : new Error(String(e));
      console.error('加载里程碑失败:', error.message);
    } finally {
      this.isLoading = false;
    }
  }

  private getProgress(milestone: Milestone): number {
    if (milestone.unlocked) return 100;
    if (this.totalCoins >= milestone.threshold) return 100;
    return (this.totalCoins / milestone.threshold) * 100;
  }

  private getRemaining(milestone: Milestone): number {
    if (milestone.unlocked) return 0;
    return Math.max(0, milestone.threshold - this.totalCoins);
  }

  build() {
    Column() {
      // 头部统计
      Column() {
        Row() {
          Column() {
            Text('里程碑')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#ffffff');
            Text(`已解锁 ${this.unlockedCount}/${this.milestones.length}`)
              .fontSize(14)
              .fontColor('#a0a0a0')
              .margin({ top: 6 });
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1);
          
          Column() {
            Text(`${this.totalCoins}`)
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#4ecdc4');
            Text('累计游戏币')
              .fontSize(12)
              .fontColor('#888888')
              .margin({ top: 4 });
          }
          .alignItems(HorizontalAlign.End);
        }
        .width('100%');
      }
      .padding(20)
      .width('100%')
      .backgroundColor('#15182e')
      .borderRadius(16)
      .margin({ top: 16, bottom: 16, left: 16, right: 16 });
      
      // 里程碑列表
      if (this.isLoading) {
        Column() {
          Text('加载中...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 50 });
        }
        .width('100%')
        .layoutWeight(1);
      } else if (this.milestones.length === 0) {
        Column() {
          Text('暂无里程碑数据')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 50 });
        }
        .width('100%')
        .layoutWeight(1);
      } else {
        List() {
          ForEach(this.milestones, (milestone: Milestone) => {
          ListItem() {
            Column() {
              Row() {
                Column() {
                  Row() {
                    Text(milestone.title)
                      .fontSize(18)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(milestone.unlocked ? '#4ecdc4' : '#ffffff');
                    if (milestone.unlocked) {
                      Text(' ✓')
                        .fontSize(18)
                        .fontColor('#4ecdc4')
                        .fontWeight(FontWeight.Bold);
                    }
                  }
                  .width('100%')
                  .margin({ bottom: 8 });
                  
                  if (milestone.description) {
                    Text(milestone.description)
                      .fontSize(13)
                      .fontColor('#888888')
                      .margin({ bottom: 12 });
                  }
                  
                  // 进度条
                  Column() {
                    Row() {
                      Text(`${this.totalCoins}/${milestone.threshold}`)
                        .fontSize(12)
                        .fontColor(milestone.unlocked ? '#4ecdc4' : '#a0a0a0');
                      Blank();
                      Text(milestone.unlocked ? '已达成' : `还需 ${this.getRemaining(milestone)}`)
                        .fontSize(12)
                        .fontColor(milestone.unlocked ? '#4ecdc4' : '#ff6b6b');
                    }
                    .width('100%')
                    .margin({ bottom: 8 });
                    
                    // 进度条
                    Stack() {
                      // 背景
                      Row()
                        .width('100%')
                        .height(8)
                        .backgroundColor('#1a1f3a')
                        .borderRadius(4);
                      
                      // 进度
                      Row()
                        .width(`${this.getProgress(milestone)}%`)
                        .height(8)
                        .backgroundColor(milestone.unlocked ? '#4ecdc4' : '#e04542')
                        .borderRadius(4);
                    }
                    .width('100%')
                    .height(8);
                  }
                  .width('100%');
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1);
              }
              .width('100%');
            }
            .width('100%')
            .padding(20)
            .backgroundColor(milestone.unlocked ? '#1a2e2e' : '#15182e')
            .borderRadius(16)
            .border({
              width: milestone.unlocked ? 1 : 0,
              color: '#4ecdc4'
            });
          }
        }, (milestone: Milestone) => milestone.id.toString())
        }
        .layoutWeight(1)
        .padding({ left: 16, right: 16 });
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0a0e27');
  }
}
