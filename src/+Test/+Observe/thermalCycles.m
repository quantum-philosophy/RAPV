function thermalCycles(varargin)
  close all;
  setup;

  options = Test.configure(varargin{:});

  surrogate = TemperatureVariation.(options.surrogate).ThermalCyclic( ...
    options, options.steadyStateOptions);

  time = tic;
  output = surrogate.compute(options.dynamicPower);
  fprintf('%s: %.2f s\n', options.surrogate, toc(time));

  display(surrogate, output);

  Plot.thermalCycles(output.Tfull, output.lifetimeOutput);
  Plot.reliability(output.Tfull, output.lifetimeOutput);
  Plot.solution(surrogate, output, options.optimizationOptions);
end
