function thermalCycles
  close all;
  setup;

  options = Test.configure;

  pc = Temperature.Chaos.ThermalCyclic(options);

  time = tic;
  [ Texp, output ] = pc.compute( ...
    options.dynamicPower, options.steadyStateOptions);
  time = toc(time);
  fprintf('Polynomial chaos: %.2f s\n', time);

  Plot.thermalCycles(output.Tfull, output.lifetimeOutput);
  Plot.reliability(output.Tfull, output.lifetimeOutput);

  I = Utils.constructPeakIndex(output.lifetimeOutput);

  fprintf('Number of significant steps: %d out of %d\n', ...
    length(I), options.stepCount);

  Plot.temperatureVariation(options.timeLine, ...
    Texp, output.Tvar, 'index', output.lifetimeOutput.peakIndex);
end
