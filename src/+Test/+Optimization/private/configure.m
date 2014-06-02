function options = configure(processorCount, taskCount, caseNumber, varargin)
  constraintMap = containers.Map;

  ... Constraints on Temperature/Energy, Lifetime, and Time

  ... 2 cores
  constraintMap('002_040'    ) = [ 1.00,  5.00, 1.20 ];
  constraintMap('002_040/002') = [ 1.02,  4.00, 1.20 ];
  constraintMap('002_040/003') = [ 1.02,  2.00, 1.20 ];
  constraintMap('002_040/004') = [ 1.01,  5.00, 1.20 ];
  constraintMap('002_040/005') = [ 1.00,  4.00, 1.20 ];
  constraintMap('002_040/006') = [ 1.01,  4.00, 1.20 ];
  constraintMap('002_040/008') = [ 1.01,  3.00, 1.20 ];
  constraintMap('002_040/010') = [ 1.02,  3.00, 1.20 ];

  ... 4 cores
  constraintMap('004_080'    ) = [ 1.01,  4.00, 1.30 ];
  constraintMap('004_080/004') = [ 1.00,  3.00, 1.30 ];
  constraintMap('004_080/005') = [ 1.01,  3.00, 1.30 ];
  constraintMap('004_080/006') = [ 1.01,  3.00, 1.30 ];
  constraintMap('004_080/008') = [ 1.01,  3.00, 1.30 ];
  constraintMap('004_080/009') = [ 1.01,  3.00, 1.30 ];
  constraintMap('004_080/010') = [ 1.01,  3.00, 1.30 ];

  ... 8 cores
  constraintMap('008_160'    ) = [ 1.01,  3.00, 1.30 ];
  constraintMap('008_160/006') = [ 1.01,  1.50, 1.30 ];
  constraintMap('008_160/007') = [ 1.00,  2.00, 1.30 ];
  constraintMap('008_160/008') = [ 1.01,  1.50, 1.30 ];

  ... 16 cores
  constraintMap('016_320'    ) = [ 1.01,  1.50, 1.30 ];
  constraintMap('016_320/006') = [ 1.01,  1.40, 1.40 ];
  constraintMap('016_320/007') = [ 1.01,  1.40, 1.40 ];
  constraintMap('016_320/009') = [ 1.00,  1.40, 1.40 ];

  ... 32 cores
  constraintMap('032_640'    ) = [ 1.00,  1.50, 1.60 ];
  constraintMap('032_640/006') = [ 1.00,  1.50, 1.70 ];
  constraintMap('032_640/009') = [ 0.98,  1.60, 1.80 ];

  function range = boundRange(constraintKey, name, nominal, ~)
    constraints = constraintMap(constraintKey);
    switch lower(name)
    case { 'temperature', 'energy' }
      range = [ 0, constraints(1) * nominal ];
    case 'lifetime'
      range = [ constraints(2) * nominal, Inf ];
    case 'time'
      range = [ 0, constraints(3) * nominal ];
    otherwise
      assert(false);
    end
  end

  function probability = boundProbability(~, ~)
    probability = 0.99;
  end

  options = Configure.case('processorCount', processorCount, ...
    'taskCount', taskCount, 'caseNumber', caseNumber, varargin{:});

  if constraintMap.isKey(options.caseName)
    constraintKey = options.caseName;
  elseif constraintMap.isKey(options.setupName)
    constraintKey = options.setupName;
  else
    assert(false);
  end

  options = Configure.problem(options);

  objectiveOptions = Options( ...
    'targetNames', { 'energy' }, ...
    'constraintNames', { 'temperature', 'lifetime' }, ...
    'power', options.power, ...
    'schedule', options.schedule, ...
    'boundRange', @(varargin) boundRange(constraintKey, varargin{:}), ...
    'boundProbability', @(varargin) boundProbability(varargin{:}), ...
    'sampleCount', 1e4);

  geneticOptions = Options( ...
    'Generations', 100, ...
    'StallGenLimit', 10, ...
    'PopulationSize', 4 * taskCount, ...
    'CrossoverFraction', 0.8, ...
    'MutationRate', 0.05, ...
    'SelectionFcn', { @selectiontournament, ...
      floor(0.05 * 4 * taskCount) });

  optimizationOptions = Options( ...
    'scheduler', options.scheduler, ...
    'verbose', true, ...
    'visualize', false, ...
    'geneticOptions', geneticOptions);

  options.objectiveOptions = objectiveOptions;
  options.optimizationOptions = optimizationOptions;

  options.constraintSet = constraintMap(constraintKey);
end
