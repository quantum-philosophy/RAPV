classdef Expectation < Objective.Base
  methods
    function this = Expectation(varargin)
      this = this@Objective.Base(varargin{:});
    end
  end

  methods (Access = 'protected')
    function fitness = evaluate(~, data)
      fitness = -mean(data(:, this.targetIndex));
    end
  end
end
