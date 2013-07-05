function traces
  close all;
  setup;
  rng(1);

  stepCount = 1e2;
  mcSampleCount = 1e5;
  chaosSampleCount = 1e5;

  options = Test.configure('stepCount', stepCount);

  %
  % Polynomial chaos
  %
  pc = Temperature.Chaos.DynamicSteadyState(options);

  [ pcTexp, pcOutput ] = pc.compute(options.dynamicPower, ...
      options.steadyStateOptions);
  pcOutput.Tdata = pc.sample(pcOutput, chaosSampleCount);

  %
  % Monte Carlo
  %
  mc = Temperature.MonteCarlo.DynamicSteadyState(options);

  [ mcTexp, mcOutput ] = mc.compute(options.dynamicPower, ...
    options.steadyStateOptions, 'sampleCount', mcSampleCount, ...
    'verbose', true);

  %
  % Comparison
  %
  Utils.plotTemperatureVariation( ...
    options.samplingInterval * (0:(stepCount - 1)), ...
    { pcTexp, mcTexp }, { pcOutput.Tvar, mcOutput.Tvar }, ...
    'labels', { 'PC', 'MC' });

  pcTstd = sqrt(pcOutput.Tvar);
  mcTstd = sqrt(mcOutput.Tvar);

  fprintf('%10s %15s %15s %15s\n', 'Processor', ...
    'Exp, C', 'Std, C', 'Var, C^2');
  for i = 1:options.processorCount
    fprintf('%10d %15.4f %15.4f %15.4f\n', i, ...
      Error.compute('RMSE', mcTexp(i, :), pcTexp(i, :)), ...
      Error.compute('RMSE', mcTstd(i, :), pcTstd(i, :)), ...
      Error.compute('RMSE', mcOutput.Tvar(i, :), pcOutput.Tvar(i, :)));
  end

  fprintf('--\n');
  fprintf('%10s %15.4f %15.4f %15.4f\n', '', ...
    Error.compute('RMSE', mcTexp, pcTexp), ...
    Error.compute('RMSE', mcTstd, pcTstd), ...
    Error.compute('RMSE', mcOutput.Tvar, pcOutput.Tvar));
end
