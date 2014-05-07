function compute(varargin)
  setup;

  options = Configure.problem(varargin{:});

  surrogate = SystemVariation(options);
  display(surrogate);

  objective = Objective.Stochastic( ...
    'surrogate', surrogate, options.objectiveOptions);
  display(objective);
end
