function thermalCycles
  close all;
  setup;

  options = Test.configure;

  temperature = Temperature.Analytical.DynamicSteadyState( ...
    options.temperatureOptions);
  T = temperature.compute(options.dynamicPower, ...
    options.steadyStateOptions);

  lifetime = Lifetime('samplingInterval', options.samplingInterval);
  [ ~, lifetimeOutput ] = lifetime.predict(T);

  Plot.thermalCycles(T, lifetimeOutput);
  Plot.reliability(T, lifetimeOutput);

  I = Utils.constructPeakIndex(lifetimeOutput);

  fprintf('Number of significant steps: %d out of %d\n', ...
    length(I), options.stepCount);

  pc = Temperature.Chaos.ThermalCyclic(options);

  time = tic;
  [ Texp, chaosOutput ] = pc.compute(options.dynamicPower, ...
    options.steadyStateOptions, 'lifetime', lifetimeOutput);
  time = toc(time);

  fprintf('Solution time: %.2f s\n', time);

  Plot.temperatureVariation(options.timeLine, Texp, chaosOutput.Tvar, ...
    'index', lifetimeOutput.peakIndex);
end
