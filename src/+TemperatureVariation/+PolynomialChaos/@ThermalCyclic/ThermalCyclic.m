classdef ThermalCyclic < TemperatureVariation.PolynomialChaos.DynamicSteadyState
  properties (SetAccess = 'protected')
    lifetime
  end

  methods
    function this = ThermalCyclic(varargin)
      this = this@TemperatureVariation.PolynomialChaos.DynamicSteadyState(varargin{:});
      this.lifetime = Lifetime('samplingInterval', this.samplingInterval);
    end

    function output = expand(this, Pdyn)
      Tfull = this.computeWithoutLeakage(Pdyn);

      [ ~, lifetimeOutput ] = this.lifetime.predict(Tfull);

      output = this.surrogate.expand( ...
        @(rvs) this.surve(Pdyn, rvs, lifetimeOutput));

      output.Tfull = Tfull;
      output.lifetimeOutput = lifetimeOutput;
    end
  end

  methods (Access = 'protected')
    function result = surve(this, Pdyn, rvs, lifetimeOutput)
      sampleCount = size(rvs, 1);

      parameters = this.process.partition(rvs);
      parameters = this.process.evaluate(parameters);
      parameters = this.process.assign(parameters);

      T = this.computeWithLeakage(Pdyn, parameters);

      result = [ ...
        this.lifetime.predict(T, lifetimeOutput)', ...
        Utils.packPeaks(T, lifetimeOutput) ];
    end

    function data = postprocess(this, output, data)
      %
      % Do not need any modifications.
      %
    end
  end
end
