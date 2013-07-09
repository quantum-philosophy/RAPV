function reliability(varargin)
  close all;
  setup;

  options = Test.configure('processorCount', 2, ...
    'tgffFilename', File.join('+Test', '+Assets', '002_040.tgff'), ...
    varargin{:});

  multiobjective = options.get('multiobjective', false);

  sampleCount = 1e4;
  burnMargin = 10; % degrees

  pc = Temperature.Chaos.ThermalCyclic(options);

  T = pc.computeWithLeakage( ...
    options.dynamicPower, options.steadyStateOptions);
  maximalTemperature = round(max(T(:)) + burnMargin);

  fprintf('Maximal temperature: %.2f C\n', ...
    Utils.toCelsius(maximalTemperature));

  function plotSchedule(schedule, title)
    Pdyn = options.powerScale * options.power.compute(schedule);
    time = options.samplingInterval * (0:(size(Pdyn, 2) - 1));

    [ Texp, output ] = pc.compute(Pdyn, options.steadyStateOptions);

    Pburn = sum(max(reshape(pc.sample(output, sampleCount), ...
      sampleCount, []), [], 2) > maximalTemperature) / sampleCount;

    Plot.temperatureVariation(time, Texp, output.Tvar, ...
      'layout', 'one', 'index', output.lifetimeOutput.peakIndex);
    Plot.title('%s temperature (P(T > %.2f C) = %.2f)', ...
      title, Utils.toCelsius(maximalTemperature), Pburn);
  end

  plotSchedule(options.schedule, 'Initial');

  populationSize = 10;
  mutationRate = 0.01;

  processorCount   = options.processorCount;
  taskCount        = options.taskCount;

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

    T = pc.computeWithLeakage(Pdyn, options.steadyStateOptions);
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

    Tmax = max(Texp(:));
    if Tmax > maximalTemperature
      fitness = 0;
      return;
    end

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
  gaOptions.TolFun = 1e-3;
  gaOptions.CreationFcn = @populate;
  gaOptions.SelectionFcn = @selectiontournament;
  gaOptions.CrossoverFcn = @crossoversinglepoint;
  gaOptions.MutationFcn = @mutate;
  gaOptions.Display = 'diagnose';
  gaOptions.UseParallel = 'never';

  if multiobjective
    gaOptions.ParetoFraction = 0.15;
    gaOptions.InitialPopulation = populate([], [], []);
    gaOptions.PlotFcns = { @gaplotpareto };

    tic;
    best = gamultiobj(@evaluateMultiobjective, 2 * taskCount, ...
      [], [], [], [], [], [], gaOptions);
    fprintf('Multiobjective genetic algorithm: %.2f s\n', toc);
  else
    gaOptions.PlotFcns = { @gaplotbestf };

    tic;
    best = ga(@evaluateUniobjective, 2 * taskCount, ...
      [], [], [], [], [], [], [], gaOptions);
    fprintf('Uniobjective genetic algorithm: %.2f s\n', toc);
  end

  schedule = Schedule.Dense( ...
    options.platform, options.application, ...
    'mapping', best(1:taskCount), ...
    'priority', best((taskCount + 1):end));

  plotSchedule(schedule, 'Optimized');
end
