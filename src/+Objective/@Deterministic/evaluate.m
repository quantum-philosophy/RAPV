function output = evaluate(this, schedule)
  quantities = this.quantities;
  targets = this.targets;
  constraints = this.constraints;

  output = struct;
  output.fitness = NaN(1, targets.count);
  output.violation = NaN(1, constraints.count);

  %
  % Stochastic (but here deterministic)
  %
  [ T, temperatureOutput ] = this.surrogate.temperature.computeWithLeakage( ...
    this.power.compute(schedule));

  data = [ ...
  	max(T(:)), ...
  	this.surrogate.temperature.samplingInterval * ...
      sum(temperatureOutput.P(:)), ...
    this.surrogate.fatigue.compute(T) ...
  ];

  %
  % NOTE: Excluding the last one as it will be treated separatly.
  %
  for i = 1:(constraints.count - 1)
    j = constraints.index(i);
    range = constraints.range{i};

    delta = [ range(1) - data(j), data(j) - range(2) ];
    output.violation(i) = max([ 0, delta ]) / quantities.nominal(i);
  end

  %
  % Deterministic
  %
  deadline = max(constraints.range{end});
  duration = max(schedule(4, :) + schedule(5, :));

  delta = duration - deadline;
  output.violation(end) = max(0, delta) / deadline;

  %
  % TODO: It should be positive for the energy consumption and
  % negative for the maximal temperature and lifetime.
  %
  output.fitness = data(targets.index);
end
