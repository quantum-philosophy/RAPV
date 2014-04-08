function output = compute(this, schedule)
  constraints = this.constraints;

  output = struct;
  output.fitness = NaN(1, this.dimensionCount);
  output.deadlineViolation = NaN;
  output.constraintViolation = NaN(1, constraints.quantityCount);

  penalty = 0;

  %
  % Timing constraint
  %
  duration = max(schedule(4, :) + schedule(5, :));

  output.deadlineViolation = max(0, duration - constraints.deadline);

  if output.deadlineViolation > 0
    penalty = penalty + this.penalize( ...
      output.deadlineViolation, constraints.deadline);
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
  % Other constraints
  %
  surrogateOutput = this.surrogate.compute(this.power.compute(schedule));
  data = this.surrogate.sample(surrogateOutput, this.sampleCount);

  for i = find(~this.targetIndex)
    probability = this.computeProbability( ...
      data(:, i), constraints.range{i});

    output.constraintViolation(i) = ...
      max(0, constraints.probability(i) - probability);

    if output.constraintViolation(i) > 0
      penalty = penalty + this.penalize( ...
        output.constraintViolation(i), constraints.probability(i));
    end
  end

  %
  % TODO: It should be positive for the energy consumption and
  % negative for the maximal temperature and lifetime.
  %
  output.fitness = mean(data(:, this.targetIndex), 1);

  if penalty > 0
    output.fitness = this.finalize(output.fitness, penalty);
  end
end
