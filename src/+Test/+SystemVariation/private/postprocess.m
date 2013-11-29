function quantities = postprocess(surrogate, output, options)
  sampleCount = 1e5;

  name = class(surrogate);

  time = tic;
  fprintf('%s: analysis...\n', name);
  stats = surrogate.analyze(output);
  fprintf('%s: done in %.2f seconds.\n', name, toc(time));

  computeExpectation = ~isfield(stats, 'expectation') || ...
    isempty(stats.expectation) || any(isnan(stats.expectation(:)));
  computeVariance = ~isfield(stats, 'variance') || ...
    isempty(stats.variance) || any(isnan(stats.variance(:)));

  if ~isfield(output, 'data')
    time = tic;
    fprintf('%s: collecting %d samples...\n', name, sampleCount);
    output.data = surrogate.sample(output, sampleCount);
    fprintf('%s: done in %.2f seconds.\n', name, toc(time));
  end

  if computeExpectation
    stats.expectation = mean(output.data, 1);
  end

  if computeVariance
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
