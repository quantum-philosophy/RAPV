function quantities = constrain(~, options)
  surrogate = options.surrogate;

  names = surrogate.quantityNames;
  count = surrogate.quantityCount;

  quantities = struct;
  quantities.nominal = zeros(1, count);
  quantities.lowerBound = zeros(1, count);
  quantities.upperBound = zeros(1, count);
  quantities.probability = zeros(1, count);
  quantities.initialProbability = zeros(1, count);

  [ T, output ] = surrogate.temperature.compute(options.referencePower);
  P = output.P;

  output = surrogate.compute(options.referencePower);
  data = surrogate.sample(output, 1e5);

  for i = 1:count
    switch lower(names{i})
    case 'temperature'
      nominal = max(T(:));
    case 'energy'
      nominal = surrogate.temperature.samplingInterval * sum(P(:));
    case 'lifetime'
      nominal = surrogate.fatigue.compute(T);
    otherwise
      assert(false);
    end
    range = options.boundRange(names{i}, nominal);
    initialProbability = mean(range(1) < data(:, i) & data(:, i) < range(2));
    probability = options.boundProbability(names{i}, initialProbability);

    quantities.nominal(i) = nominal;
    quantities.lowerBound(i) = range(1);
    quantities.upperBound(i) = range(2);
    quantities.probability(i) = probability;
    quantities.initialProbability(i) = initialProbability;
  end
end
