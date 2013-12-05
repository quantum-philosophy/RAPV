classdef Base < handle
  properties (SetAccess = 'private')
    platform
    application
    objective
  end

  methods
    function this = Base(varargin)
      options = Options(varargin{:});

      this.platform = options.platform;
      this.application = options.application;
      this.objective = options.objective;
    end
  end
end
