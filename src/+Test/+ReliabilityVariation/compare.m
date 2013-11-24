function compare(one, two, varargin)
  setup;

  if nargin < 1, one = {}; end
  if nargin < 2, two = {}; end

  one = Options('surrogate', 'MonteCarlo', one{:});
  two = Options('surrogate', 'PolynomialChaos', two{:});

  options = Test.configure(varargin{:}, one);
  [ ~, oneStats, oneOutput ] = construct(options);

  options = Test.configure(varargin{:}, two);
  [ ~, twoStats, twoOutput ] = construct(options);

  fprintf('%s:\n', one.surrogate);
  fprintf('  Expectation: %.4f years\n', ...
    Utils.toYears(oneStats.expectation));
  fprintf('  Deviation:   %.4f years\n', ...
    Utils.toYears(sqrt(oneStats.variance)));

  fprintf('%s:\n', two.surrogate);
  fprintf('  Expectation: %.4f years\n', ...
    Utils.toYears(twoStats.expectation));
  fprintf('  Deviation:   %.4f years\n', ...
    Utils.toYears(sqrt(twoStats.variance)));

  Statistic.compare(Utils.toYears(oneOutput.data), ...
    Utils.toYears(twoOutput.data), 'draw', true, ...
    'method', 'smooth', 'range', 'unbounded', ...
    'names', { one.surrogate, two.surrogate });
  Plot.label('Time, years', 'Probability density');
end
