function thermalCycles(varargin)
  close all;
  setup;

  options = Test.configure(varargin{:});

  surrogate = Temperature.Chaos.ThermalCyclic(options);

  time = tic;
  [ Tfull, output ] = surrogate.compute( ...
    options.dynamicPower, options.steadyStateOptions);
  time = toc(time);
  fprintf('Polynomial chaos: %.2f s\n', time);

  Plot.thermalCycles(Tfull, output.lifetimeOutput);
  Plot.reliability(Tfull, output.lifetimeOutput);
  Plot.solution(surrogate, output, options.optimizationOptions);
end
