classdef Base < handle
  properties (SetAccess = 'protected')
    fatigue
  end

  methods
    function this = Base(varargin)
      options = Options(varargin{:});
      this.fatigue = Fatigue(options.fatigueOptions);
    end
  end
end
