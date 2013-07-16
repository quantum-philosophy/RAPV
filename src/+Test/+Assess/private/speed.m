function speed(varargin)
  setup;

  sampleCount = 1e4;

  experiment = Options(varargin{:});
  experimentCount = length(experiment.range);
  repeat = experiment.get('repeat', ones(1, experimentCount));

  fprintf('%15s%15s%15s%15s%15s\n', experiment.shortName, ...
    'Dimensions', 'Nodes', 'Chaos, s', 'Speedup, x');

  for i = 1:experimentCount
    parameter = experiment.range(i);

    fprintf('%15d', parameter);

    options = experiment.configure(parameter);

    chaos = Temperature.Chaos.DynamicSteadyState(options);

    fprintf('%15d', chaos.process.dimensionCount);
    fprintf('%15d', chaos.chaos.nodeCount);

    totalTime = 0;
    for j = 1:repeat(i)
      time = tic;
      chaos.compute(options.dynamicPower, options.steadyStateOptions);
      totalTime = totalTime + toc(time);
    end

    fprintf('%15.2f', totalTime / repeat(i));
    fprintf('%15.2f', sampleCount / chaos.chaos.nodeCount);
    fprintf('\n');
  end
end
