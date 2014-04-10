classdef Stochastic < Objective.Base
  methods
    function this = Stochastic(varargin)
      this = this@Objective.Base(varargin{:});
    end
  end

  methods (Access = 'protected')
    output = evaluate(this, schedule)
  end
end
