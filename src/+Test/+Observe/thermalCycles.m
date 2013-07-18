function thermalCycles
  close all;
  setup;

  options = Test.configure;

  pc = Temperature.Chaos.ThermalCyclic(options);

  time = tic;
  [ Tfull, output ] = pc.compute( ...
    options.dynamicPower, options.steadyStateOptions);
  time = toc(time);
  fprintf('Polynomial chaos: %.2f s\n', time);

  Plot.thermalCycles(Tfull, output.lifetimeOutput);
  Plot.reliability(Tfull, output.lifetimeOutput);

  I = Utils.constructPeakIndex(output.lifetimeOutput);

  fprintf('Number of significant steps: %d out of %d\n', ...
    length(I), options.stepCount);

  Texp = Utils.unpackPeaks(output.expectation, output.lifetimeOutput);
  Tvar = Utils.unpackPeaks(output.variance, output.lifetimeOutput);

  Plot.temperatureVariation(options.timeLine, ...
    Texp, Tvar, 'index', output.lifetimeOutput.peakIndex);
end
