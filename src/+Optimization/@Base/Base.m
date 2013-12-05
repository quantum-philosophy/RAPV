classdef Base < handle
  properties (SetAccess = 'private')
    scheduler
    objective
  end

  methods
    function this = Base(varargin)
      options = Options(varargin{:});

      this.scheduler = options.scheduler;
      this.objective = options.objective;
    end
  end
end
