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

  for i = 1:caseCount
    fprintf('%10s', 'Solution');
    for l = 1:dimensionCount
      fprintf('%15s (%10s)', names{l}, 'Gain, %');
    end
    fprintf('\n');

    for j = 1:iterationCount
      fprintf('Case %d, iteration %d:\n', i, j);

      solutionCount = size(output{i, j}.solutions, 1);

      for k = 1:solutionCount
        fprintf('%10d', k);
        for l = 1:dimensionCount
          fitness = output{i, j}.fitness(k, l);
          gain = 1 - nominal(l) / output{i, j}.fitness(k, l);
          globalFitness(i, j, l) = min(globalFitness(i, j, l), fitness);
          globalGain(i, j, l) = min(globalGain(i, j, l), gain);
          fprintf('%15.2f (%10.2f)', fitness, gain * 100);
        end
        fprintf('\n');
      end

      fprintf('\n');
    end

    fprintf('Case-%d average (%.2f minutes):\n', 1, mean(time(i, :)) / 60);
    for l = 1:dimensionCount
      fitness = mean(globalFitness(i, :, l));
      gain = mean(globalGain(i, :, l));
      fprintf('%15.2f (%10.2f)', fitness, gain * 100);
    end

    fprintf('\n');
  end

  fprintf('Total average (%.2f minus):\n', mean(time(:)) / 60);
  for l = 1:dimensionCount
    fitness = globalFitness(:, :, l);
    fitness = mean(fitness(:));
    gain = globalGain(:, :, l);
    gain = mean(gain(:));
    fprintf('%15.2f (%10.2f)', fitness, gain * 100);
  end

  fprintf('\n');
end
