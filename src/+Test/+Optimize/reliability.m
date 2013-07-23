function reliability(varargin)
  close all;
  setup;

  options = Test.configure(varargin{:});

  if options.get('multiobjective', false)
    objectiveCount = 2;
  else
    objectiveCount = 1;
  end

  %
  % Shortcut to make the parfor slicing happy
  %
  pc = Temperature.Chaos.ThermalCyclic(options);
  solvePC = @pc.solve;
  computePC = @pc.compute;

  lifetime = pc.lifetime;
  predictLifetime = @lifetime.predict;

  power = options.power;
  computePower = @power.compute;

  platform = options.platform;
  application = options.application;

  steadyStateOptions = options.steadyStateOptions;
  optimizationOptions = options.optimizationOptions;
  temperatureLimit = optimizationOptions.temperatureLimit;

  function plotSchedule(schedule, name)
    Pdyn = computePower(schedule);

    [ ~, output ] = computePC(Pdyn, steadyStateOptions);
    [ MTTF, Pburn ] = Plot.solution( ...
      pc, output, optimizationOptions, 'name', name);

    fprintf('%15s: MTTF = %10.2e, P(T > %.2f C) = %10.4f\n', name, MTTF, ...
      Utils.toCelsius(temperatureLimit), Pburn);
  end

  geneticOptions = options.geneticOptions;
  geneticOptions.CreationFcn = @populate;
  geneticOptions.MutationFcn = @mutate;
  geneticOptions.OutputFcns = @print;

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

  cache = Cache();
  hitCount = 0;

  function fitness = evaluate(chromosomes)
    chromosomeCount = size(chromosomes, 1);
    fitness = nan(chromosomeCount, objectiveCount);

    for i = 1:chromosomeCount
      value = cache.get(chromosomes(i, :));
      if ~isempty(value), fitness(i, :) = value; end
    end

    I = find(any(isnan(fitness), 2));
    newCount = length(I);

    hitCount = hitCount + chromosomeCount - newCount;

    newMapping  = chromosomes(I, 1:taskCount);
    newPriority = chromosomes(I, (taskCount + 1):end);
    newFitness  = zeros(newCount, objectiveCount);

    parfor i = 1:newCount
      schedule = Schedule.Dense(platform, application, ...
        'mapping', newMapping(i, :), 'priority', newPriority(i, :));
      Pdyn = computePower(schedule);

      switch objectiveCount
      case 1
        T = solvePC(Pdyn, steadyStateOptions);

        if max(T(:)) > temperatureLimit
          newFitness(i, :) = 0;
        else
          newFitness(i, :) = -predictLifetime(T);
        end
      case 2
        [ ~, output ] = computePC(Pdyn, steadyStateOptions);
        [ MTTF, Pburn ] = Analyze.solution( ...
          pc, output, optimizationOptions);

        newFitness(i, :) = [ -MTTF, Pburn ];
      otherwise
        assert(false);
      end
    end
    fitness(I, :) = newFitness;

    for i = 1:newCount
      cache.set(chromosomes(I(i), :), newFitness(i, :));
    end
  end

  function [ state, options, onchanged ] = print(options, state, flag)
    switch objectiveCount
    case 1
      printUniobjective(state, flag, hitCount);
      plotUniobjective(state, flag);
    case 2
      printMultiobjective(state, flag, hitCount);
      plotMultiobjective(state, flag);
    otherwise
      assert(false);
    end
    onchanged = false;
  end

  geneticOptions.InitialPopulation = populate([], [], []);

  time = tic;
  switch objectiveCount
  case 1
    best = ga(@evaluate, 2 * taskCount, ...
      [], [], [], [], [], [], [], geneticOptions);
  case 2
    best = gamultiobj(@evaluate, 2 * taskCount, ...
      [], [], [], [], [], [], geneticOptions);
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

function printUniobjective(state, flag, hitCount)
  switch flag
  case 'init'
    fprintf('%10s%15s%15s%15s\n', 'Generation', 'Evaluations', ...
      'Best MTTF', 'Cache');
  case { 'iter', 'done' }
    fprintf('%10d%15d%15.2e%15.2f\n', ...
      state.Generation, state.FunEval, state.Best(end), ...
      hitCount / state.FunEval);
  end
end

function printMultiobjective(state, flag, hitCount)
  switch flag
  case 'init'
    fprintf('%10s%15s%15s%15s\n', 'Generation', 'Evaluations', ...
      'Non-dominants', 'Cache');
  case { 'iter', 'done' }
    fprintf('%10d%15d%15d%15.2f\n', ...
      state.Generation, state.FunEval, sum(state.Rank == 1), ...
      hitCount / state.FunEval);
  end
end

function plotUniobjective(state, flag)
  switch flag
  case 'init'
    figure;
    Plot.label('Generation', 'MTTF');
  case { 'iter', 'done' }
    line(state.Generation, -state.Best(end), 'LineStyle', 'none', ...
      'Marker', '*', 'Color', Color.pick(1));
  end
  drawnow;
end

function plotMultiobjective(state, flag)
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
end
