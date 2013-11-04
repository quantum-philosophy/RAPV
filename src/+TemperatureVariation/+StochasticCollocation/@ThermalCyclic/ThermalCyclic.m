classdef ThermalCyclic < TemperatureVariation.StochasticCollocation.DynamicSteadyState
  properties (SetAccess = 'protected')
    lifetime
  end

  methods
    function this = ThermalCyclic(varargin)
      this = this@TemperatureVariation.StochasticCollocation.DynamicSteadyState(varargin{:});
      this.lifetime = Lifetime('samplingInterval', this.samplingInterval);
    end

    function [ Tfull, output ] = interpolate(this, Pdyn)
      Tfull = this.computeWithoutLeakage(Pdyn);

      [ ~, lifetimeOutput ] = this.lifetime.predict(Tfull);

      outputCount = 1; % 1 for the lifetime
      for i = 1:this.processorCount
        outputCount = outputCount + length(lifetimeOutput.peakIndex{i});
      end

      output = this.surrogate.construct(@(rvs) this.postprocess( ...
        this.computeWithLeakage(Pdyn, this.preprocess(rvs)), ...
        lifetimeOutput), outputCount);
      output.lifetimeOutput = lifetimeOutput;
    end

    function result = sample(this, varargin)
      result = this.surrogate.sample(varargin{:});
    end

    function result = evaluate(this, varargin)
      result = this.surrogate.evaluate(varargin{:});
    end
  end

  methods (Access = 'protected')
    function result = postprocess(this, T, lifetimeOutput)
      result = [ ...
        0 * this.lifetime.predict(T, lifetimeOutput)', ...
        Utils.packPeaks(T, lifetimeOutput) ];
    end
  end
end
