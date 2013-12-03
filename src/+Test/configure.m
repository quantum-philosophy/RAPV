function options = configure(varargin)
  %
  % System simulation
  %
  options = Configure.systemSimulation('processorCount', 4, ...
    'assetPath', File.join(File.trace, '..', 'Assets'), varargin{:});

  %
  % Deterministic analysis
  %
  % NOTE: One potential model order reduction is as follows:
  %
  % modelOrderReduction = Options('threshold', 0.995, 'limit', 0.60);
  %
  % However, in some cases, the system becomes unstable, especially
  % in the case of the dynamic steady-state temperature analysis.
  %
  options = Configure.deterministicAnalysis( ...
    'temperatureOptions', Options( ...
      'analysis', 'DynamicSteadyState', ...
      'algorithm', 1, ...
      'iterationLimit', 10, ...
      'convergenceMetric', 'NRMSE', ...
      'convergenceTolerance', 0.01, ...
      'modelOrderReduction', []), ...
    options); % disabled for now

  %
  % Stochastic analysis
  %
  options = Configure.stochasticAnalysis( ...
    'surrogate', 'PolynomialChaos', ...
    'surrogateOptions', Options( ...
      'order', 4, 'anisotropic', 0.25), ...
    options);

  %
  % Reliability analysis
  %
  options = Configure.reliabilityAnalysis(options);

  %
  % Optimization
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
