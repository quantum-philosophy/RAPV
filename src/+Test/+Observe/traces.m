function traces
  close all;
  setup;
  rng(1);

  errorMetric = 'RMSE';
  stepCount = 1e3;
  sampleCount = 1e4;

  options = Test.configure('stepCount', stepCount);

  %
  % Monte Carlo
  %
  one = Temperature.MonteCarlo.DynamicSteadyState(options);

  [ oneTexp, oneOutput ] = one.compute(options.dynamicPower, ...
    options.steadyStateOptions, 'sampleCount', sampleCount, ...
    'verbose', true);

  %
  % Polynomial chaos
  %
  two = Temperature.Chaos.DynamicSteadyState(options);

  [ twoTexp, twoOutput ] = two.compute(options.dynamicPower, ...
      options.steadyStateOptions);

  %
  % Comparison
  %
  Plot.temperatureVariation({ oneTexp, twoTexp }, ...
    { oneOutput.Tvar, twoOutput.Tvar }, ...
    'time', options.timeLine, 'names', { 'MonteCarlo', 'Chaos' });

  oneTstd = sqrt(oneOutput.Tvar);
  twoTstd = sqrt(twoOutput.Tvar);

  fprintf('%10s %15s %15s %15s\n', 'Processor', ...
    [ errorMetric, '(Exp)' ], [ errorMetric, '(Std)' ], ...
    [ errorMetric, '(Var)' ]);
  for i = 1:options.processorCount
    fprintf('%10d %15.4f %15.4f %15.4f\n', i, ...
      Error.compute(errorMetric, oneTexp(i, :), twoTexp(i, :)), ...
      Error.compute(errorMetric, oneTstd(i, :), twoTstd(i, :)), ...
      Error.compute(errorMetric, oneOutput.Tvar(i, :), twoOutput.Tvar(i, :)));
  end

  fprintf('--\n');
  fprintf('%10s %15.4f %15.4f %15.4f\n', '', ...
    Error.compute(errorMetric, oneTexp, twoTexp), ...
    Error.compute(errorMetric, oneTstd, twoTstd), ...
    Error.compute(errorMetric, oneOutput.Tvar, twoOutput.Tvar));
end
