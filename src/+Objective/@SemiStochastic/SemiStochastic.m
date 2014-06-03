classdef SemiStochastic < Objective.Stochastic
  properties (SetAccess = 'private')
    excludedIndex
  end

  methods
    function this = SemiStochastic(varargin)
      options = Options(varargin{:});
      this = this@Objective.Stochastic(options);

      excludedQuantities = options.excludedQuantities;
      excludedCount = length(excludedQuantities);
      this.excludedIndex = zeros(1, excludedCount);
      for i = 1:excludedCount
        for j = 1:this.quantities.count
          if strcmpi(excludedQuantities{i}, this.quantities.names{j})
            this.excludedIndex(i) = j;
            break;
          end
        end
      end
      assert(all(this.excludedIndex > 0));
    end
  end

  methods (Access = 'protected')
    function output = evaluate(this, schedule)
      output = evaluate@Objective.Stochastic(this, schedule);
      output.violation(this.excludedIndex) = 0;
    end
  end
end
