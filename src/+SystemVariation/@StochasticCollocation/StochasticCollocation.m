classdef StochasticCollocation < TemperatureVariation.StochasticCollocation & ...
  SystemVariation.Base

  methods
    function this = StochasticCollocation(varargin)
      options = Options(varargin{:});
      this = this@TemperatureVariation.StochasticCollocation(options);
      this = this@SystemVariation.Base(options);
    end

    function output = compute(this, Pdyn)
      T = this.temperature.computeWithLeakage(Pdyn, struct, ...
        'algorithm', 'condensedEquationSingle', 'errorMetric', 'NRMSE', ...
        'errorThreshold', 0.01, 'iterationLimit', 10);
      [ ~, fatigueOutput ] = this.fatigue.compute(T);
      fatigueOutput.T = T;

      output = this.surrogate.construct( ...
        @(rvs) this.serve(Pdyn, this.preprocess(rvs), ...
        fatigueOutput, true), this.quantityCount);

      output.T = T;
      output.fatigueOutput = fatigueOutput;
    end

    function stats = analyze(~, ~)
      stats.expectation = [];
      stats.variance = [];
    end
  end

  methods (Access = 'protected')
    function data = postprocess(this, ~, data)
      data = this.decode(data);
    end
  end
end
