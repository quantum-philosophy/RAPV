function fitness = compute(this, schedule)
  duration = max(schedule(4, :) + schedule(5, :));

  if duration > this.constraints.deadline
    fitness = Inf(1, this.dimensionCount);
    return;
  end

  output = this.surrogate.compute(this.power.compute(schedule));
  data = this.surrogate.sample(output, this.sampleCount);

  for i = find(~this.targetIndex)
    probability = this.computeProbability( ...
      data(:, i), this.constraints.range{i});
    if probability < this.constraints.probability(i)
      fitness = Inf(1, this.dimensionCount);
      return;
    end
  end

  fitness = this.computeFitness(data);
end
