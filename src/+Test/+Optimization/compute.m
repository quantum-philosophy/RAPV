function compute(varargin)
  setup;
  rng(0);

  caseCount = 10;
  iterationCount = 1;

  options = Configure.problem(varargin{:});

  surrogate = SystemVariation(options);
  display(surrogate);

  %
  % Stochastic
  %
  stochasticObjective = Objective.Stochastic( ...
    'surrogate', surrogate, options.objectiveOptions);
  display(stochasticObjective);

  stochasticOptimization = Optimization.Genetic( ...
    'objective', stochasticObjective, options.optimizationOptions);

  %
  % Deterministic
  %
  deterministicObjective = Objective.Deterministic(stochasticObjective);

  deterministicOptimization = Optimization.Genetic( ...
    'objective', deterministicObjective, options.optimizationOptions);

  mapping = randi(options.processorCount, caseCount, options.taskCount);
  priority = rand(caseCount, options.taskCount);

  filename = sprintf('optimization_%s.mat', ...
    DataHash({ mapping, priority, iterationCount, options.toString }));

  if File.exist(filename)
    fprintf('Using the data from "%s"...\n', filename);
    load(filename);
  else
    stochasticTime = zeros(caseCount, iterationCount);
    stochasticOutput = cell(caseCount, iterationCount);

    deterministicTime = zeros(caseCount, iterationCount);
    deterministicOutput = cell(caseCount, iterationCount);

    for i = 1:caseCount
      for j = 1:iterationCount
        fprintf('Case %d, iteration %d...\n', i, j);

        ticStamp = tic;
        stochasticOutput{i, j} = stochasticOptimization.compute();
        stochasticTime(i, j) = toc(ticStamp);
        fprintf('Stochastic: done in %.2f minutes.\n', ...
          stochasticTime(i, j) / 60);

        ticStamp = tic;
        deterministicOutput{i, j} = deterministicOptimization.compute();
        deterministicTime(i, j) = toc(ticStamp);
        fprintf('Deterministic: done in %.2f minutes.\n', ...
          deterministicTime(i, j) / 60);
      end
    end

    save(filename, 'stochasticTime', 'stochasticOutput', ...
      'deterministicTime', 'deterministicOutput', '-v7.3');
  end

  fprintf('\n');
  fprintf('Stochastic solutions:\n');
  fprintf('--------------------------------------------------\n');
  report(stochasticObjective, stochasticOutput, stochasticTime);

  fprintf('\n');
  fprintf('Deterministic solutions:\n');
  fprintf('--------------------------------------------------\n');
  report(deterministicObjective, deterministicOutput, deterministicTime);

  fprintf('\n');
  fprintf('Assessment of the deterministic solutions:\n');
  fprintf('--------------------------------------------------\n');
  check(options.scheduler, stochasticObjective, deterministicOutput);
end

function report(objective, output, time)
  targetCount = objective.targets.count;
  names = objective.quantities.names(objective.targets.index);
  nominal = objective.quantities.nominal(objective.targets.index);

  [ caseCount, iterationCount ] = size(output);

  globalFitness = NaN(caseCount, iterationCount, targetCount);
  globalGain = NaN(caseCount, iterationCount, targetCount);

  fprintf('%10s%10s%10s', 'Case', 'Iteration', 'Solution');
  for l = 1:targetCount
    fprintf('%15s (%15s)', names{l}, 'Reduction, %');
  end
  fprintf('%10s\n', 'Time, m');

  for i = 1:caseCount
    for j = 1:iterationCount
      solutionCount = size(output{i, j}.solutions, 1);
      for k = 1:solutionCount
        fprintf('%10d%10d%10d', i, j, k);
        for l = 1:targetCount
          fitness = output{i, j}.fitness(k, l);

          if fitness >= objective.maximalFitness
            fprintf('%15s (%15s)', 'NA', 'NA');
            continue;
          end

          gain = 1 - fitness / nominal(l);
          globalFitness(i, j, l) = min(globalFitness(i, j, l), fitness);
          globalGain(i, j, l) = min(globalGain(i, j, l), gain);
          fprintf('%15.2f (%15.2f)', fitness, gain * 100);
        end
        if k == 1
          fprintf('%10.2f\n', time(i, j) / 60);
        else
          fprintf('\n');
        end
      end
    end

    if iterationCount == 1, continue; end

    fprintf('%10s%20s', 'Average', '');
    for l = 1:targetCount
      fitness = globalFitness(i, I, l);
      gain = globalGain(i, I, l);

      I = ~isnan(fitness);

      fprintf('%15.2f (%15.2f)', mean(fitness(I)), ...
        mean(gain(:)) * 100);
    end
    fprintf('%10.2f\n', mean(time(i, :)) / 60);
    fprintf('\n');
  end

  fprintf('%10s%20s', 'Average', '');
  for l = 1:targetCount
    fitness = reshape(globalFitness(:, :, l), 1, []);
    gain = reshape(globalGain(:, :, l), 1, []);

    I = ~isnan(fitness);

    fprintf('%15.2f (%15.2f)', mean(fitness(I)), ...
      mean(gain(I)) * 100);
  end
  fprintf('%10.2f\n', mean(time(:)) / 60);
end

function check(scheduler, objective, output)
  nominal = objective.quantities.nominal(objective.targets.index);

  [ caseCount, iterationCount ] = size(output);
  taskCount = length(scheduler.application);

  failCount = 0;

  fprintf('%10s%10s%10s%10s (%30s)\n', 'Case', 'Iteration', 'Solution', ...
    'Result', 'Optimism / Violation, %');
  for i = 1:caseCount
    for j = 1:iterationCount
      solutionCount = size(output{i, j}.solutions, 1);
      for k = 1:solutionCount
        fprintf('%10d%10d%10d', i, j, k);
        chromosome = output{i, j}.solutions(k, :);
        schedule = scheduler.compute( ...
          chromosome(1:taskCount), chromosome((taskCount + 1):end));
        objectiveOutput = objective.compute(schedule);
        if any(objectiveOutput.violation > 0)
          failCount = failCount + 1;
          fprintf('%10s (', 'failed');
          fprintf('%10.2f', objectiveOutput.violation * 100);
          fprintf(')');
        else
          delta = (objectiveOutput.fitness - ...
            output{i, j}.fitness(k, :)) ./ nominal;
          fprintf('%10s (%30.2f)', 'passed', delta * 100);
        end
        fprintf('\n');
      end
    end
  end

  fprintf('\n');
  fprintf('Failure rate: %.2f %%\n', ...
    failCount / caseCount / iterationCount * 100);
end
