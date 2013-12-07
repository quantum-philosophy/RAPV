function display(this)
  fprintf('%s:\n', class(this));
  fprintf('  Targets: %s\n', String.join(', ', this.targetNames));

  names = this.surrogate.quantityNames;
  count = this.surrogate.quantityCount;

  constraints = this.constraints;

  fprintf('  Deterministic constraints on time:\n');
  fprintf('    Deadline:    %.2f s (initial %.2f s)\n', ...
    constraints.deadline, constraints.initialDeadline);

  for i = 1:count
    nominal = constraints.nominal(i);
    lowerBound = constraints.range{i}(1);
    upperBound = constraints.range{i}(2);

    switch lower(names{i})
    case 'temperature'
      nominal = Utils.toCelsius(nominal);
      lowerBound = Utils.toCelsius(lowerBound);
      upperBound = Utils.toCelsius(upperBound);
      units = 'C';
    case 'energy'
      units = 'J';
    case 'lifetime'
      nominal = Utils.toYears(nominal);
      lowerBound = Utils.toYears(lowerBound);
      upperBound = Utils.toYears(upperBound);
      units = 'years';
    otherwise
      assert(false);
    end

    fprintf('  Probabilistic constraints on %s:\n', lower(names{i}));
    fprintf('    Nominal:     %.2f %s\n', nominal, units);
    fprintf('    Lower bound: %.2f %s\n', lowerBound, units);
    fprintf('    Upper bound: %.2f %s\n', upperBound, units);
    fprintf('    Probability: %.2f (initial %.5f)\n', ...
      constraints.probability(i), constraints.initialProbability(i));
  end
end
