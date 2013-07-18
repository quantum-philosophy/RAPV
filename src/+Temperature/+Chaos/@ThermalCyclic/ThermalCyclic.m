classdef ThermalCyclic < Temperature.Chaos.DynamicSteadyState
  properties (SetAccess = 'protected')
    lifetime
  end

  methods
    function this = ThermalCyclic(varargin)
      this = this@Temperature.Chaos.DynamicSteadyState(varargin{:});
      this.lifetime = Lifetime('samplingInterval', this.samplingInterval);
    end

    function [ Tfull, output ] = expand(this, Pdyn, varargin)
      options = Options(varargin{:});

      Tfull = this.solve(Pdyn, Options('leakage', []));
      [ ~, lifetimeOutput ] = this.lifetime.predict(Tfull);

      function T = target(rvs)
        L = this.preprocess(rvs, options);
        [ T, solveOutput ] = this.solve(Pdyn, Options(options, 'L', L));
        T = this.postprocess(T, solveOutput, lifetimeOutput, options);
      end

      output = this.chaos.expand(@target);
      output.lifetimeOutput = lifetimeOutput;
    end

    function Tdata = sample(this, varargin)
      Tdata = this.chaos.sample(varargin{:});
    end

    function Tdata = evaluate(this, varargin)
      Tdata = this.chaos.evaluate(varargin{:});
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
