function output = compute(this, schedule)
  quantities = this.quantities;
  targets = this.targets;
  constraints = this.constraints;

  output = struct;
  output.fitness = NaN(1, targets.count);
  output.violations = NaN(1, quantities.count);

  penalty = 0;

  %
  % The first
  %
  deadline = max(constraints.range{1});
  duration = max(schedule(4, :) + schedule(5, :));

  output.violations(1) = max(0, duration - deadline);

  if output.violations(1) > 0
    penalty = penalty + this.penalize( ...
      output.violations(1), deadline);
  end

  %
  % NOTE: For efficiency, we stop here and do not include in the penalty
  % other potential violations of the constraints.
  %
  if penalty > 0
    output.fitness(:) = this.finalize(0, penalty);
    return;
  end

  %
  % The rest
  %
  surrogateOutput = this.surrogate.compute(this.power.compute(schedule));
  data = this.surrogate.sample(surrogateOutput, this.sampleCount);

  %
  % NOTE: Excluding one to account for the timing constraint.
  %
  for i = setdiff(constraints.index, 1)
    %
    % NOTE: Shifting by one to account for the timing constraint.
    %
    probability = this.computeProbability( ...
      data(:, i - 1), constraints.range{i});

    output.violations(i) = ...
      max(0, constraints.probability(i) - probability);

    if output.violations(i) > 0
      penalty = penalty + this.penalize( ...
        output.violations(i), constraints.probability(i));
    end
  end

  %
  % NOTE: It should be positive for the energy consumption and
  % negative for the maximal temperature and lifetime.
  %
  % NOTE: Shifting by one to account for the timing constraint.
  %
  output.fitness = mean(data(:, targets.index - 1), 1);

  if penalty > 0
    output.fitness = this.finalize(output.fitness, penalty);
  end
end
