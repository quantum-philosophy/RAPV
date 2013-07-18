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
  Plot.solution(pc, output, options.optimizationOptions);
end
