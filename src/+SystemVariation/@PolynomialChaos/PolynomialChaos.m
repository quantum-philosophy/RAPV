classdef PolynomialChaos < TemperatureVariation.PolynomialChaos & ...
  SystemVariation.Base

  methods
    function this = PolynomialChaos(varargin)
      options = Options(varargin{:});
      this = this@TemperatureVariation.PolynomialChaos(options);
      this = this@SystemVariation.Base(options);
    end

    function output = compute(this, Pdyn, varargin)
      T = this.temperature.computeWithoutLeakage(Pdyn); % cycle template
      [ ~, fatigueOutput ] = this.fatigue.compute(T);

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