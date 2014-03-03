classdef MonteCarlo < TemperatureVariation.MonteCarlo & ...
  SystemVariation.Base

  methods
    function this = MonteCarlo(varargin)
      options = Options(varargin{:});
      this = this@TemperatureVariation.MonteCarlo(options);
      this = this@SystemVariation.Base(options);
    end

    function output = compute(this, Pdyn, varargin)
      output = compute@TemperatureVariation.MonteCarlo(this, Pdyn);
      options = Options(varargin{:});
      if options.get('raw', false)
        output.data = this.encode(output.data);
      end
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

      output.data = this.decode(output.data);
    end

    function data = postprocess(this, ~, data)
      data = this.decode(data);
    end
  end
end
