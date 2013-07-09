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

      Tfull = this.computeWithoutLeakage(Pdyn);
      [ ~, lifetimeOutput ] = this.lifetime.predict(Tfull);

      function result = target(rvs)
        L = transpose(this.process.evaluate(rvs));
        T = this.computeWithLeakage(Pdyn, options, 'L', L);
        result = Utils.packPeaks(T, lifetimeOutput);
      end

      coefficients = this.chaos.expand(@target);

      Texp = Utils.unpackPeaks(coefficients(1, :), lifetimeOutput);

      if nargout < 2, return; end

      outputCount = size(coefficients, 2);

      output.Tvar = Utils.unpackPeaks(sum(coefficients(2:end, :).^2 .* ...
        Utils.replicate(this.chaos.norm(2:end), 1, outputCount), 1), ...
        lifetimeOutput);

      output.coefficients = coefficients;

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
