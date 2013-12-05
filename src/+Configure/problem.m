function options = problem(varargin)
  %
  % System simulation
  %
  options = Configure.systemSimulation( ...
    'assetPath', File.join(File.trace, '..', 'Assets'), varargin{:});

  %
  % Deterministic analysis
  %
  options = Configure.deterministicAnalysis( ...
    'temperatureOptions', Options( ...
      'analysis', 'DynamicSteadyState', ...
      'modelOrderReduction', Options( ...
        'threshold', 0.95, 'limit', 0.60, 'method', 'MatchDC'), ...
      'algorithm', 1, ...
      'iterationLimit', 10, ...
      'errorMetric', 'NRMSE', ...
      'errorThreshold', 0.01), ...
    options);

  %
  % Stochastic analysis
  %
  options = Configure.stochasticAnalysis( ...
    'parameterOptions', Options( ...
      'reductionThreshold', 0.96), ...
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
  function range = boundRange(name, nominal)
    switch lower(name)
    case 'temperature'
      range = [ -Inf, Utils.toKelvin(100) ];
    case 'energy'
      range = [ -Inf, 1.1 * nominal ];
    case 'lifetime'
      range = [ 0.8 * nominal, Inf ];
    otherwise
      assert(false);
    end
  end

  function probability = boundProbability(name, initial)
    if ~(initial > 0 && initial < 1)
      warning([ 'The initial probability for ', lower(name), ...
        ' is ', num2str(initial), '.' ]);
    end

    probability = 0.95;

    switch lower(name)
    case 'temperature'
    case 'energy'
    case 'lifetime'
    otherwise
      assert(false);
    end
  end

  options.objectiveOptions = Options('sampleCount', 1e3, ...
    'boundRange', @boundRange, 'boundProbability', @boundProbability);
  options.optimizationOptions = [];
end
