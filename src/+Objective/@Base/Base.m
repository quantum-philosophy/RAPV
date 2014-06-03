classdef Base < handle
  properties (Constant)
    maximalFitness = 1e3;
  end

  properties (SetAccess = 'private')
    power
    surrogate
    sampleCount
    quantities
  end

  methods
    function this = Base(varargin)
      if length(varargin) == 1 && isa(varargin{1}, 'Objective.Base')
        that = varargin{1};

        this.power = that.power;
        this.surrogate = that.surrogate;
        this.sampleCount = that.sampleCount;
        this.quantities = that.quantities;

        return;
      end

      options = Options(varargin{:});

      this.power = options.power;
      this.surrogate = options.surrogate;
      this.sampleCount = options.get('sampleCount', 1e4);
      this.quantities = this.configure(options);
    end

    function output = compute(this, schedule)
      output = this.evaluate(schedule);

      output.fitness = output.expectation(this.quantities.targetIndex);

      I = output.violation > 0;
      if ~any(I), return; end

      %
      % NOTE: Here we ignore the computed fitness.
      %
      if I(end)
        %
        % NOTE: The last item correspond to the timing constraint.
        % If it is violated, the other constraints are not being cheched.
        %
        output.fitness(:) = 2 * this.maximalFitness + output.violation(end);
      else
        output.fitness(:) = this.maximalFitness + sum(output.violation(I));
      end
    end
  end

  methods (Abstract = true, Access = 'protected')
    output = evaluate(this, schedule)
  end

  methods (Access = 'protected')
    function probability = computeProbability(~, data, range, crude)
      if nargin < 4, crude = false; end

      %
      % NOTE: It is assumed that the support is positive, and
      % the range is bounded only at one end.
      %
      if range(1) <= 0
        if crude
          probability = sum(data < range(2)) / numel(data);
        else
          probability = ksdensity(data, range(2), ...
            'support', 'positive', 'function', 'cdf');
        end
      elseif isinf(range(2))
        if crude
          probability = 1 - sum(data < range(1)) / numel(data);
        else
          probability = 1 - ksdensity(data, range(1), ...
            'support', 'positive', 'function', 'cdf');
        end
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
