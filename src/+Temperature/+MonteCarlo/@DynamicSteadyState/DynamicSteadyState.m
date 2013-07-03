classdef DynamicSteadyState < Temperature.MonteCarlo.Base
  methods
    function this = DynamicSteadyState(varargin)
      options = Options(varargin{:});
      this = this@Temperature.MonteCarlo.Base(options);
      this.temperature = Temperature.Analytical.DynamicSteadyState( ...
        options.temperatureOptions);
    end
  end
end
