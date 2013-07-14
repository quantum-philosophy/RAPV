classdef ThermalCyclic < Temperature.Chaos.DynamicSteadyState
  properties (SetAccess = 'protected')
    lifetime
  end

  methods
    function this = ThermalCyclic(varargin)
      this = this@Temperature.Chaos.DynamicSteadyState(varargin{:});
      this.lifetime = Lifetime('samplingInterval', this.samplingInterval);
    end

    function [ Texp, output ] = expand(this, Pdyn, varargin)
      options = Options(varargin{:});

      Tfull = this.solve(Pdyn, Options('leakage', []));
      [ ~, lifetimeOutput ] = this.lifetime.predict(Tfull);

      function result = target(rvs)
        L = transpose(this.process.evaluate(rvs));
        T = this.solve(Pdyn, Options(options, 'L', L));
        result = Utils.packPeaks(T, lifetimeOutput);
      end

      chaosOutput = this.chaos.expand(@target);

      Texp = Utils.unpackPeaks(chaosOutput.expectation, lifetimeOutput);

      if nargout < 2, return; end

      output.Tvar = Utils.unpackPeaks(chaosOutput.variance, lifetimeOutput);

      output.coefficients = chaosOutput.coefficients;

      output.Tfull = Tfull;
      output.lifetimeOutput = lifetimeOutput;
    end

    function Tdata = sample(this, output, sampleCount)
      Tdata = this.chaos.sample(sampleCount, output.coefficients);
      Tdata = Utils.unpackPeaks(Tdata, output.lifetimeOutput);
    end

    function Tdata = evaluate(this, output, rvs)
      Tdata = this.chaos.evaluate(rvs, output.coefficients);
      Tdata = Utils.unpackPeaks(Tdata, output.lifetimeOutput);
    end
  end
end
