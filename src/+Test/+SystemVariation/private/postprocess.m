function quantities = postprocess(surrogate, output, options)
  sampleCount = 1e5;

  name = class(surrogate);

  time = tic;
  fprintf('%s: analysis...\n', name);
  stats = surrogate.analyze(output);
  fprintf('%s: done in %.2f seconds.\n', name, toc(time));

  if ~isfield(output, 'data')
    time = tic;
    fprintf('%s: collecting %d samples...\n', name, sampleCount);
    output.data = surrogate.sample(output, sampleCount);
    fprintf('%s: done in %.2f seconds.\n', name, toc(time));
  end

  if isempty(stats.expectation)
    stats.expectation = mean(output.data, 1);
  end

  if isempty(stats.variance)
    stats.variance = var(output.data, [], 1);
  end

  quantities = decode(surrogate, output, stats);

  [ T, output ] = surrogate.temperature.compute(options.dynamicPower);
  quantities.temperature.nominal = max(T(:));
  quantities.energy.nominal = options.samplingInterval * sum(output.P(:));
  quantities.lifetime.nominal = surrogate.fatigue.compute(T);
end

function quantities = decode(surrogate, output, stats)
  quantities = struct;

  for i = 1:surrogate.quantityCount
    quantity = struct;
    quantity.expectation = stats.expectation(i);
    quantity.variance = stats.variance(i);
    quantity.data = output.data(:, i);

    quantities.(lower(surrogate.quantityNames{i})) = quantity;
  end
end
