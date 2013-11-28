classdef MonteCarlo < TemperatureVariation.MonteCarlo & ...
  SystemVariation.Base

  methods
    function this = MonteCarlo(varargin)
      options = Options(varargin{:});
      this = this@TemperatureVariation.MonteCarlo(options);
      this = this@SystemVariation.Base(options);
    end
  end

  methods (Access = 'protected')
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
