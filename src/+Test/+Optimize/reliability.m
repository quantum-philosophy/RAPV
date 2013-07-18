function reliability(varargin)
  close all;
  setup;

  options = Test.configure('processorCount', 2, ...
    'tgffFilename', File.join('+Test', 'Assets', '002_040.tgff'), ...
    varargin{:});

  multiobjective = options.get('multiobjective', false);

  sampleCount = 1e4;
  maximalTemperature = Utils.toKelvin(120);

  fprintf('Maximal temperature: %.2f C\n', ...
    Utils.toCelsius(maximalTemperature));

  pc = Temperature.Chaos.ThermalCyclic(options);

  function plotSchedule(schedule, title)
    Pdyn = options.powerScale * options.power.compute(schedule);
    time = options.samplingInterval * (0:(size(Pdyn, 2) - 1));

    [ ~, output ] = pc.compute(Pdyn, options.steadyStateOptions);

    Texp = Utils.unpackPeaks(output.expectation, output.lifetimeOutput);
    Tvar = Utils.unpackPeaks(output.variance, output.lifetimeOutput);
    MTTF = output.lifetimeOutput.totalMTTF;

    Tdata = max(pc.sample(output, sampleCount), [], 2);
    Pburn = sum(Tdata > maximalTemperature) / sampleCount;

    fprintf('%15s: MTTF = %10.2e, P(T > %.2f C) = %10.4f\n', ...
      title, MTTF, Utils.toCelsius(maximalTemperature), Pburn);

    figure('Position', [ 100, 500, 1000, 300 ]);

    subplot(1, 2, 1);
    Plot.temperatureVariation(time, Texp, Tvar, ...
      'figure', false, 'layout', 'one', ...
      'index', output.lifetimeOutput.peakIndex);
    Plot.title('MTTF = %.2e', MTTF);

    subplot(1, 2, 2);
    Data.observe(Utils.toCelsius(Tdata), ...
      'figure', false, 'layout', 'one', 'range', 'unbounded');
    Plot.vline(Utils.toCelsius(maximalTemperature), ...
      'Color', 'k', 'LineStyle', '--');
    Plot.label('Temperature, C', 'Probability');
    Plot.title('P(T > %.2f C) = %.4f', ...
      Utils.toCelsius(maximalTemperature), Pburn);
    Plot.legend('Probability density', 'Temperature constraint');

    Plot.name('%s: MTTF = %.2e, P(T > %.2f C) = %.4f', ...
      title, MTTF, Utils.toCelsius(maximalTemperature), Pburn);
  end

  populationSize = 10;
  mutationRate = 0.01;

  processorCount = options.processorCount;
  taskCount = options.taskCount;

  function population = populate(Genomelength, FitnessFcn, options_)
    M = randi(processorCount, populationSize, taskCount);
    P = rand(populationSize, taskCount);
    population = [ M, P ];
  end

  function children = mutate(parents, options_, nvars, ...
    FitnessFcn, state, thisScore, thisPopulation)

    count = length(parents);
    children = zeros(count, 2 * taskCount);
    for i = 1:count
      child = thisPopulation(parents(i), :);

      %
      % Mutate the mapping part.
      %
      points = find(rand(1, taskCount) < mutationRate);
      child(points) = randi(processorCount, 1, length(points));
      %
      % Mutate the priority part.
      %
      points = find(rand(1, taskCount) < mutationRate);
      child(taskCount + points) = rand(1, length(points));

      children(i, :) = child;
    end
  end

  function fitness = evaluateUniobjective(chromosome)
    schedule = Schedule.Dense( ...
      options.platform, options.application, ...
      'mapping', chromosome(1:taskCount), ...
      'priority', chromosome((taskCount + 1):end));
    Pdyn = options.powerScale * options.power.compute(schedule);

    T = pc.solve(Pdyn, options.steadyStateOptions);
    Tmax = max(T(:));

    if Tmax > maximalTemperature
      fitness = 0;
      return;
    end

    MTTF = pc.lifetime.predict(T);

    fitness = -MTTF;
  end

  function fitness = evaluateMultiobjective(chromosome)
    schedule = Schedule.Dense( ...
      options.platform, options.application, ...
      'mapping', chromosome(1:taskCount), ...
      'priority', chromosome((taskCount + 1):end));
    Pdyn = options.powerScale * options.power.compute(schedule);

    [ Texp, output ] = pc.compute(Pdyn, options.steadyStateOptions);

    Pburn = sum(max(reshape(pc.sample(output, sampleCount), ...
      sampleCount, []), [], 2) > maximalTemperature) / sampleCount;

    fitness = [ -output.lifetimeOutput.totalMTTF, Pburn ];
  end

  gaOptions = gaoptimset;
  gaOptions.PopulationSize = populationSize;
  gaOptions.EliteCount = floor(0.05 * populationSize);
  gaOptions.CrossoverFraction = 0.8;
  gaOptions.MigrationFraction = 0.2;
  gaOptions.Generations = 500;
  gaOptions.StallGenLimit = 100;
  gaOptions.TolFun = 0;
  gaOptions.CreationFcn = @populate;
  gaOptions.SelectionFcn = @selectiontournament;
  gaOptions.CrossoverFcn = @crossoversinglepoint;
  gaOptions.MutationFcn = @mutate;
  gaOptions.Display = 'off';
  gaOptions.UseParallel = 'always';

  time = tic;
  if multiobjective
    gaOptions.ParetoFraction = 1;
    gaOptions.InitialPopulation = populate([], [], []);
    gaOptions.OutputFcns = { @printMultiobjective, @plotMultiobjective };
    best = gamultiobj(@evaluateMultiobjective, 2 * taskCount, ...
      [], [], [], [], [], [], gaOptions);
  else
    gaOptions.OutputFcns = { @printUniobjective, @plotUniobjective };
    best = ga(@evaluateUniobjective, 2 * taskCount, ...
      [], [], [], [], [], [], [], gaOptions);
  end
  time = toc(time);

  fprintf('Optimization time: %.2f s\n', time);

  solutionCount = size(best, 1);
  fprintf('Number of solutions: %d\n', solutionCount);

  plotSchedule(options.schedule, 'Initial');

  for k = 1:solutionCount
    schedule = Schedule.Dense( ...
      options.platform, options.application, ...
      'mapping', best(k, 1:taskCount), ...
      'priority', best(k, (taskCount + 1):end));
    plotSchedule(schedule, [ 'Solution ', num2str(k) ]);
  end
end

function [ state, options, onchanged ] = printUniobjective(options, state, flag)
  switch flag
  case 'init'
    fprintf('%10s%15s%15s\n', 'Generation', 'Evaluations', 'Best MTTF');
  case { 'iter', 'done' }
    fprintf('%10d%15d%15.2e\n', ...
      state.Generation, state.FunEval, state.Best(end));
  end
  onchanged = false;
end

function [ state, options, onchanged ] = printMultiobjective(options, state, flag)
  switch flag
  case 'init'
    fprintf('%10s%15s%15s\n', 'Generation', 'Evaluations', 'Best MTTF');
  case { 'iter', 'done' }
    fprintf('%10d%15d\n', ...
      state.Generation, state.FunEval);
  end
  onchanged = false;
end

function [ state, options, onchanged ] = plotUniobjective(options, state, flag)
  switch flag
  case 'init'
    figure;
    Plot.label('Generation', 'MTTF');
  case { 'iter', 'done' }
    line(state.Generation, -state.Best(end), 'LineStyle', 'none', ...
      'Marker', '*', 'Color', Color.pick(1));
  end
  drawnow;
  onchanged = false;
end

function [ state, options, onchanged ] = plotMultiobjective(options, state, flag)
  [ ~, I ] = sort(state.Score(:, 1));
  S = state.Score(I, :);
  S(:, 1) = -S(:, 1);
  R = state.Rank(I);
  switch flag
  case 'init'
    figure;
    Plot.label('MTTF', 'P(burn)');
    hold on;
    h = plot(S(:, 1), S(:, 2), 'LineStyle', 'none', ...
      'Marker', 'o', 'Color', Color.pick(1));
    set(h, 'Tag', 'all');
    h = plot(S(R == 1, 1), S(R == 1, 2), 'LineStyle', '-', ...
      'Marker', 'o', 'Color', Color.pick(2));
    set(h, 'Tag', 'front');
    hold off;
  case { 'iter', 'done' }
    h = findobj(get(gca, 'Children'), 'Tag', 'all');
    set(h, 'Xdata', S(:, 1), 'Ydata', S(:, 2));
    h = findobj(get(gca, 'Children'), 'Tag', 'front');
    set(h, 'Xdata', S(R == 1, 1), 'Ydata', S(R == 1, 2));
  end
  drawnow;
  onchanged = false;
end
