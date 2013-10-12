classdef ThermalCyclic < Temperature.Chaos.DynamicSteadyState
  properties (SetAccess = 'protected')
    lifetime
  end

  methods
    function this = ThermalCyclic(varargin)
      this = this@Temperature.Chaos.DynamicSteadyState(varargin{:});
      this.lifetime = Lifetime('samplingInterval', this.samplingInterval);
    end

    function [ Tfull, output ] = expand(this, Pdyn)
      Tfull = this.computeWithoutLeakage(Pdyn);

      [ ~, lifetimeOutput ] = this.lifetime.predict(Tfull);

      output = this.surrogate.expand(@(rvs) this.postprocess( ...
        this.computeWithLeakage(Pdyn, this.preprocess(rvs)), lifetimeOutput));
      output.lifetimeOutput = lifetimeOutput;
    end
  end

  methods (Access = 'protected')
    function result = postprocess(this, T, lifetimeOutput)
      result = [ ...
        this.lifetime.predict(T, lifetimeOutput)', ...
        Utils.packPeaks(T, lifetimeOutput) ];
    end
  end
end
