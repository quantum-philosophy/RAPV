classdef Base < handle
  properties (SetAccess = 'private')
    power
    surrogate

    targetNames
    targetIndex
    dimensionCount

    constraints
    sampleCount
  end

  methods
    function this = Base(varargin)
      options = Options(varargin{:});

      this.power = options.power;
      this.surrogate = options.surrogate;

      this.targetNames = options.targetNames;
      this.dimensionCount = length(this.targetNames);

      this.targetIndex = zeros(1, this.dimensionCount);
      for i = 1:this.dimensionCount
        found = false;
        for j = 1:this.surrogate.quantityCount
          if strcmpi(this.targetNames{i}, this.surrogate.quantityNames{j})
            found = true;
            this.targetIndex(i) = j;
          end
        end
        assert(found);
      end

      this.constraints = this.constrain(options);
      this.sampleCount = options.get('sampleCount', 1e3);
    end

    function fitness = compute(this, schedule)
      if duration(schedule) > this.constraints.deadline
        fitness = Inf(1, this.dimensionCount);
        return;
      end

      output = this.surrogate.compute(this.power.compute(schedule));

      data = this.surrogate.sample(output, this.sampleCount);
      probability = mean( ...
        bsxfun(@gt, data, this.constraints.lowerBound), ...
        bsxfun(@lt, data, this.constraints.upperBound), 1);

      if any(probability < this.constraints.probability)
        fitness = Inf(1, this.dimensionCount);
        return;
      end

      fitness = this.evaluate(data);
    end
  end

  methods (Abstract, Access = 'protected')
    fitness = evaluate(this, data);
  end
end
