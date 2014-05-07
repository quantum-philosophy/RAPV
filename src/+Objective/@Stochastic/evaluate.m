function output = evaluate(this, schedule)
  quantities = this.quantities;

  output = struct;
  output.expectation = NaN(1, quantities.count);
  output.violation = NaN(1, quantities.count);

  %
  % Deterministic
  %
  deadline = max(quantities.range{end});
  output.expectation(end) = max(schedule(4, :) + schedule(5, :));

  delta = output.expectation(end) - deadline;
  output.violation(end) = max(0, delta) / deadline;

  if output.violation(end) > 0
    %
    % NOTE: We stop here to cut down the computational time.
    %
    return;
  end

  %
  % Stochastic
  %
  surrogateOutput = this.surrogate.compute(this.power.compute(schedule));
  data = this.surrogate.sample(surrogateOutput, this.sampleCount);

  %
  % NOTE: Excluding the last one as it is treated separatly.
  %
  for i = quantities.constraintIndex(1:(end - 1))
    probability = this.computeProbability( ...
      data(:, i), quantities.range{i}, true); % crude

    %
    % NOTE: It is assumed that the constraint is a lower bound.
    %
    delta = quantities.probability(i) - probability;
    output.violation(i) = max([ 0, delta ]) / quantities.probability(i);
  end

  output.expectation(1:(end - 1)) = mean(data, 1);
end
