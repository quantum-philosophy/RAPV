function compute(varargin)
  setup;

  options = Test.configure(varargin{:});
  [ surrogate, stats, output ] = construct(options, 'sampleCount', 1e5);

  expectation = Utils.toYears(stats.expectation);
  deviation = Utils.toYears(sqrt(stats.variance));

  T = surrogate.temperature.computeWithLeakage(options.dynamicPower);
  nominal = Utils.toYears(surrogate.fatigue.compute(T));

  fprintf('%s:\n', options.surrogate);
  fprintf('  Nominal:     %.4f years\n', nominal);
  fprintf('  Expectation: %.4f years\n', expectation);
  fprintf('  Deviation:   %.4f years\n', deviation);

  Statistic.observe(Utils.toYears(output.data), 'draw', true, ...
    'method', 'smooth', 'range', 'unbounded');
  Plot.label('Time, years', 'Probability density');
  Plot.vline(nominal, 'Color', Color.pick(2));
  Plot.vline(expectation, 'Color', Color.pick(3));
  Plot.vline(expectation + deviation, 'Color', Color.pick(3), 'LineStyle', '--');
  Plot.vline(expectation - deviation, 'Color', Color.pick(3), 'LineStyle', '--');
  Plot.legend('Density', 'Nominal', 'Expectation', '+/- Deviation');

  limit = xlim;
  xlim([ 0, limit(2) ]);
end
