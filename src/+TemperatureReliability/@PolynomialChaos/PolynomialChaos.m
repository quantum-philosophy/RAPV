classdef PolynomialChaos < TemperatureVariation.PolynomialChaos
  properties (SetAccess = 'protected')
    lifetime
  end

  methods
    function this = PolynomialChaos(varargin)
      this = this@TemperatureVariation.PolynomialChaos(varargin{:});
      this.lifetime = Lifetime('samplingInterval', ...
        this.temperature.samplingInterval);
    end

    function output = compute(this, Pdyn)
      Tfull = this.temperature.computeWithoutLeakage(Pdyn); % cycle template
      [ ~, lifetimeOutput ] = this.lifetime.predict(Tfull);

      output = this.surrogate.construct( ...
        @(rvs) this.surve(Pdyn, rvs, lifetimeOutput));

      output.Tfull = Tfull;
      output.lifetimeOutput = lifetimeOutput;
    end
  end

  methods (Access = 'protected')
    function surrogate = configure(this, options)
      %
      % NOTE: For now, only one distribution.
      %
      distributions = this.process.distributions;
      distribution = distributions{1};
      for i = 2:this.process.parameterCount
        assert(distribution == distributions{i});
      end

      surrogate = PolynomialChaos( ...
        'inputCount', sum(this.process.dimensions), ...
        'distribution', distribution, options);
    end

    function result = surve(this, Pdyn, rvs, lifetimeOutput)
      parameters = this.process.partition(rvs);
      parameters = this.process.evaluate(parameters);
      parameters = this.process.assign(parameters);

      T = this.temperature.computeWithLeakage(Pdyn, parameters);

      result = [ this.lifetime.predict(T, lifetimeOutput)', ...
        Utils.packPeaks(T, lifetimeOutput) ];
    end

    function T = postprocess(~, ~, T)
      %
      % Do nothing
      %
    end
  end
end
