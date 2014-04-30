function compute(varargin)
  setup;
  rng(0);

  processorCount = 4;
  taskCount = 20 * processorCount;

  caseCount = 10;
  iterationCount = 1;

  stochasticTime = zeros(caseCount, iterationCount);
  stochasticOutput = cell(caseCount, iterationCount);

  deterministicTime = zeros(caseCount, iterationCount);
  deterministicOutput = cell(caseCount, iterationCount);

  assessmentOutput = cell(caseCount, iterationCount);

  for i = 1:caseCount
    filename = sprintf('optimization_%03d_%03d_%03d_%03d.mat', ...
      processorCount, taskCount, i, iterationCount);

    if File.exist(filename)
      fprintf('Using the data from "%s"...\n', filename);
      load(filename);
    else
      caseStochasticTime = zeros(1, iterationCount);
      caseStochasticOutput = cell(1, iterationCount);

      caseDeterministicTime = zeros(1, iterationCount);
      caseDeterministicOutput = cell(1, iterationCount);

      caseAssessmentOutput = cell(1, iterationCount);

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
        caseStochasticOutput{j} = stochasticOptimization.compute();
        caseStochasticTime(j) = toc(ticStamp);
        fprintf('Stochastic: done in %.2f minutes.\n', ...
          caseStochasticTime(j) / 60);

        fprintf('Deterministic: case %d, iteration %d...\n', i, j);
        ticStamp = tic;
        caseDeterministicOutput{j} = deterministicOptimization.compute();
        caseDeterministicTime(j) = toc(ticStamp);
        fprintf('Deterministic: done in %.2f minutes.\n', ...
          caseDeterministicTime(j) / 60);

        fprintf('Assessment: case %d, iteration %d...\n', i, j);
        ticStamp = tic;
        solutionCount = size(caseDeterministicOutput{j}.solutions, 1);
        iterationAssessmentOutput = cell(1, solutionCount);
        for k = 1:solutionCount
          chromosome = caseDeterministicOutput{j}.solutions{k}.chromosome;
          schedule = options.scheduler.compute( ...
            chromosome(1:taskCount), chromosome((taskCount + 1):end));
          iterationAssessmentOutput{k} = stochasticObjective.compute(schedule);
        end
        caseAssessmentOutput{j} = iterationAssessmentOutput;
        fprintf('Assessment: done in %.2f minutes.\n', toc(ticStamp) / 60);
      end

      %
      % NOTE: Any objective will do here.
      %
      quantities = stochasticObjective.quantities;

      save(filename, 'caseStochasticTime', 'caseStochasticOutput', ...
        'caseDeterministicTime', 'caseDeterministicOutput', ...
        'caseAssessmentOutput', 'quantities', '-v7.3');
    end

    stochasticTime(i, :) = caseStochasticTime;
    stochasticOutput(i, :) = caseStochasticOutput;

    deterministicTime(i, :) = caseDeterministicTime;
    deterministicOutput(i, :) = caseDeterministicOutput;

    assessmentOutput(i, :) = caseAssessmentOutput;
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
  [ caseCount, iterationCount ] = size(output);

  globalValue = NaN(caseCount, iterationCount, quantities.count);
  globalChange = NaN(caseCount, iterationCount, quantities.count);
  bestIndex = NaN(caseCount, 1);

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
        fprintf('%15s (%15s)\n', 'NA', 'NA');
        continue;
      end

      %
      % NOTE: Not ready for multiobjective optimization.
      %
      if isnan(bestIndex(i)) || ...
        solution.fitness < output{i, bestIndex(i)}.solutions{1}.fitness

        bestIndex(i) = j;
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

    if iterationCount == 1 || isnan(bestIndex(i)), continue; end

    fprintf('%10s%10s%10.2f', 'Best', '', time(i, bestIndex(i)) / 60);
    for k = 1:quantities.count
      value = globalValue(i, bestIndex(i), k);
      change = globalChange(i, bestIndex(i), k);

      fprintf('%15.2e (%15.2f)', value, change * 100);
    end
    fprintf('\n\n');
  end

  I = find(~isnan(bestIndex));
  J = bestIndex(I);

  if isempty(I), return; end

  time = select(time, I, J);

  fprintf('%10s%10s%10.2f', 'Average', '', mean(time) / 60);
  for k = 1:quantities.count
    value = select(globalValue(:, :, k), I, J);
    change = select(globalChange(:, :, k), I, J);

    fprintf('%15.2e (%15.2f)', mean(value), mean(change) * 100);
  end
  fprintf('\n');
end

function reportAssessment(quantities, optimizationOutput, assessmentOutput)
  [ caseCount, iterationCount ] = size(optimizationOutput);

  failCount = 0;

  fprintf('%10s%10s%10s (%40s)\n', 'Case', 'Iteration', 'Result', ...
    'Offset / Violation, %');
  for i = 1:caseCount
    %
    % NOTE: Not ready for multiple objectives.
    %
    fitness = NaN(1, iterationCount);
    valid = false(1, iterationCount);

    for j = 1:iterationCount
      %
      % NOTE: Not ready for multiple solutions.
      %
      solutionCount = length(optimizationOutput{i, j}.solutions);
      assert(solutionCount == 1);

      solution = optimizationOutput{i, j}.solutions{1};
      assessment = assessmentOutput{i, j}{1};

      if all(solution.fitness < Objective.Base.maximalFitness)
        fitness(j) = solution.fitness;
      end

      fprintf('%10d%10d', i, j);
      if any(assessment.violation > 0)
        fprintf('%10s (', 'failed');
        fprintf('%10.2f', assessment.violation * 100);
        fprintf(')');
      else
        valid(j) = true;

        fprintf('%10s (', 'passed');
        change = solution.expectation ./ quantities.nominal;
        trueChange = assessment.expectation ./ quantities.nominal;
        fprintf('%10.2f', (trueChange - change) * 100);
        fprintf(')');
      end
      fprintf('\n');
    end

    J = find(~isnan(fitness));
    [ ~, k ] = min(fitness(J));

    if isempty(J) || ~valid(J(k))
      failCount = failCount + 1;
    end
  end

  fprintf('\n');
  fprintf('Failure rate: %.2f %%\n', failCount / caseCount * 100);
end

function result = select(A, I, J)
  result = zeros(1, length(I));
  for i = 1:length(I)
    result(i) = A(I(i), J(i));
  end
end
