function options = configure(varargin)
  options = Configure.systemSimulation(varargin{:});
  options = Configure.processVariation(options);
  options = Configure.polynomialChaos(options);
end
