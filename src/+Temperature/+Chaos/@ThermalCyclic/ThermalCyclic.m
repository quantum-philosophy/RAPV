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

      function T = target(rvs)
        L = this.preprocess(rvs, options);
        [ T, solveOutput ] = this.solve(Pdyn, Options(options, 'L', L));
        T = this.postprocess(T, solveOutput, lifetimeOutput, options);
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

  methods (Access = 'protected')
    function T = postprocess(this, T, solveOutput, lifetimeOutput, options)
      T = Utils.packPeaks(T, lifetimeOutput);

      if ~options.get('verbose', false), return; end

      runawayCount = sum(isnan(solveOutput.iterationCount));

      if runawayCount == 0, return; end

      warning('Detected %d thermal runaways out of %d samples.', ...
        runawayCount, sampleCount);
    end
  end
end
