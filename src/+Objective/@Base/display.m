function display(this)
  fprintf('%s:\n', class(this));
  fprintf('  Targets: %s\n', String.join(', ', this.targetNames));

  names = this.surrogate.quantityNames;
  count = this.surrogate.quantityCount;

  constraints = this.constraints;

  for i = 1:count
    nominal = constraints.nominal(i);
    lowerBound = constraints.lowerBound(i);
    upperBound = constraints.upperBound(i);

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

    fprintf('  Constraints for %s:\n', lower(names{i}));
    fprintf('    Nominal:     %.2f %s\n', nominal, units);
    fprintf('    Lower bound: %.2f %s\n', lowerBound, units);
    fprintf('    Upper bound: %.2f %s\n', upperBound, units);
    fprintf('    Probability: %.2f (initial %.5f)\n', ...
      constraints.probability(i), constraints.initialProbability(i));
  end
end
