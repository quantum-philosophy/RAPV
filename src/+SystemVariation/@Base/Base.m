classdef Base < handle
  properties (Constant)
    quantityCount = 3;
    quantityNames = { 'Temperature', 'Energy', 'Lifetime' };
  end

  properties (SetAccess = 'protected')
    fatigue
  end

  methods
    function this = Base(varargin)
      options = Options(varargin{:});
      this.fatigue = Fatigue(options.fatigueOptions);
    end
  end

  %
  % NOTE: The purpose of "Sealed = true" here is to unambiguously
  % resolve collisions of method names.
  %
  % Reference:
  %
  % http://www.mathworks.se/help/releases/R2011a/techdoc/matlab_oop/breg81r.html
  %
  methods (Sealed = true, Access = 'protected')
    function data = serve(this, Pdyn, rvs, fatigueOutput, isUniform)
      if nargin < 5, isUniform = false; end

      parameters = this.process.partition(rvs);
      parameters = this.process.evaluate(parameters, isUniform);
      parameters = this.process.assign(parameters);

      [ T, output ] = this.temperature.computeWithLeakage( ...
        Pdyn, parameters, 'T', fatigueOutput.T);

      samplingInterval = this.temperature.samplingInterval;

      data = this.encode([ ...
        ... Temperature
        permute(max(max(T, [], 1), [], 2), [ 3, 2, 1 ]), ...
        ... Energy
        permute(samplingInterval * sum(sum(output.P, 1), 2), [ 3, 2, 1 ]), ...
        ... Lifetime
        transpose(this.fatigue.compute(T, fatigueOutput)) ]);
    end

    function data = encode(this, data)
      ... Temperature
      data(:, 1) = data(:, 1) - this.temperature.ambientTemperature;
      ... All
      data = log(data);
    end

    function data = decode(this, data)
      ... All
      data = exp(data);
      ... Temperature
      data(:, 1) = data(:, 1) + this.temperature.ambientTemperature;
    end
  end
end
