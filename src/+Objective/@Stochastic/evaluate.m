function output = evaluate(this, schedule)
  targets = this.targets;
  constraints = this.constraints;

  output = struct;
  output.fitness = NaN(1, targets.count);
  output.violation = NaN(1, constraints.count);

  %
  % Stochastic
  %
  surrogateOutput = this.surrogate.compute(this.power.compute(schedule));
  data = this.surrogate.sample(surrogateOutput, this.sampleCount);

  %
  % NOTE: Excluding the last one as it will be treated separatly.
  %
  for i = 1:(constraints.count - 1)
    j = constraints.index(i);

    probability = this.computeProbability( ...
      data(:, j), constraints.range{i});

    %
    % NOTE: It is assumed that the constraint is a lower bound.
    %
    delta = constraints.probability(i) - probability;
    output.violation(i) = max([ 0, delta ]) / constraints.probability(i);
  end

  %
  % Deterministic
  %
  deadline = max(constraints.range{end});
  duration = max(schedule(4, :) + schedule(5, :));

  delta = duration - deadline;
  output.violation(end) = max(0, delta) / deadline;

  %
  % NOTE: It should be positive for the energy consumption and
  % negative for the maximal temperature and lifetime.
  %
  output.fitness = mean(data(:, targets.index), 1);
end
