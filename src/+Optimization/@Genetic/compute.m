function output = compute(this, varargin)
  options = Options(varargin{:});

  scheduler = this.scheduler;
  objective = this.objective;

  geneticOptions = this.geneticOptions;
  geneticOptions.CreationFcn = [];
  geneticOptions.MutationFcn = @mutate;
  geneticOptions.OutputFcns = @track;

  processorCount = length(scheduler.platform);
  taskCount = length(scheduler.application);
  dimensionCount = objective.dimensionCount;

  populationSize = geneticOptions.PopulationSize;

  function population = populate
    population = zeros(populationSize, 2 * taskCount);
    population(:, 1:taskCount) = randi(processorCount, ...
      populationSize, taskCount);
    population(:, (taskCount + 1):end) = rand(populationSize, taskCount);
  end

  geneticOptions.InitialPopulation = populate;

  if options.has('initialSolution')
    geneticOptions.InitialPopulation(1, :) = ...
      [ options.initialSolution(1, :), options.initialSolution(2, :) ];
  end

  mutationRate = geneticOptions.MutationRate;

  function children = mutate(parents, ~, ~, ~, ~, ~, thisPopulation)
    count = length(parents);
    children = zeros(count, 2 * taskCount);
    for i = 1:count
      child = thisPopulation(parents(i), :);

      points = find(rand(1, taskCount) < mutationRate);
      child(points) = randi(processorCount, 1, length(points));
      points = find(rand(1, taskCount) < mutationRate);
      child(taskCount + points) = rand(1, length(points));

      children(i, :) = child;
    end
  end

  cache = Cache;
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
    fitness = NaN(chromosomeCount, dimensionCount);

    chromosomes = unify(chromosomes);

    for i = 1:chromosomeCount
      value = cache.get(chromosomes(i, :));
      if ~isempty(value), fitness(i, :) = value; end
    end

    I = find(any(isnan(fitness), 2));
    newCount = length(I);

    cachedCount = cachedCount + chromosomeCount - newCount;

    newMapping = chromosomes(I, 1:taskCount);
    newPriority = chromosomes(I, (taskCount + 1):end);
    newFitness = Inf(newCount, dimensionCount);

    for i = 1:newCount
      schedule = scheduler.compute(newMapping(i, :), newPriority(i, :));
      newFitness(i, :) = objective.compute(schedule);
    end

    for i = 1:newCount
      cache.set(chromosomes(I(i), :), newFitness(i, :));
    end

    fitness(I, :) = newFitness;

    discardedCount = discardedCount + sum(isinf(max(fitness, [], 2)));
  end

  function [ state, options, onchanged ] = track(options, state, flag)
    onchanged = false;

    state.cachedCount = cachedCount;
    state.discardedCount = discardedCount;

    this.track(state, flag);
  end

  if dimensionCount == 1
    [ solutions, fitness ] = ga(@evaluate, 2 * taskCount, ...
      [], [], [], [], [], [], [], geneticOptions);
  else
    [ solutions, fitness ] = gamultiobj(@evaluate, 2 * taskCount, ...
      [], [], [], [], [], [], geneticOptions);
  end

  output = struct;
  [ output.solutions, I ] = unique(unify(solutions), 'rows');
  output.fitness = fitness(I, :);
end
