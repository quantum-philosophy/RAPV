classdef MonteCarlo < TemperatureVariation.MonteCarlo & ...
    ReliabilityVariation.Base

  methods
    function this = MonteCarlo(varargin)
      options = Options(varargin{:});
      this = this@TemperatureVariation.MonteCarlo(options);
      this = this@ReliabilityVariation.Base(options);
    end
  end

  methods (Access = 'protected')
    function result = serve(this, Pdyn, rvs, fatigueOutput)
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

    function output = simulate(this, Pdyn)
      T = this.temperature.computeWithoutLeakage(Pdyn); % cycle template
      [ ~, fatigueOutput ] = this.fatigue.compute(T);

      output = this.surrogate.construct( ...
        @(rvs) this.serve(Pdyn, rvs, fatigueOutput));

      output.T = T;
      output.fatigueOutput = fatigueOutput;
    end
  end
end
