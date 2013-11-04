classdef ThermalCyclic < TemperatureVariation.StochasticCollocation.DynamicSteadyState
  properties (SetAccess = 'protected')
    lifetime
  end

  methods
    function this = ThermalCyclic(varargin)
      this = this@TemperatureVariation.StochasticCollocation.DynamicSteadyState(varargin{:});
      this.lifetime = Lifetime('samplingInterval', this.samplingInterval);
    end

    function output = interpolate(this, Pdyn)
      Tfull = this.computeWithoutLeakage(Pdyn);

      [ ~, lifetimeOutput ] = this.lifetime.predict(Tfull);

      outputCount = 1; % 1 for the lifetime
      for i = 1:this.processorCount
        outputCount = outputCount + length(lifetimeOutput.peakIndex{i});
      end

      output = this.surrogate.construct( ...
        @(rvs) this.surve(Pdyn, rvs, lifetimeOutput), outputCount);

      output.Tfull = Tfull;
      output.lifetimeOutput = lifetimeOutput;
    end
  end

  methods (Access = 'protected')
    function result = surve(this, Pdyn, rvs, lifetimeOutput)
      sampleCount = size(rvs, 1);

      rvs(rvs == 0) = sqrt(eps);
      rvs(rvs == 1) = 1 - sqrt(eps);
      parameters = this.process.partition(rvs);
      parameters = this.process.evaluate(parameters, true); % uniform
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
