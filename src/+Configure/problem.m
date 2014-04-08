function options = problem(varargin)
  %
  % System simulation
  %
  options = Configure.systemSimulation('processorCount', 4, ...
    'assetPath', File.join(File.trace, '..', 'Assets'), varargin{:});

  %
  % Deterministic analysis
  %
  options = Configure.deterministicAnalysis( ...
    'processParameters', { 'Leff', 'Tox' }, ...
    'temperatureOptions', Options( ...
      'analysis', 'DynamicSteadyState', ...
      'modelOrderReduction', Options( ...
        'threshold', 0.95, 'limit', 0.60, 'method', 'MatchDC'), ...
      'algorithm', 'condensed-equation-multiple', ...
      'iterationLimit', 10, ...
      'errorMetric', 'NRMSE', ...
      'errorThreshold', 0.01), ...
    options);

  %
  % Stochastic analysis
  %
  options = Configure.stochasticAnalysis( ...
    'parameterOptions', Options( ...
      'transformation', 'Gaussian', ...
      'reductionThreshold', 0.95), ...
    'surrogate', 'PolynomialChaos', ...
    'surrogateOptions', Options( ...
      'order', 3, 'anisotropic', 0.25, ...
      'quadratureOptions', Options('method', 'sparse')), ...
    options);

  %
  % Reliability analysis
  %
  options = Configure.reliabilityAnalysis(options);

  %
  % Optimization
  %
  function range = boundRange(name, nominal, ~)
    switch lower(name)
    case 'time'
      range = [ 0, 2 * nominal ];
    case { 'temperature', 'energy' }
      range = [ 0, nominal ];
    case 'lifetime'
      range = [ nominal, Inf ];
    otherwise
      assert(false);
    end
  end

  function probability = boundProbability(~, ~)
    probability = 0.99;
  end

  options.objectiveOptions = Options( ...
    'targetNames', { 'energy' }, ...
    'power', options.power, ...
    'schedule', options.schedule, ...
    'boundRange', @boundRange, ...
    'boundProbability', @boundProbability, ...
    'sampleCount', 1e3);

  geneticOptions = Options( ...
    'Generations', 100, ...
    'StallGenLimit', 10, ...
    'PopulationSize', 4 * options.taskCount, ...
    'CrossoverFraction', 0.8, ...
    'MutationRate', 0.05, ...
    'SelectionFcn', { @selectiontournament, ...
      floor(0.05 * 4 * options.taskCount) });

  options.optimizationOptions = Options( ...
    'scheduler', options.scheduler, ...
    'verbose', true, ...
    'visualize', false, ...
    'geneticOptions', geneticOptions);
end
