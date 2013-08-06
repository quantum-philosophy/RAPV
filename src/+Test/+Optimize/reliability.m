function reliability(varargin)
  close all;
  setup;

  options = Test.configure(varargin{:});

  target = options.get('target', 'Lifetime');

  switch target
  case 'Lifetime'
    objectiveCount = 1;
  case 'LifetimeTmax'
    objectiveCount = 2;
  case 'LifetimePburn'
    objectiveCount = 2;
  otherwise
    assert(false);
  end

  %
  % Shortcut to make the parfor slicing happy
  %
  surrogate = Temperature.Chaos.ThermalCyclic(options);
  power = options.power;
  lifetime = surrogate.lifetime;
  platform = options.platform;
  application = options.application;

  steadyStateOptions = options.steadyStateOptions;
  optimizationOptions = options.optimizationOptions;

  %
  % Timing constraint
  %
  durationLimit = optimizationOptions.deadlineDurationRatio * ...
    options.schedule.duration;

  fprintf('Initial duration: %.2f s\n', options.schedule.duration);
  fprintf('Duration limit: %.2f s\n', durationLimit);

  %
  % Thermal constraint
  %
  temperatureLimit = optimizationOptions.temperatureLimit;

  T = surrogate.computeWithLeakage( ...
    options.dynamicPower, steadyStateOptions);
  fprintf('Initial maximal temperature: %.2f C\n', ...
    Utils.toCelsius(max(T(:))));
  fprintf('Temperature limit: %.2f C\n', ...
    Utils.toCelsius(temperatureLimit));

  function plotSchedule(schedule, name)
    Pdyn = power.compute(schedule);

    [ ~, output ] = surrogate.compute(Pdyn, steadyStateOptions);
    [ MTTF, Pburn ] = Plot.solution( ...
      surrogate, output, optimizationOptions, 'name', name);

    fprintf('%15s: MTTF = %10.2e, P(T > %.2f C) = %10.2f%%\n', name, MTTF, ...
      Utils.toCelsius(temperatureLimit), Pburn * 100);
  end

  geneticOptions = options.geneticOptions;
  geneticOptions.CreationFcn = @populate;
  geneticOptions.MutationFcn = @mutate;
  geneticOptions.OutputFcns = @print;

  processorCount = options.processorCount;
  taskCount = options.taskCount;

  function population = populate(Genomelength, FitnessFcn, options_)
    count = geneticOptions.PopulationSize;
    population = zeros(count, 2 * taskCount);
    population(:, 1:taskCount) = randi(processorCount, count, taskCount);
    population(:, (taskCount + 1):end) = rand(count, taskCount);
  end

  function children = mutate(parents, options_, nvars, ...
    FitnessFcn, state, thisScore, thisPopulation)

    count = length(parents);
    children = zeros(count, 2 * taskCount, 'uint16');
    for i = 1:count
      child = thisPopulation(parents(i), :);

      points = find(rand(1, taskCount) < geneticOptions.MutationRate);
      child(points) = randi(processorCount, 1, length(points));
      points = find(rand(1, taskCount) < geneticOptions.MutationRate);
      child(taskCount + points) = rand(1, length(points));

      children(i, :) = child;
    end
  end

  cache = Cache();
  cachedCount = 0;
  discardedCount = 0;

  function chromosomes = unify(chromosomes)
    %
    % Convert double priorities to ordinal numbers
    %
    [ ~, I ] = sort(chromosomes(:, (taskCount + 1):end), 2);
    for i = 1:size(chromosomes, 1)
      chromosomes(i, taskCount + I(i, :)) = 1:taskCount;
    end
  end

  function fitness = evaluate(chromosomes)
    chromosomeCount = size(chromosomes, 1);
    fitness = nan(chromosomeCount, objectiveCount);

    chromosomes = unify(chromosomes);

    for i = 1:chromosomeCount
      value = cache.get(chromosomes(i, :));
      if ~isempty(value), fitness(i, :) = value; end
    end

    I = find(any(isnan(fitness), 2));
    newCount = length(I);

    cachedCount = cachedCount + chromosomeCount - newCount;

    newMapping  = chromosomes(I, 1:taskCount);
    newPriority = chromosomes(I, (taskCount + 1):end);
    newFitness  = inf(newCount, objectiveCount);

    parfor i = 1:newCount
      schedule = Schedule.Dense(platform, application, ...
        'mapping', newMapping(i, :), 'priority', newPriority(i, :));

      if duration(schedule) > durationLimit, continue; end

      Pdyn = power.compute(schedule);

      switch target
      case 'Lifetime'
        T = surrogate.computeWithLeakage(Pdyn, steadyStateOptions);
        if max(T(:)) > temperatureLimit, continue; end
        newFitness(i, :) = -lifetime.predict(T);
      case 'LifetimeTmax'
        T = surrogate.computeWithLeakage(Pdyn, steadyStateOptions);
        newFitness(i, :) = [ -lifetime.predict(T), max(T(:)) ];
      case 'LifetimePburn'
        [ ~, output ] = surrogate.compute(Pdyn, steadyStateOptions);
        [ MTTF, Pburn ] = Analyze.solution( ...
          surrogate, output, optimizationOptions);
        newFitness(i, :) = [ -MTTF, Pburn ];
      otherwise
        assert(false);
      end
    end
    fitness(I, :) = newFitness;

    discardedCount = discardedCount + sum(isinf(max(newFitness, [], 2)));

    for i = 1:newCount
      cache.set(chromosomes(I(i), :), newFitness(i, :));
    end
  end

  function [ state, options, onchanged ] = print(options, state, flag)
    state.target = target;
    state.cachedCount = cachedCount;
    state.discardedCount = discardedCount;
    switch objectiveCount
    case 1
      printUniobjective(state, flag);
      plotUniobjective(state, flag);
    case 2
      printMultiobjective(state, flag);
      plotMultiobjective(state, flag);
    otherwise
      assert(false);
    end
    onchanged = false;
  end

  rng(0);

  geneticOptions.InitialPopulation = populate([], [], []);

  time = tic;
  switch objectiveCount
  case 1
    best = ga(@evaluate, 2 * taskCount, ...
      [], [], [], [], [], [], [], geneticOptions);
  case 2
    best = gamultiobj(@evaluate, 2 * taskCount, ...
      [], [], [], [], [], [], geneticOptions);
    best = unique(unify(best), 'rows');
  otherwise
    assert(false);
  end
  time = toc(time);

  fprintf('Optimization time: %.2f s\n', time);

  solutionCount = size(best, 1);
  fprintf('Number of solutions: %d\n', solutionCount);

  plotSchedule(options.schedule, 'Initial');

  for k = 1:solutionCount
    schedule = Schedule.Dense(platform, application, ...
      'mapping', best(k, 1:taskCount), ...
      'priority', best(k, (taskCount + 1):end));
    plotSchedule(schedule, [ 'Solution ', num2str(k) ]);
  end
end

function printUniobjective(state, flag)
  switch flag
  case 'init'
    fprintf('%10s%15s%15s%15s%15s\n', 'Generation', 'Evaluations', ...
      'Cached', 'Discarded', 'Best MTTF');
  case { 'iter', 'done' }
    fprintf('%10d%15d%15.2f%15.2f%15.2e\n', ...
      state.Generation, state.FunEval, ...
      state.cachedCount / state.FunEval, ...
      state.discardedCount /state.FunEval, ...
      -state.Best(end));
  end
end

function printMultiobjective(state, flag)
  switch flag
  case 'init'
    fprintf('%10s%15s%15s%15s%15s\n', 'Generation', 'Evaluations', ...
      'Cached', 'Discarded', 'Non-dominants');
  case { 'iter', 'done' }
    fprintf('%10d%15d%15.2f%15.2f%15d\n', ...
      state.Generation, state.FunEval, ...
      state.cachedCount / state.FunEval, ...
      state.discardedCount / state.FunEval, ...
      sum(state.Rank == 1));
  end
end

function plotUniobjective(state, flag)
  switch flag
  case 'init'
    f = figure;
    set(f, 'Tag', 'figure');
    Plot.label('Generation', 'MTTF, years');
  case { 'iter', 'done' }
    MTTF = -state.Best(end) / 60 / 60 / 24 / 365;
    f = findobj('Tag', 'figure');
    Plot.title(f, '%d generations, %d solves, %.2f cached, %.2f discarded', ...
      state.Generation, state.FunEval, ...
      state.cachedCount / state.FunEval, ...
      state.discardedCount / state.FunEval);
    line(state.Generation, MTTF, 'LineStyle', 'none', ...
      'Marker', '*', 'Color', Color.pick(1));
  end
  drawnow;
end

function plotMultiobjective(state, flag)
  [ ~, I ] = sort(state.Score(:, 1));

  S = state.Score(I, :);
  S(:, 1) = -S(:, 1) / 60 / 60 / 24 / 365;

  switch state.target
  case 'LifetimeTmax'
    S(:, 2) = Utils.toCelsius(S(:, 2));
  case 'LifetimePburn'
    S(:, 2) = S(:, 2) * 100;
  otherwise
    assert(false);
  end

  R = state.Rank(I);

  switch flag
  case 'init'
    f = figure;
    set(f, 'Tag', 'figure');

    switch state.target
    case 'LifetimeTmax'
      names = { 'MTTF, years', 'Tmax, C' };
    case 'LifetimePburn'
      names = { 'MTTF, years', 'P(burn), %' };
    otherwise
      assert(false);
    end
    Plot.label(names{:});

    hold on;
    h = plot(S(:, 1), S(:, 2), 'LineStyle', 'none', ...
      'Marker', 'o', 'Color', Color.pick(1));
    set(h, 'Tag', 'active');
    h = plot(NaN, NaN, 'LineStyle', 'none', ...
      'Marker', '.', 'Color', 0.8 * [ 1, 1, 1 ]);
    set(h, 'Tag', 'inactive');
    h = plot(S(R == 1, 1), S(R == 1, 2), 'LineStyle', '-', ...
      'Marker', 'o', 'Color', Color.pick(2));
    set(h, 'Tag', 'front');
    hold off;
  case { 'iter', 'done' }
    f = findobj('Tag', 'figure');
    Plot.title(f, '%d generations, %d solves, %.2f cached, %.2f discarded', ...
      state.Generation, state.FunEval, ...
      state.cachedCount / state.FunEval, ...
      state.discardedCount / state.FunEval);
    h = findobj(get(f, 'Children'), 'Tag', 'active');
    Xdata = get(h, 'Xdata'); Ydata = get(h, 'Ydata');
    set(h, 'Xdata', S(:, 1), 'Ydata', S(:, 2));
    h = findobj(get(f, 'Children'), 'Tag', 'inactive');
    set(h, 'Xdata', [ get(h, 'Xdata'), Xdata ], ...
      'Ydata', [ get(h, 'Ydata'), Ydata ]);
    h = findobj(get(f, 'Children'), 'Tag', 'front');
    set(h, 'Xdata', S(R == 1, 1), 'Ydata', S(R == 1, 2));
  end
  drawnow;
end
