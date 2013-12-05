function quantities = constraints(surrogate, options)
  names = surrogate.quantityNames;
  count = surrogate.quantityCount;

  quantities = struct;
  quantities.nominal = zeros(1, count);
  quantities.range = cell(1, count);
  quantities.probability = zeros(1, count);
  quantities.initialProbability = zeros(1, count);

  [ T, output ] = surrogate.temperature.compute(options.dynamicPower);
  P = output.P;

  output = surrogate.compute(options.dynamicPower);
  data = surrogate.sample(output, options.objectiveOptions.sampleCount);

  boundRange = options.objectiveOptions.boundRange;
  boundProbability = options.objectiveOptions.boundProbability;

  for i = 1:count
    switch lower(names{i})
    case 'temperature'
      nominal = max(T(:));
    case 'energy'
      nominal = options.samplingInterval * sum(P(:));
    case 'lifetime'
      nominal = surrogate.fatigue.compute(T);
    otherwise
      assert(false);
    end
    range = boundRange(names{i}, nominal);
    initialProbability = mean(range(1) < data(:, i) & data(:, i) < range(2));
    probability = boundProbability(names{i}, initialProbability);

    quantities.nominal(i) = nominal;
    quantities.range{i} = range;
    quantities.probability(i) = probability;
    quantities.initialProbability(i) = initialProbability;
  end
end
