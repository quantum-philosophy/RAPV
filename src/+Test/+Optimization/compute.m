function compute(varargin)
  setup;

  processorCount = 2;
  taskCount = 20 * processorCount;

  caseCount = 10;
  iterationCount = 1;

  constraintMap = containers.Map;

  ... Constraints on Temperature/Energy, Lifetime, and Time
  ... C - cases, I - iterations, NA - w/o solution, F - failures

  ... 2 cores
  constraintMap('002_040'    ) = [ 1.00,  5.00, 1.20 ];
  constraintMap('002_040/002') = [ 1.02,  4.00, 1.20 ];
  constraintMap('002_040/003') = [ 1.02,  2.00, 1.20 ];
  constraintMap('002_040/004') = [ 1.01,  5.00, 1.20 ];
  constraintMap('002_040/005') = [ 1.00,  4.00, 1.20 ];
  constraintMap('002_040/006') = [ 1.01,  4.00, 1.20 ];
  constraintMap('002_040/008') = [ 1.01,  3.00, 1.20 ];
  constraintMap('002_040/010') = [ 1.02,  3.00, 1.20 ];

  ... 4 cores
  constraintMap('004_080'    ) = [ 1.01,  1.00, 1.30 ];

  ... 8 cores
  constraintMap('008_160'    ) = [ 1.02,  1.00, 1.30 ];

  ... 16 cores
  constraintMap('016_320'    ) = [ 1.02,  1.00, 1.30 ];

  ... 32 cores
  constraintMap('032_640'    ) = [ 1.00,  1.50, 1.30 ];

  function range = boundRange(constraintKey, name, nominal, ~)
    constraints = constraintMap(constraintKey);
    switch lower(name)
    case { 'temperature', 'energy' }
      range = [ 0, constraints(1) * nominal ];
    case 'lifetime'
      range = [ constraints(2) * nominal, Inf ];
    case 'time'
      range = [ 0, constraints(3) * nominal ];
    otherwise
      assert(false);
    end
  end

  function probability = boundProbability(~, ~)
    probability = 0.99;
  end

  stochasticTime = zeros(caseCount, iterationCount);
  stochasticOutput = cell(caseCount, iterationCount);

  deterministicTime = zeros(caseCount, iterationCount);
  deterministicOutput = cell(caseCount, iterationCount);

  assessmentOutput = cell(caseCount, iterationCount);

  for i = 1:caseCount
    options = Configure.case('processorCount', processorCount, ...
      'taskCount', taskCount, 'caseNumber', i, varargin{:});

    if constraintMap.isKey(options.caseName)
      constraintKey = options.caseName;
    elseif constraintMap.isKey(options.setupName)
      constraintKey = options.setupName;
    else
      assert(false);
    end

    options = Configure.problem(options);

    objectiveOptions = Options( ...
      'targetNames', { 'energy' }, ...
      'constraintNames', { 'temperature', 'lifetime' }, ...
      'power', options.power, ...
      'schedule', options.schedule, ...
      'boundRange', @(varargin) boundRange(constraintKey, varargin{:}), ...
      'boundProbability', @(varargin) boundProbability(varargin{:}), ...
      'sampleCount', 1e4);

    geneticOptions = Options( ...
      'Generations', 100, ...
      'StallGenLimit', 10, ...
      'PopulationSize', 4 * taskCount, ...
      'CrossoverFraction', 0.8, ...
      'MutationRate', 0.05, ...
      'SelectionFcn', { @selectiontournament, ...
        floor(0.05 * 4 * taskCount) });

    optimizationOptions = Options( ...
      'scheduler', options.scheduler, ...
      'verbose', true, ...
      'visualize', false, ...
      'geneticOptions', geneticOptions);

    filename = sprintf('optimization_%03d_%03d_%03d_%03d_%s.mat', ...
      processorCount, taskCount, i, iterationCount, ...
      DataHash({ options.dynamicPower, constraintMap(constraintKey) }));

    if File.exist(filename)
      fprintf('Using the data from "%s"...\n', filename);
      load(filename);
    else
      rng(i);

      caseStochasticTime = zeros(1, iterationCount);
      caseStochasticOutput = cell(1, iterationCount);

      caseDeterministicTime = zeros(1, iterationCount);
      caseDeterministicOutput = cell(1, iterationCount);

      caseAssessmentOutput = cell(1, iterationCount);

      surrogate = SystemVariation(options);

      %
      % Stochastic
      %
      stochasticObjective = Objective.Stochastic( ...
        'surrogate', surrogate, objectiveOptions);
      display(stochasticObjective);

      stochasticOptimization = Optimization.Genetic( ...
        'objective', stochasticObjective, optimizationOptions);

      %
      % Deterministic
      %
      deterministicObjective = Objective.Deterministic(stochasticObjective);

      deterministicOptimization = Optimization.Genetic( ...
        'objective', deterministicObjective, optimizationOptions);

      baseSolution = objectiveOptions.schedule;

      for j = 1:iterationCount
        fprintf('Stochastic: case %d, iteration %d...\n', i, j);
        ticStamp = tic;
        caseStochasticOutput{j} = stochasticOptimization.compute( ...
          'initialSolution', baseSolution);
        caseStochasticTime(j) = toc(ticStamp);
        fprintf('Stochastic: done in %.2f minutes.\n', ...
          caseStochasticTime(j) / 60);

        fprintf('Deterministic: case %d, iteration %d...\n', i, j);
        ticStamp = tic;
        caseDeterministicOutput{j} = deterministicOptimization.compute( ...
          'initialSolution', baseSolution);
        caseDeterministicTime(j) = toc(ticStamp);
        fprintf('Deterministic: done in %.2f minutes.\n', ...
          caseDeterministicTime(j) / 60);

        fprintf('Assessment: case %d, iteration %d...\n', i, j);
        ticStamp = tic;
        solutionCount = size(caseDeterministicOutput{j}.solutions, 1);
        iterationAssessmentOutput = struct;
        iterationAssessmentOutput.solutions = cell(1, solutionCount);
        for k = 1:solutionCount
          chromosome = caseDeterministicOutput{j}.solutions{k}.chromosome;
          schedule = stochasticOptimization.scheduler.compute( ...
            chromosome(1:taskCount), chromosome((taskCount + 1):end));
          iterationAssessmentOutput.solutions{k} = ...
            stochasticObjective.compute(schedule);
          iterationAssessmentOutput.solutions{k}.chromosome = chromosome;
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
  reportOptimization(quantities, assessmentOutput, 0 * deterministicTime);

  fprintf('\n');
  fprintf('Summary of the assessment:\n');
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
      assessment = assessmentOutput{i, j}.solutions{1};

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
