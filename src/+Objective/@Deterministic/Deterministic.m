classdef Deterministic < Objective.Base
  methods
    function this = Deterministic(varargin)
      this = this@Objective.Base(varargin{:});
    end
  end
end
