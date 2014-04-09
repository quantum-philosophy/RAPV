function [ quantities, targets, constraints ] = configure(this, options)
  surrogate = options.surrogate;
  targetNames = options.targetNames;

  quantities = struct;

  quantities.names = [ surrogate.quantityNames, { 'Time' } ];
  quantities.count = length(quantities.names);
  quantities.nominal = zeros(1, quantities.count);

  targets = struct;
  targets.count = length(targetNames);

  constraints = struct;
  constraints.count = quantities.count - targets.count;
  constraints.quantile = NaN(1, constraints.count);
  constraints.percentile = NaN(1, constraints.count);
  constraints.range = cell(1, constraints.count);
  constraints.probability = NaN(1, constraints.count);

  %
  % NOTE: Excluding the last one as we do not count time.
  %
  isTarget = false(1, quantities.count);
  for i = 1:(quantities.count - 1)
    for j = 1:targets.count
      if strcmpi(quantities.names{i}, targetNames{j})
        isTarget(i) = true;
        break;
      end
    end
  end

  targets.index = find(isTarget);
  constraints.index = find(~isTarget);

  %
  % Stochastic
  %
  output = surrogate.compute(options.power.compute(options.schedule));
  data = surrogate.sample(output, 1e5);

  %
  % NOTE: Excluding the last one as it will be treated separatly.
  %
  j = 0;
  for i = 1:(quantities.count - 1)
    nominal = mean(data(:, i));
    quantities.nominal(i) = nominal;

    if isTarget(i), continue; end

    %
    % Compute the prior range and probability
    %
    range = options.boundRange(quantities.names{i}, nominal);
    probability = options.boundProbability(quantities.names{i});

    %
    % Update the range
    %
    quantile = this.computeQuantile(data(:, i), range, probability);
    range = options.boundRange(quantities.names{i}, nominal, quantile);

    %
    % Update the probability
    %
    percentile = this.computeProbability(data(:, i), range) * 100;
    probability = options.boundProbability(quantities.names{i}, percentile);

    j = j + 1;

    constraints.quantile(j) = quantile;
    constraints.percentile(j) = percentile;
    constraints.range{j} = range;
    constraints.probability(j) = probability;
  end

  %
  % Deterministic
  %
  quantities.nominal(end) = ...
    max(options.schedule(4, :) + options.schedule(5, :));
  constraints.range{end} = ...
    options.boundRange('Time', quantities.nominal(end));
end
