function display(this)
  quantityNames = this.surrogate.quantityNames;

  fprintf('%s:\n', class(this));
  fprintf('  Targets: %s\n', String.join(', ', ...
    quantityNames{this.targetIndex}));

  constraints = this.constraints;

  fprintf('  Deterministic constraints on time:\n');
  fprintf('    Deadline:    %.2f s (initial %.2f s)\n', ...
    constraints.deadline, constraints.duration);

  for i = find(~this.targetIndex)
    nominal = constraints.nominal(i);
    quantile = constraints.quantile(i);
    range = constraints.range{i};

    switch lower(quantityNames{i})
    case 'temperature'
      nominal = Utils.toCelsius(nominal);
      quantile = Utils.toCelsius(quantile);
      range = Utils.toCelsius(range);
      units = 'C';
    case 'energy'
      units = 'J';
    case 'lifetime'
      nominal = Utils.toYears(nominal);
      quantile = Utils.toYears(quantile);
      range = Utils.toYears(range);
      units = 'years';
    otherwise
      assert(false);
    end

    fprintf('  Probabilistic constraints on %s:\n', lower(quantityNames{i}));
    fprintf('    Nominal:     %.2f %s\n', nominal, units);
    fprintf('    Quantile:    %.2f %s\n', quantile, units);
    fprintf('    Percentile:  %.2f %%\n', constraints.percentile(i));
    fprintf('    Lower bound: %.2f %s\n', range(1), units);
    fprintf('    Upper bound: %.2f %s\n', range(2), units);
    fprintf('    Probability: %.2f\n', constraints.probability(i));
  end
end
