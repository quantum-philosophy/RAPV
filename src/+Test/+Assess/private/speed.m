function speed(varargin)
  setup;

  sampleCount = 1e4;

  experiment = Options(varargin{:});
  experimentCount = length(experiment.range);
  repeat = experiment.get('repeat', ones(1, experimentCount));

  fprintf('%20s%20s%20s%20s%20s%20s%20s\n', 'Processors', 'Thermal nodes', ...
    'Variables', 'Quadrature nodes', 'Time steps', 'Chaos, s', 'Speedup, x');

  for i = 1:experimentCount
    options = experiment.configure(experiment.range(i));

    chaos = Temperature.Chaos.DynamicSteadyState(options);

    fprintf('%20d%20d%20d%20d%20d', options.processorCount, ...
      chaos.nodeCount, chaos.process.dimensionCount, ...
      chaos.chaos.nodeCount, options.stepCount);

    totalTime = 0;
    for j = 1:repeat(i)
      time = tic;
      chaos.compute(options.dynamicPower, options.steadyStateOptions);
      totalTime = totalTime + toc(time);
    end

    fprintf('%20.2f', totalTime / repeat(i));
    fprintf('%20.2f', sampleCount / chaos.chaos.nodeCount);
    fprintf('\n');
  end
end
