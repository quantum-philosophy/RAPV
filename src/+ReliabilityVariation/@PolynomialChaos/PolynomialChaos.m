classdef PolynomialChaos < TemperatureVariation.PolynomialChaos & ...
    ReliabilityVariation.Base

  methods
    function this = PolynomialChaos(varargin)
      options = Options(varargin{:});
      this = this@TemperatureVariation.PolynomialChaos(options);
      this = this@ReliabilityVariation.Base(options);
    end

    function output = compute(this, Pdyn)
      T = this.temperature.computeWithoutLeakage(Pdyn); % cycle template
      [ ~, fatigueOutput ] = this.fatigue.compute(T);

      output = this.surrogate.construct( ...
        @(rvs) this.surve(Pdyn, rvs, fatigueOutput));

      output.T = T;
      output.fatigueOutput = fatigueOutput;
    end
  end

  methods (Access = 'protected')
    function result = surve(this, Pdyn, rvs, fatigueOutput)
      parameters = this.process.partition(rvs);
      parameters = this.process.evaluate(parameters);
      parameters = this.process.assign(parameters);

      T = this.temperature.computeWithLeakage(Pdyn, parameters);
      result = transpose(this.fatigue.compute(T, fatigueOutput));
    end

    function result = postprocess(~, ~, result)
      %
      % Do nothing
      %
    end
  end
end
