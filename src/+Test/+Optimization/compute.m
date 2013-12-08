function compute(varargin)
  setup;
  rng(0);

  options = Configure.problem(varargin{:});

  surrogate = SystemVariation(options);
  display(surrogate);

  objective = Objective.Expectation( ...
    'surrogate', surrogate, options.objectiveOptions);
  display(objective);

  optimization = Optimization.Genetic( ...
    'objective', objective, options.optimizationOptions);

  time = tic;
  fprintf('%s: in progress...\n', class(optimization));
  output = optimization.compute;
  fprintf('%s: done in %.2f minutes.\n', class(optimization), toc(time) / 60);

  fprintf('Number of solutions: %d\n', size(output.solutions, 1));
end
