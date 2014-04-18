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
          chromosome = deterministicOutput{i, j}.solutions{k}.chromosome;
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
    quantities = stochasticObjective.quantities;

    save(filename, 'stochasticTime', 'stochasticOutput', ...
      'deterministicTime', 'deterministicOutput', ...
      'assessmentOutput', 'quantities', '-v7.3');
  end

  fprintf('\n');
  fprintf('Stochastic solutions:\n');
  fprintf('--------------------------------------------------\n');
  reportOptimization(quantities, stochasticOutput, stochasticTime);

  fprintf('\n');
  fprintf('Deterministic solutions:\n');
  fprintf('--------------------------------------------------\n');
  reportOptimization(quantities, deterministicOutput, deterministicTime);

  fprintf('\n');
  fprintf('Assessment of the deterministic solutions:\n');
  fprintf('--------------------------------------------------\n');
  reportAssessment(quantities, deterministicOutput, assessmentOutput);
end

function reportOptimization(quantities, output, time)
  targetCount = length(quantities.targetIndex);
  [ caseCount, iterationCount ] = size(output);

  globalValue = NaN(caseCount, iterationCount, targetCount);
  globalChange = NaN(caseCount, iterationCount, targetCount);

  fprintf('%10s%10s%10s', 'Case', 'Iteration', 'Time, m');
  for k = 1:quantities.count
    fprintf('%15s (%15s)', quantities.names{k}, 'Change, %');
  end
  fprintf('\n');

  for i = 1:caseCount
    for j = 1:iterationCount
      %
      % NOTE: Not ready for multiple solutions.
      %
      solutionCount = length(output{i, j}.solutions);
      assert(solutionCount == 1);

      solution = output{i, j}.solutions{1};

      fprintf('%10d%10d%10.2f', i, j, time(i, j) / 60);

      if any(solution.fitness >= Objective.Base.maximalFitness)
        fprintf('%15s\n', 'NA');
        continue;
      end

      for k = 1:quantities.count
        value = solution.expectation(k);
        change = value / quantities.nominal(k);

        globalValue(i, j, k) = value;
        globalChange(i, j, k) = change;

        fprintf('%15.2e (%15.2f)', value, change * 100);
      end

      fprintf('\n');
    end

    if iterationCount == 1, continue; end

    fprintf('%10s%10s%10.2f', 'Average', '', mean(time(i, :)) / 60);
    for k = 1:quantities.count
      value = globalValue(i, :, k);
      change = globalChange(i, :, k);

      I = ~isnan(value);

      fprintf('%15.2f (%15.2f)', mean(value(I)), mean(change(I)) * 100);
    end
    fprintf('\n\n');
  end

  fprintf('%10s%10s%10.2f', 'Average', '', mean(time(:)) / 60);
  for k = 1:targetCount
    value = reshape(globalValue(:, :, k), 1, []);
    change = reshape(globalChange(:, :, k), 1, []);

    I = ~isnan(value);

    fprintf('%15.2f (%15.2f)', mean(value(I)), mean(change(I)) * 100);
  end
  fprintf('\n');
end

function reportAssessment(quantities, optimizationOutput, assessmentOutput)
  [ caseCount, iterationCount ] = size(optimizationOutput);

  failCount = 0;

  fprintf('%10s%10s%10s (%40s)\n', 'Case', 'Iteration', 'Result', ...
    'Offset / Violation, %');
  for i = 1:caseCount
    for j = 1:iterationCount
      %
      % NOTE: Not ready for multiple solutions.
      %
      solutionCount = length(optimizationOutput{i, j}.solutions);
      assert(solutionCount == 1);

      solution = optimizationOutput{i, j}.solutions{1};
      assessment = assessmentOutput{i, j}{1};

      fprintf('%10d%10d', i, j);
      if any(assessment.violation > 0)
        failCount = failCount + 1;
        fprintf('%10s (', 'failed');
        fprintf('%10.2f', assessment.violation * 100);
        fprintf(')');
      else
        fprintf('%10s (', 'passed');
        change = solution.expectation ./ quantities.nominal;
        trueChange = assessment.expectation ./ quantities.nominal;
        fprintf('%10.2f', (trueChange - change) * 100);
        fprintf(')');
      end
      fprintf('\n');
    end
  end

  fprintf('\n');
  fprintf('Failure rate: %.2f %%\n', ...
    failCount / caseCount / iterationCount * 100);
end
