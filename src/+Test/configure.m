function options = configure(varargin)
  %
  % System simulation
  %
  options = Configure.systemSimulation('processorCount', 4, ...
    'assetPath', File.join('+Test', 'Assets'), varargin{:});

  %
  % Deterministic analysis
  %
  % reductionLimit = [ 0.45, 0.50, 0.60, 0.60, 0.60 ];
  % modelOrderReduction = Options('threshold', 0, ...
  %   'limit', reductionLimit(log2(options.processorCount)));
  %
  options = Configure.deterministicAnalysis(options, ...
    'temperatureOptions', Options(...
      'analysis', 'DynamicSteadyState', ...
      'algorithm', 2, ...
      'iterationLimit', 10, ...
      'temperatureLimit', Utils.toKelvin(400), ...
      'convergenceTolerance', 0.1, ...
      'modelOrderReduction', [])); % disabled for now

  %
  % Stochastic analysis
  %
  options = Configure.stochasticAnalysis(options, ...
    'surrogate', 'PolynomialChaos', ...
    'surrogateOptions', Options('order', 3));

  %
  % Reliability optimization
  %
  options.optimizationOptions = Options( ...
    'sampleCount', 1e3, ...
    'temperatureLimit', Utils.toKelvin(110), ...
    'deadlineDurationRatio', 1.05, ...
    'verbose', true);

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
