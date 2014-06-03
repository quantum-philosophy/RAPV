function semiCompute(varargin)
  setup;

  processorCount = 16;
  taskCount = 20 * processorCount;

  caseCount = 10;
  iterationCount = 1;

  stochasticTime = zeros(caseCount, iterationCount);
  stochasticOutput = cell(caseCount, iterationCount);

  for i = 1:caseCount
    options = configure(processorCount, taskCount, i, varargin{:});

    filename = sprintf('semioptimization_%03d_%03d_%03d_%03d_%s.mat', ...
      processorCount, taskCount, i, iterationCount, ...
      DataHash({ options.dynamicPower, options.constraintSet }));

    if File.exist(filename)
      fprintf('Using the data from "%s"...\n', filename);
      load(filename);
    else
      rng(i);

      caseStochasticTime = zeros(1, iterationCount);
      caseStochasticOutput = cell(1, iterationCount);

      surrogate = SystemVariation(options);

      stochasticObjective = Objective.SemiStochastic( ...
        'surrogate', surrogate, 'excludedQuantities', { 'Lifetime' }, ...
        options.objectiveOptions);
      display(stochasticObjective);

      stochasticOptimization = Optimization.Genetic( ...
        'objective', stochasticObjective, options.optimizationOptions);

      baseSolution = options.objectiveOptions.schedule;

      for j = 1:iterationCount
        fprintf('Stochastic: case %d, iteration %d...\n', i, j);
        ticStamp = tic;
        caseStochasticOutput{j} = stochasticOptimization.compute( ...
          'initialSolution', baseSolution);
        caseStochasticTime(j) = toc(ticStamp);
        fprintf('Stochastic: done in %.2f minutes.\n', ...
          caseStochasticTime(j) / 60);
      end

      %
      % NOTE: Any objective will do here.
      %
      quantities = stochasticObjective.quantities;

      save(filename, 'caseStochasticTime', 'caseStochasticOutput', ...
        'quantities', '-v7.3');
    end

    stochasticTime(i, :) = caseStochasticTime;
    stochasticOutput(i, :) = caseStochasticOutput;
  end

  fprintf('\n');
  fprintf('Stochastic solutions:\n');
  fprintf('--------------------------------------------------\n');
  reportOptimization(quantities, stochasticOutput, stochasticTime);
end
