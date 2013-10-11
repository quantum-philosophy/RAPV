function options = configure(varargin)
  %
  % General configuration:
  %
  %   * platform,
  %   * application,
  %   * power model (dynamic + leakage), and
  %   * thermal model.
  %
  options = Configure.systemSimulation('processorCount', 4, ...
    'assetPath', File.join('+Test', 'Assets'), varargin{:});

  %
  % Model order reduction
  %
  switch options.processorCount
  case 2
    reductionLimit = 0.45;
  case 4
    reductionLimit = 0.50;
  case 8
    reductionLimit = 0.60;
  case 16
    reductionLimit = 0.60;
  case 32
    reductionLimit = 0.60;
  otherwise
    assert(false);
  end
  options.reduceModelOrder = Options( ...
    'threshold', 0, ...
    'limit', reductionLimit);

  %
  % Dynamic steady-state analysis
  %
  options.steadyStateOptions = Options( ...
    'algorithm', 'condensedEquation', ...
    'version', 3, ...
    'iterationLimit', 20, ...
    'temperatureLimit', Utils.toKelvin(400), ...
    'tolerance', 0.5, ...
    'verbose', true);

  %
  % Process variation
  %
  options = Configure.processVariation(options);

  %
  % Surrogate
  %
  options = Configure.surrogate(options);

  %
  % Optimization
  %
  options.optimizationOptions = Options( ...
    'sampleCount', 1e4, ...
    'temperatureLimit', Utils.toKelvin(120), ...
    'deadlineDurationRatio', 1.05);

  %
  % Genetic algorithm
  %
  geneticOptions = gaoptimset;
  geneticOptions.PopulationSize = 20;
  geneticOptions.EliteCount = ...
    floor(0.05 * geneticOptions.PopulationSize); % uniobjective
  geneticOptions.CrossoverFraction = 0.8;
  geneticOptions.ParetoFraction = 1; % multiobjective
  geneticOptions.Generations = 500;
  geneticOptions.StallGenLimit = 20;
  geneticOptions.TolFun = 0;
  geneticOptions.SelectionFcn = @selectiontournament;
  geneticOptions.CrossoverFcn = @crossoversinglepoint;
  geneticOptions.UseParallel = 'never';
  geneticOptions.Vectorized = 'on';
  geneticOptions.MutationRate = 0.01; % non-standard

  options.geneticOptions = geneticOptions;
end
