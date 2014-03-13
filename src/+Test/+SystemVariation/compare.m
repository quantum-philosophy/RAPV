function compare(one, two, varargin)
  setup;

  if nargin < 1, one = {}; end
  if nargin < 2, two = {}; end

  names = { 'MonteCarlo', 'PolynomialChaos' };

  one = Options('surrogate', names{1}, one{:});
  two = Options('surrogate', names{2}, two{:});

  options = Configure.problem(varargin{:}, one);
  [ oneSurrogate, oneOutput ] = construct(options);
  oneStats = postprocess(oneSurrogate, oneOutput);

  options = Configure.problem(varargin{:}, two);
  [ twoSurrogate, twoOutput ] = construct(options);
  twoStats = postprocess(twoSurrogate, twoOutput);

  Utils.compareDistributions( ...
    oneStats.temperature.data, twoStats.temperature.data, ...
    'method', 'smooth', 'range', 'unbounded', 'names', names);
  Plot.label('Maximal temperature', 'Probability density');

  Utils.compareDistributions( ...
    oneStats.energy.data, twoStats.energy.data, ...
    'method', 'smooth', 'range', 'unbounded', 'names', names);
  Plot.label('Energy consumption', 'Probability density');

  Utils.compareDistributions( ...
    oneStats.lifetime.data, twoStats.lifetime.data, ...
    'method', 'smooth', 'range', 'unbounded', 'names', names);
  Plot.label('Reliability parametrization', 'Probability density');
end