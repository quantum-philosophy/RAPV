function thermalCycles(varargin)
  close all;
  setup;

  options = Test.configure(varargin{:});

  surrogate = Temperature.(options.surrogate).ThermalCyclic( ...
    options, options.steadyStateOptions);

  time = tic;
  [ Tfull, output ] = surrogate.compute(options.dynamicPower);
  fprintf('%s: %.2f s\n', options.surrogate, toc(time));

  Plot.thermalCycles(Tfull, output.lifetimeOutput);
  Plot.reliability(Tfull, output.lifetimeOutput);
  Plot.solution(surrogate, output, options.optimizationOptions);
end
