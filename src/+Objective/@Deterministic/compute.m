function output = compute(this, schedule)
  quantities = this.quantities;
  targets = this.targets;
  constraints = this.constraints;

  output = struct;
  output.fitness = NaN(1, targets.count);
  output.violations = NaN(1, constraints.count);

  penalty = 0;

  %
  % Deterministic
  %
  deadline = max(constraints.range{end});
  duration = max(schedule(4, :) + schedule(5, :));

  output.violations(end) = max(0, duration - deadline);

  if output.violations(end) > 0
    penalty = penalty + this.penalize( ...
      output.violations(end), deadline);
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
  % Stochastic (but here deterministic)
  %
  [ T, temperatureOutput ] = this.surrogate.temperature.computeWithLeakage( ...
    this.power.compute(schedule));

  data = [ ...
  	max(T(:)), ...
  	this.surrogate.temperature.samplingInterval * sum(temperatureOutput.P(:)), ...
    this.surrogate.fatigue.compute(T) ...
  ];

  %
  % NOTE: Excluding the last one as it has already been treated.
  %
  for i = 1:(constraints.count - 1)
    j = constraints.index(i);
    range = constraints.range{i};

    output.violations(i) = max([ 0, ...
      range(1) - data(j), data(j) - range(2) ]);

    if output.violations(i) > 0
      penalty = penalty + this.penalize( ...
        output.violations(i), quantities.nominal(i));
    end
  end

  %
  % TODO: It should be positive for the energy consumption and
  % negative for the maximal temperature and lifetime.
  %
  output.fitness = data(targets.index);

  if penalty > 0
    output.fitness = this.finalize(output.fitness, penalty);
  end
end
