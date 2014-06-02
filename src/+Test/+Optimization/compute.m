function compute(varargin)
  setup;

  processorCount = 2;
  taskCount = 20 * processorCount;

  caseCount = 10;
  iterationCount = 1;

  stochasticTime = zeros(caseCount, iterationCount);
  stochasticOutput = cell(caseCount, iterationCount);

  deterministicTime = zeros(caseCount, iterationCount);
  deterministicOutput = cell(caseCount, iterationCount);

  assessmentOutput = cell(caseCount, iterationCount);

  for i = 1:caseCount
    options = configure(processorCount, taskCount, i, varargin{:});

    filename = sprintf('optimization_%03d_%03d_%03d_%03d_%s.mat', ...
      processorCount, taskCount, i, iterationCount, ...
      DataHash({ options.dynamicPower, options.constraintSet }));

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

      baseSolution = options.objectiveOptions.schedule;

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
