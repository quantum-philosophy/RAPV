classdef Expectation < Objective.Base
  methods
    function this = Expectation(varargin)
      this = this@Objective.Base(varargin{:});
    end
  end

  methods (Access = 'protected')
    function fitness = evaluate(this, data)
      %
      % TODO: It should be positive for the energy consumption and
      % negative for the maximal temperature and lifetime.
      %
      fitness = mean(data(:, this.targetIndex), 1);
    end
  end
end
