function speed(varargin)
  setup;

  sampleCount = 1e4;

  experiment = Options(varargin{:});
  experimentCount = length(experiment.range);
  repeat = experiment.get('repeat', ones(1, experimentCount));

  fprintf('%20s%20s%20s%20s%20s%20s%20s%20s\n', 'Processors', ...
    'Thermal nodes', 'Random variables', 'Polynomial terms', ...
    'Quadrature nodes', 'Time steps', 'Surrogate, s', 'Speedup, x');

  for i = 1:experimentCount
    options = experiment.configure(experiment.range(i));

    surrogate = SystemVariation(options);

    quadratureNodeCount = surrogate.surrogate.nodeCount;

    fprintf('%20d%20d%20d%20d%20d%20d', ...
      options.processorCount, ...
      surrogate.temperature.nodeCount, ...
      surrogate.surrogate.inputCount, ...
      surrogate.surrogate.termCount, ...
      quadratureNodeCount, ...
      options.stepCount);

    totalTime = 0;
    for j = 1:repeat(i)
      time = tic;
      surrogate.compute(options.dynamicPower);
      totalTime = totalTime + toc(time);
    end

    fprintf('%20.2f', totalTime / repeat(i));
    fprintf('%20.2f', sampleCount / quadratureNodeCount);
    fprintf('\n');
  end
end
