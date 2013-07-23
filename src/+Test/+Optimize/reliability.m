function reliability(varargin)
  close all;
  setup;

  options = Test.configure(varargin{:});

  pc = Temperature.Chaos.ThermalCyclic(options);

  function plotSchedule(schedule, name)
    Pdyn = options.power.compute(schedule);

    [ ~, output ] = pc.compute(Pdyn, options.steadyStateOptions);
    [ MTTF, Pburn ] = Plot.solution(pc, output, ...
      options.optimizationOptions, 'name', name);

    fprintf('%15s: MTTF = %10.2e, P(T > %.2f C) = %10.4f\n', name, MTTF, ...
      Utils.toCelsius(options.optimizationOptions.temperatureLimit), Pburn);
  end

  geneticOptions = options.geneticOptions;
  geneticOptions.CreationFcn = @populate;
  geneticOptions.MutationFcn = @mutate;

  processorCount = options.processorCount;
  taskCount = options.taskCount;

  function population = populate(Genomelength, FitnessFcn, options_)
    count = geneticOptions.PopulationSize;
    population = zeros(count, 2 * taskCount, 'uint16');
    population(:, 1:taskCount) = randi(processorCount, count, taskCount);
    population(:, (taskCount + 1):end) = randi(taskCount, count, taskCount);
  end

  function children = mutate(parents, options_, nvars, ...
    FitnessFcn, state, thisScore, thisPopulation)

    count = length(parents);
    children = zeros(count, 2 * taskCount, 'uint16');
    for i = 1:count
      child = thisPopulation(parents(i), :);

      %
      % Mutate the mapping part.
      %
      points = find(rand(1, taskCount) < geneticOptions.MutationRate);
      child(points) = randi(processorCount, 1, length(points));
      %
      % Mutate the priority part.
      %
      points = find(rand(1, taskCount) < geneticOptions.MutationRate);
      child(taskCount + points) = randi(taskCount, 1, length(points));

      children(i, :) = child;
    end
  end

  function fitness = evaluateUniobjective(chromosome)
    schedule = Schedule.Dense( ...
      options.platform, options.application, ...
      'mapping', chromosome(1:taskCount), ...
      'priority', chromosome((taskCount + 1):end));
    Pdyn = options.power.compute(schedule);

    T = pc.solve(Pdyn, options.steadyStateOptions);

    if max(T(:)) > options.optimizationOptions.temperatureLimit
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
    Pdyn = options.power.compute(schedule);

    [ ~, output ] = pc.compute(Pdyn, options.steadyStateOptions);
    [ MTTF, Pburn ] = Analyze.solution(pc, output, ...
      options.optimizationOptions);

    fitness = [ -MTTF, Pburn ];
  end

  geneticOptions.InitialPopulation = populate([], [], []);

  cache = Cache();

  time = tic;
  if options.get('multiobjective', false)
    geneticOptions.OutputFcns = { @plotMultiobjective, ...
      @(a, b, c) printMultiobjective(a, b, c, cache) };
    best = gamultiobj( ...
      @(data) cache.fetch(data, @evaluateMultiobjective), ...
      2 * taskCount, [], [], [], [], [], [], geneticOptions);
  else
    geneticOptions.OutputFcns = { @plotUniobjective, ...
      @(a, b, c) printUniobjective(a, b, c, cache) };
    best = ga( ...
      @(data) cache.fetch(data, @evaluateUniobjective), ...
      2 * taskCount, [], [], [], [], [], [], [], geneticOptions);
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

function [ state, options, onchanged ] = printUniobjective( ...
  options, state, flag, cache)

  switch flag
  case 'init'
    fprintf('%10s%15s%15s%15s\n', 'Generation', 'Evaluations', ...
      'Best MTTF', 'Cache');
  case { 'iter', 'done' }
    fprintf('%10d%15d%15.2e%15.2f\n', ...
      state.Generation, state.FunEval, state.Best(end), ...
      cache.hitCount / (cache.hitCount + cache.missCount));
  end
  onchanged = false;
end

function [ state, options, onchanged ] = printMultiobjective( ...
  options, state, flag, cache)

  switch flag
  case 'init'
    fprintf('%10s%15s%15s%15s\n', 'Generation', 'Evaluations', ...
      'Non-dominants', 'Cache');
  case { 'iter', 'done' }
    fprintf('%10d%15d%15d%15.2f\n', ...
      state.Generation, state.FunEval, sum(state.Rank == 1), ...
      cache.hitCount / (cache.hitCount + cache.missCount));
  end
  onchanged = false;
end

function [ state, options, onchanged ] = plotUniobjective( ...
  options, state, flag)

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

function [ state, options, onchanged ] = plotMultiobjective( ...
  options, state, flag)

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
