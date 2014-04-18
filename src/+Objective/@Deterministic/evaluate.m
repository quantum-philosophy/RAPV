function output = evaluate(this, schedule)
  quantities = this.quantities;

  output = struct;
  output.violation = NaN(1, quantities.count);

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
  for i = quantities.constraintIndex(1:(end - 1))
    range = quantities.range{i};

    delta = [ range(1) - data(i), data(i) - range(2) ];
    output.violation(i) = max([ 0, delta ]) / quantities.nominal(i);
  end

  %
  % Deterministic
  %
  deadline = max(quantities.range{end});
  duration = max(schedule(4, :) + schedule(5, :));

  delta = duration - deadline;
  output.violation(end) = max(0, delta) / deadline;

  output.expectation = [ data, duration ];
end
