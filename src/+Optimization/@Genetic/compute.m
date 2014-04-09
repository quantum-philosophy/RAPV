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
  targetCount = objective.targets.count;

  populationSize = geneticOptions.PopulationSize;

  function population = populate
    population = zeros(populationSize, 2 * taskCount);
    population(:, 1:taskCount) = randi(processorCount, ...
      populationSize, taskCount);
    population(:, (taskCount + 1):end) = rand(populationSize, taskCount);
  end

  geneticOptions.InitialPopulation = populate;

  if ~isempty(options.get('initialSolution', []))
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

  %
  % Generation stats
  %
  newCount = 0;
  newPenalizedCount = 0;

  %
  % Global stats
  %
  cachedCount = 0;
  penalizedCount = 0;

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
    objectiveOutput = cell(chromosomeCount, 1);

    fitness = NaN(chromosomeCount, targetCount);

    chromosomes = unify(chromosomes);

    I = true(chromosomeCount, 1);
    for i = 1:chromosomeCount
      value = cache.get(chromosomes(i, :));

      if isempty(value), continue; end

      objectiveOutput{i} = value;
      I(i) = false;

      fitness(i, :) = value.fitness;
    end

    I = find(I);
    newCount = length(I);

    cachedCount = cachedCount + chromosomeCount - newCount;

    newMapping = chromosomes(I, 1:taskCount);
    newPriority = chromosomes(I, (taskCount + 1):end);
    newObjectiveOutput = cell(newCount, 1);

    parfor i = 1:newCount
      schedule = scheduler.compute(newMapping(i, :), newPriority(i, :));
      newObjectiveOutput{i} = objective.compute(schedule);
    end

    objectiveOutput(I) = newObjectiveOutput;

    for i = 1:newCount
      cache.set(chromosomes(I(i), :), newObjectiveOutput{i});

      fitness(I(i), :) = newObjectiveOutput{i}.fitness;
    end

    newPenalizedCount = 0;

    for i = 1:chromosomeCount
      if ~any(objectiveOutput{i}.violations > 0), continue; end

      penalizedCount = penalizedCount + 1;

      if ismember(i, I)
        newPenalizedCount = newPenalizedCount + 1;
      end
    end
  end

  function [ state, options, onchanged ] = track(options, state, flag)
    onchanged = false;

    state.newCount = newCount;
    state.newPenalizedCount = newPenalizedCount;

    state.cachedCount = cachedCount;
    state.penalizedCount = penalizedCount;

    this.track(state, flag);
  end

  if targetCount == 1
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
