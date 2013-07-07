classdef ThermalCyclic < Temperature.Chaos.DynamicSteadyState

  methods
    function this = ThermalCyclic(varargin)
      this = this@Temperature.Chaos.DynamicSteadyState(varargin{:});
    end

    function [ Texp, output ] = expand(this, Pdyn, varargin)
      options = Options(varargin{:});
      lifetime = options.lifetime;

      function result = target(rvs)
        L = transpose(this.process.evaluate(rvs));
        T = this.computeWithLeakage(Pdyn, options, 'L', L);
        result = Utils.packPeaks(T, lifetime);
      end

      coefficients = this.chaos.expand(@target);

      Texp = Utils.unpackPeaks(coefficients(1, :), lifetime);

      if nargout < 2, return; end

      outputCount = size(coefficients, 2);

      output.Tvar = Utils.unpackPeaks(sum(coefficients(2:end, :).^2 .* ...
        Utils.replicate(this.chaos.norm(2:end), 1, outputCount), 1), ...
        lifetime);

      output.coefficients = coefficients;
      output.lifetime = lifetime;
    end

    function Tdata = sample(this, output, sampleCount)
      Tdata = this.chaos.sample(sampleCount, output.coefficients);
      Tdata = Utils.unpackPeaks(Tdata, output.lifetime);
    end

    function Tdata = evaluate(this, output, rvs)
      Tdata = this.chaos.evaluate(rvs, output.coefficients);
      Tdata = Utils.unpackPeaks(Tdata, output.lifetime);
    end
  end
end
