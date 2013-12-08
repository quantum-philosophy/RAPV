classdef Base < handle
  properties (SetAccess = 'private')
    power
    surrogate

    targetIndex
    constraints

    dimensionCount
    sampleCount
  end

  methods
    function this = Base(varargin)
      options = Options(varargin{:});

      this.power = options.power;
      this.surrogate = options.surrogate;

      [ this.targetIndex, this.constraints ] = this.configure(options);

      this.dimensionCount = nnz(this.targetIndex);
      this.sampleCount = options.get('sampleCount', 1e3);
    end
  end

  methods (Abstract, Access = 'protected')
    fitness = computeFitness(this, data);
  end

  methods (Access = 'private')
    function probability = computeProbability(~, data, range)
      %
      % NOTE: It is assumed that the support is positive, and
      % the range is bounded only at one end.
      %
      if range(1) <= 0
        probability = ksdensity(data, range(2), ...
          'support', 'positive', 'function', 'cdf');
      elseif isinf(range(2))
        probability = 1 - ksdensity(data, range(1), ...
          'support', 'positive', 'function', 'cdf');
      else
        assert(false);
      end
    end

    function quantile = computeQuantile(~, data, range, probability)
      %
      % NOTE: It is assumed that the support is positive, and
      % the range is bounded only at one end.
      %
      if range(1) <= 0
        quantile = ksdensity(data, probability, ...
          'support', 'positive', 'function', 'icdf');
      elseif isinf(range(2))
        quantile = ksdensity(data, 1 - probability, ...
          'support', 'positive', 'function', 'icdf');
      else
        assert(false);
      end
    end
  end
end
