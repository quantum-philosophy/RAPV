function options = configure(varargin)
  options = Configure.systemSimulation(varargin{:});
  options = Configure.processVariation(options);
  options = Configure.polynomialChaos(options);

  options.steadyStateOptions = Options( ...
    'iterationLimit', 20, ...
    'temperatureLimit', Utils.toKelvin(1e3), ...
    'tolerance', 0.5);
end
