function compute(varargin)
  setup;

  options = Test.configure(varargin{:});
  [ ~, stats, output ] = construct(options, 'sampleCount', 1e5);

  expectation = Utils.toYears(stats.expectation);
  deviation = Utils.toYears(sqrt(stats.variance));

  fprintf('%s:\n', options.surrogate);
  fprintf('  Expectation: %.4f years\n', expectation);
  fprintf('  Deviation:   %.4f years\n', deviation);

  Statistic.observe(Utils.toYears(output.data), 'draw', true, ...
    'method', 'smooth', 'range', 'unbounded');
  Plot.label('Time, years', 'Probability density');
  Plot.vline(expectation, 'Color', Color.pick(2));
  Plot.vline(expectation + deviation, 'Color', Color.pick(3), 'LineStyle', '--');
  Plot.vline(expectation - deviation, 'Color', Color.pick(3), 'LineStyle', '--');
  Plot.legend('Density', 'Expectation', '+/- Deviation');
end
