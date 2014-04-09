function [ quantities, targets, constraints ] = configure(this, options)
  surrogate = options.surrogate;

  quantities = struct;
  quantities.names = [ { 'Time' }, surrogate.quantityNames ];
  quantities.count = length(quantities.names);

  targets = struct;
  targets.names = options.targetNames;
  targets.count = length(targets.names);

  targetIndex = false(1, quantities.count);

  constraints = struct;
  constraints.nominal = zeros(1, quantities.count);
  constraints.quantile = NaN(1, quantities.count);
  constraints.percentile = NaN(1, quantities.count);
  constraints.range = cell(1, quantities.count);
  constraints.probability = NaN(1, quantities.count);

  %
  % The first
  %
  constraints.nominal(1) = ...
    max(options.schedule(4, :) + options.schedule(5, :));
  constraints.range{1} = ...
    options.boundRange('Time', constraints.nominal(1));

  %
  % The rest
  %
  output = surrogate.compute(options.power.compute(options.schedule));
  data = surrogate.sample(output, 1e5);

  for i = 2:quantities.count
    for j = 1:targets.count
      if strcmpi(quantities.names{i}, targets.names{j})
        targetIndex(i) = true;
        break;
      end
    end

    %
    % NOTE: Shifting by one hereafter to account for the timing constraint.
    %
    nominal = mean(data(:, i - 1));
    constraints.nominal(i) = nominal;

    if targetIndex(i), continue; end

    %
    % Compute the prior range and probability
    %
    range = options.boundRange(quantities.names{i}, nominal);
    probability = options.boundProbability(quantities.names{i});

    %
    % Update the range
    %
    % NOTE: computeQuantile uses range only to check the boundedness.
    %
    quantile = this.computeQuantile(data(:, i - 1), range, probability);
    range = options.boundRange(quantities.names{i}, nominal, quantile);

    %
    % Update the probability
    %
    percentile = this.computeProbability(data(:, i - 1), range) * 100;
    probability = options.boundProbability(quantities.names{i}, percentile);

    constraints.quantile(i) = quantile;
    constraints.percentile(i) = percentile;
    constraints.range{i} = range;
    constraints.probability(i) = probability;
  end

  targets.index = find(targetIndex);
  constraints.index = find(~targetIndex);
end
