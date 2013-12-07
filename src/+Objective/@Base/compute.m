function fitness = compute(this, schedule)
  dimensionCount = this.dimensionCount;
  constraints = this.constraints;

  duration = max(schedule(4, :) + schedule(5, :));

  if duration > constraints.deadline
    fitness = Inf(1, dimensionCount);
    return;
  end

  output = this.surrogate.compute(this.power.compute(schedule));

  data = this.surrogate.sample(output, this.sampleCount);

  for i = 1:dimensionCount
    probability = diff(ksdensity(data(:, i), constraints.range{i}, ...
      'support', 'positive', 'function', 'cdf'));
    if probability < constraints.probability(i)
      fitness = Inf(1, dimensionCount);
      return;
    end
  end

  fitness = this.evaluate(data);
end
