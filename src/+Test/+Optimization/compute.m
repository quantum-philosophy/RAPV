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
  output = optimization.compute('initialSolution', options.schedule);
  fprintf('%s: done in %.2f minutes.\n', class(optimization), toc(time) / 60);

  solutionCount = size(output.solutions, 1);
  dimensionCount = objective.dimensionCount;
  nominal = objective.constraints.nominal(objective.targetIndex);
  names = surrogate.quantityNames(objective.targetIndex);

  fprintf('Number of solutions: %d\n', solutionCount);

  fprintf('%10s', 'Solution');
  for i = 1:dimensionCount
    fprintf('%15s (%10s)', names{i}, 'Gain, %');
  end
  fprintf('\n');

  for i = 1:solutionCount
    fprintf('%10d', i);
    for j = 1:dimensionCount
      fprintf('%15.2f (%10.2f)', output.fitness(i, j), ...
        (1 - nominal(j) / output.fitness(i, j)) * 100);
    end
    fprintf('\n');
  end
end
