function compare(varargin)
  setup;

  data1 = construct('PolynomialChaos');
  data2 = construct('MonteCarlo');

  Statistic.compare(data1, data2, 'draw', true, ...
    'method', 'smooth', 'range', 'unbounded', ...
    'names', { 'PolynomialChaos', 'MonteCarlo' });
  Plot.label('Time, years', 'Probability density');
end

function data = construct(surrogate, varargin)
  options = Test.configure(varargin{:}, 'surrogate', surrogate);

  reliability = ReliabilityVariation(options);
  output = reliability.compute(options.dynamicPower);

  stats = reliability.analyze(output);

  fprintf('%s:\n', surrogate);
  fprintf('  Expectation: %.2f years\n', Utils.toYears(stats.expectation));
  fprintf('  Deviation:   %.2f years\n', Utils.toYears(sqrt(stats.variance)));

  if isfield(output, 'data')
    data = output.data;
  else
    data = reliability.sample(output, 1e5);
  end

  data = Utils.toYears(data);
end
