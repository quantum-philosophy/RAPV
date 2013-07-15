function options = configure(varargin)
  options = Configure.systemSimulation(varargin{:});

  options = Configure.processVariation(options);
  options.processOptions.threshold = 0.95;
  options.processModel = 'Normal';

  options = Configure.polynomialChaos(options);
  options.surrogateOptions.order = 4;

  options.steadyStateOptions = Options( ...
    'algorithm', 'condensedEquation', ...
    'version', 2, ...
    'iterationLimit', 20, ...
    'temperatureLimit', Utils.toKelvin(1e3), ...
    'tolerance', 0.5);
end
