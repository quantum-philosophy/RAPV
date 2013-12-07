function constraints = constrain(~, options)
  surrogate = options.surrogate;

  names = surrogate.quantityNames;
  count = surrogate.quantityCount;

  constraints = struct;

  constraints.initialDeadline = ...
    max(options.schedule(4, :) + options.schedule(5, :));
  constraints.deadline = max(options.boundRange( ...
    'time', constraints.initialDeadline));

  constraints.nominal = zeros(1, count);
  constraints.range = cell(1, count);
  constraints.probability = zeros(1, count);
  constraints.initialProbability = zeros(1, count);

  Pdyn = options.power.compute(options.schedule);
  [ T, output ] = surrogate.temperature.compute(Pdyn);
  P = output.P;

  output = surrogate.compute(Pdyn);
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
    initialProbability = diff(ksdensity(data(:, i), range, ...
      'support', 'positive', 'function', 'cdf'));
    probability = options.boundProbability(names{i}, initialProbability);

    constraints.nominal(i) = nominal;
    constraints.range{i} = range;
    constraints.probability(i) = probability;
    constraints.initialProbability(i) = initialProbability;
  end
end
