function quantities = configure(this, options)
  surrogate = options.surrogate;

  quantities = struct;

  quantities.names = [ surrogate.quantityNames, { 'Time' } ];
  quantities.count = length(quantities.names);
  quantities.nominal = zeros(1, quantities.count);

  quantities.targetIndex = false(1, quantities.count);
  quantities.constraintIndex = false(1, quantities.count);
  quantities.quantile = NaN(1, quantities.count);
  quantities.percentile = NaN(1, quantities.count);
  quantities.range = cell(1, quantities.count);
  quantities.probability = NaN(1, quantities.count);

  %
  % Targets
  %
  for i = 1:length(options.targetNames)
    for j = 1:quantities.count
      if strcmpi(options.targetNames{i}, quantities.names{j})
      quantities.targetIndex(j) = true;
      break;
    end
  end

  %
  % Stochastic constraints
  %
  output = surrogate.compute(options.power.compute(options.schedule));
  data = surrogate.sample(output, this.sampleCount);

  %
  % NOTE: Excluding the last one as it will be treated separatly.
  %
  for i = 1:(quantities.count - 1)
    for j = 1:length(options.constraintNames)
      if strcmpi(quantities.names{i}, options.constraintNames{j})
        quantities.constraintIndex(i) = true;
        break;
      end
    end

    nominal = mean(data(:, i));
    quantities.nominal(i) = nominal;

    if ~quantities.constraintIndex(i), continue; end

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

    quantities.quantile(i) = quantile;
    quantities.percentile(i) = percentile;
    quantities.range{i} = range;
    quantities.probability(i) = probability;
  end

  %
  % Deterministic constraints
  %
  quantities.constraintIndex(end) = true;
  quantities.nominal(end) = ...
    max(options.schedule(4, :) + options.schedule(5, :));
  quantities.range{end} = ...
    options.boundRange('Time', quantities.nominal(end));

  quantities.targetIndex = find(quantities.targetIndex);
  quantities.constraintIndex = find(quantities.constraintIndex);
end
