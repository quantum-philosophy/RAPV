function output = evaluate(this, schedule)
  quantities = this.quantities;

  output = struct;
  output.violation = NaN(1, quantities.count);

  %
  % Stochastic
  %
  surrogateOutput = this.surrogate.compute(this.power.compute(schedule));
  data = this.surrogate.sample(surrogateOutput, this.sampleCount);

  %
  % NOTE: Excluding the last one as it will be treated separatly.
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

  %
  % Deterministic
  %
  deadline = max(quantities.range{end});
  duration = max(schedule(4, :) + schedule(5, :));

  delta = duration - deadline;
  output.violation(end) = max(0, delta) / deadline;

  output.expectation = [ mean(data, 1), duration ];
end
