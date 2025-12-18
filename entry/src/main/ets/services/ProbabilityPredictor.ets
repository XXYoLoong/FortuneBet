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

import type { BetOption, ProbabilityReport } from '../common/types';

/**
 * 加权概率预测器：核心算法模块，与 UI 解耦。
 * 输入：倍率配置（value/weight）
 * 输出：基于权重的开奖数字 & 分布统计
 */
export class ProbabilityPredictor {
  private readonly options: BetOption[];
  private readonly cumulative: number[];
  private readonly values: number[];
  private readonly totalWeight: number;

  constructor(options: BetOption[]) {
    if (!options || options.length === 0) {
      throw new Error('ProbabilityPredictor options cannot be empty');
    }
    this.options = options;
    this.cumulative = [];
    this.values = [];
    let sum = 0;
    options.forEach(opt => {
      sum += opt.weight;
      this.cumulative.push(sum);
      this.values.push(opt.value);
    });
    this.totalWeight = sum;
  }

  /**
   * 执行一次加权随机开奖。可注入随机函数以便测试。
   */
  pick(randomFn: () => number = Math.random): number {
    const r = randomFn() * this.totalWeight;
    for (let i = 0; i < this.cumulative.length; i++) {
      if (r <= this.cumulative[i]) {
        return this.values[i];
      }
    }
    return this.values[this.values.length - 1];
  }

  /**
   * 批量模拟开奖，返回统计分布。
   */
  simulate(times: number, randomFn: () => number = Math.random): ProbabilityReport {
    if (times <= 0) {
      throw new Error('simulate times must be positive');
    }
    const counts = new Map<number, number>();
    for (let i = 0; i < times; i++) {
      const result = this.pick(randomFn);
      counts.set(result, (counts.get(result) ?? 0) + 1);
    }
    const distribution = new Map<number, number>();
    counts.forEach((cnt, value) => {
      distribution.set(value, cnt / times);
    });
    return { total: times, counts, distribution };
  }
}


