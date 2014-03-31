function compute(varargin)
  setup;
  rng(0);

  caseCount = 10;
  iterationCount = 10;

  options = Configure.problem(varargin{:});

  surrogate = SystemVariation(options);
  display(surrogate);

  objective = Objective.Expectation( ...
    'surrogate', surrogate, options.objectiveOptions);
  display(objective);

  optimization = Optimization.Genetic( ...
    'objective', objective, options.optimizationOptions);

  time = zeros(caseCount, iterationCount);
  output = cell(caseCount, iterationCount);

  for i = 1:caseCount
    mapping = randi(options.processorCount, 1, options.taskCount);
    priority = rand(1, options.taskCount);
    schedule = options.scheduler.compute(mapping, priority);

    for j = 1:iterationCount
      ticStamp = tic;
      fprintf('%s: case %d, iteration %d...\n', class(optimization), i, j);
      output{i, j} = optimization.compute('initialSolution', schedule);
      time(i, j) = toc(ticStamp);
      fprintf('%s: case %d, iteration %d, done in %.2f minutes.\n', ...
        class(optimization), i, j, time(i, j) / 60);
    end
  end

  dimensionCount = objective.dimensionCount;
  nominal = objective.constraints.nominal(objective.targetIndex);
  names = surrogate.quantityNames(objective.targetIndex);

  globalFitness = Inf(caseCount, iterationCount, dimensionCount);
  globalGain = Inf(caseCount, iterationCount, dimensionCount);

  fprintf('%10s%10s%10s', 'Case', 'Iteration', 'Solution');
  for l = 1:dimensionCount
    fprintf('%15s (%10s)', names{l}, 'Gain, %');
  end
  fprintf('\n');

  for i = 1:caseCount
    for j = 1:iterationCount
      solutionCount = size(output{i, j}.solutions, 1);
      for k = 1:solutionCount
        fprintf('%10d%10d%10d', i, j, k);
        for l = 1:dimensionCount
          fitness = output{i, j}.fitness(k, l);
          gain = 1 - nominal(l) / output{i, j}.fitness(k, l);
          globalFitness(i, j, l) = min(globalFitness(i, j, l), fitness);
          globalGain(i, j, l) = min(globalGain(i, j, l), gain);
          fprintf('%15.2f (%10.2f)', fitness, gain * 100);
        end
        fprintf('\n');
      end
    end

    fprintf('%10d%20s', i, 'Average solution');
    for l = 1:dimensionCount
      fitness = mean(globalFitness(i, :, l));
      gain = mean(globalGain(i, :, l));
      fprintf('%15.2f (%10.2f)', fitness, gain * 100);
    end
    fprintf('\n');
    fprintf('%10d%20s%28.2f\n', i, 'Average time, m', ...
      mean(time(i, :)) / 60);
    fprintf('\n');
  end

  fprintf('%30s', 'Total average solution');
  for l = 1:dimensionCount
    fitness = globalFitness(:, :, l);
    fitness = mean(fitness(:));
    gain = globalGain(:, :, l);
    gain = mean(gain(:));
    fprintf('%15.2f (%10.2f)', fitness, gain * 100);
  end
  fprintf('\n');
  fprintf('%30s%28.2f\n', 'Total average time, m', ...
    mean(time(:)) / 60);
end
