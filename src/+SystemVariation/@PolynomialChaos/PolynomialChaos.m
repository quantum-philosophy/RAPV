classdef PolynomialChaos < TemperatureVariation.PolynomialChaos & ...
  SystemVariation.Base

  methods
    function this = PolynomialChaos(varargin)
      options = Options(varargin{:});
      this = this@TemperatureVariation.PolynomialChaos(options);
      this = this@SystemVariation.Base(options);
    end

    function output = compute(this, Pdyn)
      T = this.temperature.computeWithoutLeakage(Pdyn); % cycle template
      [ ~, fatigueOutput ] = this.fatigue.compute(T);

      output = this.surrogate.construct( ...
        @(rvs) this.serve(Pdyn, rvs, fatigueOutput));

      output.T = T;
      output.fatigueOutput = fatigueOutput;
    end
  end
end
