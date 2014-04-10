classdef Base < handle
  properties (Constant)
    maximalFitness = 1e3;
  end

  properties (SetAccess = 'private')
    power
    surrogate

    quantities
    targets
    constraints

    sampleCount
  end

  methods
    function this = Base(varargin)
      if length(varargin) == 1
        that = varargin{1};

        this.power = that.power;
        this.surrogate = that.surrogate;

        this.quantities = that.quantities;
        this.targets = that.targets;
        this.constraints = that.constraints;

        this.sampleCount = that.sampleCount;

        return;
      end

      options = Options(varargin{:});

      this.power = options.power;
      this.surrogate = options.surrogate;

      [ this.quantities, this.targets, this.constraints ] = ...
        this.configure(options);

      this.sampleCount = options.get('sampleCount', 1e3);
    end

    function output = compute(this, schedule)
      output = this.evaluate(schedule);

      I = output.violation > 0;
      if ~any(I), return; end

      %
      % NOTE: Here we ignore the computed fitness.
      %
      output.fitness(:) = this.maximalFitness + sum(output.violation(I));
    end
  end

  methods (Abstract = true, Access = 'protected')
    output = evaluate(this, schedule)
  end

  methods (Access = 'protected')
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
