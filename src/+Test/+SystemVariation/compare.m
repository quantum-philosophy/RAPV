function compare(one, two, varargin)
  setup;

  if nargin < 1, one = {}; end
  if nargin < 2, two = {}; end

  names = { 'MonteCarlo', 'PolynomialChaos' };

  one = Options('surrogate', names{1}, one{:});
  two = Options('surrogate', names{2}, two{:});

  options = Test.configure(varargin{:}, one);
  [ oneSurrogate, oneOutput ] = construct(options);
  oneStats = postprocess(oneSurrogate, oneOutput, options);

  options = Test.configure(varargin{:}, two);
  [ twoSurrogate, twoOutput ] = construct(options);
  twoStats = postprocess(twoSurrogate, twoOutput, options);

  fprintf('Maximal temperature:\n');
  Print.structComparison('names', names, 'values', ...
    { oneStats.temperature, twoStats.temperature }, ...
    'exclude', @(name, ~) ~strcmp(name, 'data'));
  fprintf('\n');

  fprintf('Energy consumption:\n');
  Print.structComparison('names', names, 'values', ...
    { oneStats.energy, twoStats.energy }, ...
    'exclude', @(name, ~) ~strcmp(name, 'data'));
  fprintf('\n');

  fprintf('Mean time to failure:\n');
  Print.structComparison('names', names, 'values', ...
    { oneStats.lifetime, twoStats.lifetime }, ...
    'exclude', @(name, ~) ~strcmp(name, 'data'));

  Utils.compareDistributions( ...
    Utils.toCelsius(oneStats.temperature.data), ...
    Utils.toCelsius(twoStats.temperature.data), ...
    'method', 'smooth', 'range', 'unbounded', 'names', names);
  Plot.label('Maximal temperature, C', 'Probability density');

  Utils.compareDistributions( ...
    oneStats.energy.data, ...
    twoStats.energy.data, ...
    'method', 'smooth', 'range', 'unbounded', 'names', names);
  Plot.label('Energy, J', 'Probability density');

  Utils.compareDistributions( ...
    Utils.toYears(oneStats.lifetime.data), ...
    Utils.toYears(twoStats.lifetime.data), ...
    'method', 'smooth', 'range', 'unbounded', 'names', names);
  Plot.label('Time, years', 'Probability density');
end
