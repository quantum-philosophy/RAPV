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
  options.leakageModel = 'LinearInterpolation';
  options.leakageOptions.LCount = 50;
  options.leakageOptions.TCount = 50;
  options.leakageOptions.TLimit = Utils.toKelvin([ 0, 400 ]);
  options.leakageOptions.order = [ 3, 2 ];

  %
  % Model order reduction
  %
  options.reductionThreshold = 0;
  switch options.processorCount
  case 2
    options.reductionLimit = 0.45;
  case 4
    options.reductionLimit = 0.50;
  case 8
    options.reductionLimit = 0.60;
  case 16
    options.reductionLimit = 0.60;
  case 32
    options.reductionLimit = 0.60;
  otherwise
    assert(false);
  end

  %
  % Dynamic steady-state analysis
  %
  options.steadyStateOptions = Options( ...
    'algorithm', 'condensedEquation', ...
    'version', 2, ...
    'iterationLimit', 20, ...
    'temperatureLimit', Utils.toKelvin(400), ...
    'tolerance', 0.5, ...
    'verbose', true);

  %
  % Process variation
  %
  options = Configure.processVariation(options);
  options.processModel = 'Normal';
  options.processOptions.reductionThreshold = 0.96;

  %
  % Polynomial chaos expansions
  %
  options = Configure.polynomialChaos(options);
  options.surrogateOptions.order = 4;

  %
  % Optimization
  %
  options.optimizationOptions = Options( ...
    'sampleCount', 1e4, ...
    'temperatureLimit', Utils.toKelvin(120));

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
