function compute(varargin)
  setup;
  rng(0);

  processorCount = 4;
  taskCount = 20 * processorCount;

  caseCount = 10;
  iterationCount = 1;

  filename = sprintf('optimization_%03d_%03d_%03d_%03d.mat', ...
    processorCount, taskCount, caseCount, iterationCount);

  if File.exist(filename)
    fprintf('Using the data from "%s"...\n', filename);
    load(filename);
  else
    stochasticTime = zeros(caseCount, iterationCount);
    stochasticOutput = cell(caseCount, iterationCount);

    deterministicTime = zeros(caseCount, iterationCount);
    deterministicOutput = cell(caseCount, iterationCount);

    assessmentOutput = cell(caseCount, iterationCount);

    for i = 1:caseCount
      options = Configure.problem('processorCount', processorCount, ...
        'taskCount', taskCount, 'caseNumber', i, varargin{:});

      surrogate = SystemVariation(options);

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

      for j = 1:iterationCount
        fprintf('Stochastic: case %d, iteration %d...\n', i, j);
        ticStamp = tic;
        stochasticOutput{i, j} = stochasticOptimization.compute();
        stochasticTime(i, j) = toc(ticStamp);
        fprintf('Stochastic: done in %.2f minutes.\n', ...
          stochasticTime(i, j) / 60);

        fprintf('Deterministic: case %d, iteration %d...\n', i, j);
        ticStamp = tic;
        deterministicOutput{i, j} = deterministicOptimization.compute();
        deterministicTime(i, j) = toc(ticStamp);
        fprintf('Deterministic: done in %.2f minutes.\n', ...
          deterministicTime(i, j) / 60);

        fprintf('Assessment: case %d, iteration %d...\n', i, j);
        ticStamp = tic;
        solutionCount = size(deterministicOutput{i, j}.solutions, 1);
        iterationAssessmentOutput = cell(1, solutionCount);
        for k = 1:solutionCount
          chromosome = deterministicOutput{i, j}.solutions(k, :);
          schedule = options.scheduler.compute( ...
            chromosome(1:taskCount), chromosome((taskCount + 1):end));
          iterationAssessmentOutput{k} = stochasticObjective.compute(schedule);
        end
        assessmentOutput{i, j} = iterationAssessmentOutput;
        fprintf('Assessment: done in %.2f minutes.\n', toc(ticStamp) / 60);
      end
    end

    %
    % NOTE: Any objective will do here.
    %
    names = stochasticObjective.quantities.names( ...
      stochasticObjective.targets.index);
    nominal = stochasticObjective.quantities.nominal( ...
      stochasticObjective.targets.index);

    save(filename, 'stochasticTime', 'stochasticOutput', ...
      'deterministicTime', 'deterministicOutput', ...
      'assessmentOutput', 'names', 'nominal', '-v7.3');
  end

  fprintf('\n');
  fprintf('Stochastic solutions:\n');
  fprintf('--------------------------------------------------\n');
  reportOptimization(stochasticOutput, stochasticTime, ...
    names, nominal);

  fprintf('\n');
  fprintf('Deterministic solutions:\n');
  fprintf('--------------------------------------------------\n');
  reportOptimization(deterministicOutput, deterministicTime, ...
    names, nominal);

  fprintf('\n');
  fprintf('Assessment of the deterministic solutions:\n');
  fprintf('--------------------------------------------------\n');
  reportAssessment(deterministicOutput, assessmentOutput, nominal);
end

function reportOptimization(output, time, names, nominal)
  targetCount = size(output{1, 1}.fitness, 2);

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

          if fitness >= Objective.Base.maximalFitness
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

function reportAssessment(optimizationOutput, assessmentOutput, nominal)
  [ caseCount, iterationCount ] = size(optimizationOutput);

  failCount = 0;

  fprintf('%10s%10s%10s%10s (%30s)\n', 'Case', 'Iteration', 'Solution', ...
    'Result', 'Optimism / Violation, %');
  for i = 1:caseCount
    for j = 1:iterationCount
      solutionCount = size(optimizationOutput{i, j}.solutions, 1);
      iterationAssessmentOutput = assessmentOutput{i, j};
      for k = 1:solutionCount
        fprintf('%10d%10d%10d', i, j, k);
        if any(iterationAssessmentOutput{k}.violation > 0)
          failCount = failCount + 1;
          fprintf('%10s (', 'failed');
          fprintf('%10.2f', iterationAssessmentOutput{k}.violation * 100);
          fprintf(')');
        else
          delta = (iterationAssessmentOutput{k}.fitness - ...
            optimizationOutput{i, j}.fitness(k, :)) ./ nominal;
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
