import { describe, it, expect } from '@ohos/hypium';
import { ProbabilityPredictor } from '../../src/main/ets/services/ProbabilityPredictor';
import { BET_GRID } from '../../src/main/ets/common/constants';

const predictor = new ProbabilityPredictor(BET_GRID);

export default function probabilityPredictorTest() {
  describe('ProbabilityPredictor', () => {
    it('should sum to 100% weights', () => {
      const total = BET_GRID.reduce((s, v) => s + v.weight, 0);
      expect(total).closeTo(100, 0.5);
    });

    it('simulate distribution close to weights', () => {
      const times = 10000;
      const report = predictor.simulate(times);
      BET_GRID.forEach(opt => {
        const observed = report.distribution.get(opt.value) ?? 0;
        const expected = opt.weight / 100;
        // 允许 1% 误差
        expect(observed).closeTo(expected, 0.01);
      });
    });
  });
}


