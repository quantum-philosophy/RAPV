function reliability
  close all;
  setup;

  options = Test.configure('processorCount', 2);

  dss = Temperature.Analytical.DynamicSteadyState( ...
    options.temperatureOptions);

  pc = Temperature.Chaos.DynamicSteadyState(options);

  lifetime = Lifetime('samplingInterval', options.samplingInterval);

  function plotSchedule(schedule, title)
    Pdyn = options.powerScale * options.power.compute(schedule);
    time = options.samplingInterval * (0:(size(Pdyn, 2) - 1));

    T = dss.compute(Pdyn, options.steadyStateOptions);
    [ ~, lifetimeOutput ] = lifetime.predict(T);

    [ Texp, output ] = pc.compute(Pdyn, ...
      options.steadyStateOptions, 'lifetime', lifetimeOutput);

    Plot.temperatureVariation(time, Texp, output.Tvar, ...
      'layout', 'one', 'index', lifetimeOutput.peakIndex);
    Plot.title('Temperature profile (%s)', title);
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

  function fitness = evaluate(chromosome)
    schedule = Schedule.Dense( ...
      options.platform, options.application, ...
      'mapping', chromosome(1:taskCount), ...
      'priority', chromosome((taskCount + 1):end));
    Pdyn = options.powerScale * options.power.compute(schedule);

    T = dss.compute(Pdyn, options.steadyStateOptions);
    [ MTTF, lifetimeOutput ] = lifetime.predict(T);

    % Texp = pc.compute(Pdyn, options.steadyStateOptions, ...
    %   'lifetime', lifetimeOutput);

    fitness = -MTTF;
  end

  gaOptions = gaoptimset;
  gaOptions.PopulationSize = populationSize;
  gaOptions.EliteCount = floor(0.05 * populationSize);
  gaOptions.CrossoverFraction = 0.8;
  gaOptions.MigrationFraction = 0.2;
  gaOptions.Generations = 1e3;
  gaOptions.StallGenLimit = 100;
  gaOptions.TolFun = 1e-3;
  gaOptions.CreationFcn = @populate;
  gaOptions.SelectionFcn = @selectiontournament;
  gaOptions.CrossoverFcn = @crossoversinglepoint;
  gaOptions.MutationFcn = @mutate;
  gaOptions.Display = 'diagnose';
  gaOptions.PlotFcns = { @gaplotbestf };
  gaOptions.UseParallel = 'never';

  tic;
  best = ga(@evaluate, 2 * taskCount, gaOptions);
  fprintf('Genetic algorithm: %.2f s\n', toc);

  schedule = Schedule.Dense( ...
    options.platform, options.application, ...
    'mapping', best(1:taskCount), ...
    'priority', best((taskCount + 1):end));

  plotSchedule(schedule, 'Optimized');
end
