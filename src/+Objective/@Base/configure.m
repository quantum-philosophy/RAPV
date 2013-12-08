function [ targetIndex, constraints ] = configure(this, options)
  surrogate = options.surrogate;

  quantityNames = surrogate.quantityNames;
  quantityCount = length(quantityNames);

  targetNames = options.targetNames;
  targetIndex = false(1, quantityCount);

  constraints = struct;

  constraints.duration = ...
    max(options.schedule(4, :) + options.schedule(5, :));
  constraints.deadline = max(options.boundRange( ...
    'time', constraints.duration));

  constraints.nominal = zeros(1, quantityCount);
  constraints.quantile = NaN(1, quantityCount);
  constraints.percentile = NaN(1, quantityCount);
  constraints.range = cell(1, quantityCount);
  constraints.probability = NaN(1, quantityCount);

  Pdyn = options.power.compute(options.schedule);
  [ T, output ] = surrogate.temperature.compute(Pdyn);
  P = output.P;

  output = surrogate.compute(Pdyn);
  data = surrogate.sample(output, 1e5);

  for i = 1:quantityCount
    for j = 1:length(targetNames)
      if strcmpi(quantityNames{i}, targetNames{j})
        targetIndex(i) = true;
        break;
      end
    end

    switch lower(quantityNames{i})
    case 'temperature'
      nominal = max(T(:));
    case 'energy'
      nominal = surrogate.temperature.samplingInterval * sum(P(:));
    case 'lifetime'
      nominal = surrogate.fatigue.compute(T);
    otherwise
      assert(false);
    end
    constraints.nominal(i) = nominal;

    if targetIndex(i), continue; end

    %
    % Compute the prior range and probability
    %
    range = options.boundRange(quantityNames{i}, nominal);
    probability = options.boundProbability(quantityNames{i});

    %
    % Update the range
    %
    % NOTE: computeQuantile uses range only to check the boundedness.
    %
    quantile = this.computeQuantile(data(:, i), range, probability);
    range = options.boundRange(quantityNames{i}, nominal, quantile);

    %
    % Update the probability
    %
    percentile = this.computeProbability(data(:, i), range) * 100;
    probability = options.boundProbability(quantityNames{i}, percentile);

    constraints.quantile(i) = quantile;
    constraints.percentile(i) = percentile;
    constraints.range{i} = range;
    constraints.probability(i) = probability;
  end
end
