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
  % NOTE: Excluding the last one as it is treated separatly.
  %
  for i = quantities.constraintIndex(1:(end - 1))
    range = quantities.range{i};

    delta = [ range(1) - data(i), data(i) - range(2) ];
    output.violation(i) = max([ 0, delta ]) / quantities.nominal(i);
  end

  output.expectation(1:(end - 1)) = data;
end
