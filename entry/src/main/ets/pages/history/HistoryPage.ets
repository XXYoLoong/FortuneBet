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
import { GameRound } from '../../common/types';
import { useHistoryService } from '../../services/ServiceLocator';
import { HistoryService } from '../../services/HistoryService';

@Component
export struct HistoryPage {
  @Prop account: string = '';
  @State rounds: GameRound[] = [];
  @State isLoading: boolean = false;

  async aboutToAppear(): Promise<void> {
    await this.loadHistory();
  }

  // 关键：页面显示时重新加载，实现实时更新
  onPageShow(): void {
    this.loadHistory();
  }

  private async loadHistory(): Promise<void> {
    if (!this.account) return;
    this.isLoading = true;
    try {
      const historyService: HistoryService = useHistoryService();
      // 获取最新记录
      this.rounds = await historyService.listRounds(this.account);
    } catch (e) {
      console.error('History load failed');
    } finally {
      this.isLoading = false;
    }
  }

  private formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    const m = (date.getMonth() + 1).toString().padStart(2, '0');
    const d = date.getDate().toString().padStart(2, '0');
    const h = date.getHours().toString().padStart(2, '0');
    const min = date.getMinutes().toString().padStart(2, '0');
    const s = date.getSeconds().toString().padStart(2, '0');
    return `${m}-${d} ${h}:${min}:${s}`;
  }

  build() {
    Column() {
      Text('战绩记录')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#ffffff')
        .margin({ top: 16, bottom: 16 });

      if (this.isLoading) {
        Text('数据同步中...').fontColor('#999999').margin({ top: 50 });
      } else if (this.rounds.length === 0) {
        Column() {
          Text('暂无游戏记录').fontSize(16).fontColor('#666666').margin({ bottom: 8 });
          Text('好运正在等着你！').fontSize(14).fontColor('#444444');
        }.margin({ top: 100 });
      } else {
        List() {
          ForEach(this.rounds, (item: GameRound) => {
            ListItem() {
              this.renderHistoryItem(item);
            }
          }, (item: GameRound) => item.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, bottom: 20 });
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0a0e27');
  }

  @Builder
  private renderHistoryItem(item: GameRound) {
    Row() {
      // 左侧：轮次信息
      Column() {
        Text(`第 ${item.roundNumber} 局`)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
          .margin({ bottom: 4 });
        Text(this.formatDate(item.createdAt))
          .fontSize(11)
          .fontColor('#888888');
      }
      .alignItems(HorizontalAlign.Start);

      Blank();

      // 中间：开奖结果
      Column() {
        Text('开奖')
          .fontSize(10)
          .fontColor('#666666')
          .margin({ bottom: 2 });
        Text(`${item.resultValue}x`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffd700'); // 金色强调结果
      }
      .margin({ right: 24 });

      // 右侧：盈亏展示
      Column() {
        Text((item.coinsEarned > 0 ? `+${item.coinsEarned}` : `-${item.coinsUsed}`))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(item.coinsEarned > 0 ? '#4ecdc4' : '#ff6b6b');
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#15182e')
    .borderRadius(12)
    .margin({ bottom: 10 });
  }
}