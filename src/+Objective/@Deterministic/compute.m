function output = compute(this, schedule)
  quantities = this.quantities;
  targets = this.targets;
  constraints = this.constraints;

  output = struct;
  output.fitness = NaN(1, targets.count);
  output.deadlineViolation = NaN;
  output.constraintViolation = NaN(1, quantities.count);

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
  [ T, temperatureOutput ] = this.surrogate.temperature.computeWithLeakage( ...
    this.power.compute(schedule));

  data = [ ...
  	max(T(:)), ...
  	this.surrogate.temperature.samplingInterval * sum(temperatureOutput.P(:)), ...
    this.surrogate.fatigue.compute(T) ...
  ];

  for i = setdiff(constraints.index, 1)
    range = constraints.range{i};

    %
    % NOTE: Shifting by one to account for the timing constraint.
    %
    output.violations(i) = max([ 0, ...
      range(1) - data(i - 1), data(i - 1) - range(2) ]);

    if output.violations(i) > 0
      penalty = penalty + this.penalize( ...
        output.violations(i), constraints.nominal(i));
    end
  end

  %
  % TODO: It should be positive for the energy consumption and
  % negative for the maximal temperature and lifetime.
  %
  % NOTE: Shifting by one to account for the timing constraint.
  %
  output.fitness = data(targets.index - 1);

  if penalty > 0
    output.fitness = this.finalize(output.fitness, penalty);
  end
end
