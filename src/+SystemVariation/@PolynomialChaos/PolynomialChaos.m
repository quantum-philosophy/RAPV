classdef PolynomialChaos < TemperatureVariation.PolynomialChaos & ...
  SystemVariation.Base

  methods
    function this = PolynomialChaos(varargin)
      options = Options(varargin{:});
      this = this@TemperatureVariation.PolynomialChaos(options);
      this = this@SystemVariation.Base(options);
    end

    function output = compute(this, Pdyn, varargin)
      %
      % NOTE: This profile is used to obtain a "thermal-cycling template."
      % It is also used as the initial temperature of further solves.
      %
      T = this.temperature.computeWithLeakage(Pdyn, struct, ...
        'algorithm', 'condensedEquationSingle', 'errorMetric', 'NRMSE', ...
        'errorThreshold', 0.01, 'iterationLimit', 10);

      [ ~, fatigueOutput ] = this.fatigue.compute(T);
      fatigueOutput.T = T;

      output = this.surrogate.construct( ...
        @(rvs) this.serve(Pdyn, rvs, fatigueOutput));

      output.T = T;
      output.fatigueOutput = fatigueOutput;

      options = Options(varargin{:});
      output.raw = options.get('raw', false);
    end

    function stats = analyze(this, output)
      if output.raw
        stats = this.surrogate.analyze(output);
      else
        stats.expectation = [];
        stats.variance = [];
      end
    end

    function data = sample(this, output, sampleCount)
      data = sample@TemperatureVariation.PolynomialChaos( ...
        this, output, sampleCount);
      if output.raw
        data = this.encode(data);
      end
    end
  end

  methods (Access = 'protected')
    function data = postprocess(this, ~, data)
      data = this.decode(data);
    end
  end
end