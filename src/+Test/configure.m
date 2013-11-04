function options = configure(varargin)
  options = Options(varargin{:});
  verbose = options.get('verbose', true);

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
  reductionLimit = [ 0.45, 0.50, 0.60, 0.60, 0.60 ];
  options.reduceModelOrder = Options( ...
    'threshold', 0, ...
    'limit', reductionLimit(log2(options.processorCount)));

  %
  % Dynamic steady-state analysis
  %
  options.steadyStateOptions = Options( ...
    'algorithmVersion', 1, ...
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
  options = Configure.temperatureVariation(options);
  switch options.surrogate
  case 'PolynomialChaos'
    options.surrogateOptions.update('order', 3);
  case 'StochasticCollocation'
    options.surrogateOptions.update( ...
      'method', 'Global', ...
      'basis', 'ChebyshevLagrange', ...
      'absoluteTolerance', 1e-1, ...
      'relativeTolerance', 1e-2, ...
      'maximalLevel', 10, ...
      'maximalNodeCount', 1e3, ...
      'verbose', verbose);
  otherwise
    assert(false);
  end

  %
  % Optimization
  %
  options.optimizationOptions = Options( ...
    'sampleCount', 1e3, ...
    'temperatureLimit', Utils.toKelvin(120), ...
    'deadlineDurationRatio', 1.05, ...
    'verbose', verbose);

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
