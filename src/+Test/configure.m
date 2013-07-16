function options = configure(varargin)
  options = Configure.systemSimulation(varargin{:});
  options.leakageModel = 'PolynomialRegression';
  options.leakageOptions.LCount = 50;
  options.leakageOptions.TCount = 50;
  options.leakageOptions.TLimit = Utils.toKelvin([0, 400]);
  options.leakageOptions.order = [ 3, 2 ];

  options = Configure.processVariation(options);
  options.processModel = 'Normal';
  options.processOptions.threshold = 0.96;

  options = Configure.polynomialChaos(options);
  options.surrogateOptions.order = 4;

  options.steadyStateOptions = Options( ...
    'algorithm', 'condensedEquation', ...
    'version', 2, ...
    'iterationLimit', 20, ...
    'temperatureLimit', Utils.toKelvin(1e3), ...
    'tolerance', 0.5);
end
