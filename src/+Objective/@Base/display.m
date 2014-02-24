function display(this)
  quantityNames = this.surrogate.quantityNames;
  constraints = this.constraints;

  fprintf('%s:\n', class(this));

  for i = find(this.targetIndex)
    name = quantityNames{i};
    [ nominal, units ] = convert(constraints.nominal(i), name);
    fprintf('  Target: %s (initial %.2f %s)\n', name, nominal, units);
  end

  fprintf('  Deterministic constraints on time:\n');
  fprintf('    Deadline:    %.2f s (initial %.2f s)\n', ...
    constraints.deadline, constraints.duration);

  for i = find(~this.targetIndex)
    name = quantityNames{i};
    [ nominal, units ] = convert(constraints.nominal(i), name);
    quantile = convert(constraints.quantile(i), name);
    range = convert(constraints.range{i}, name);

    fprintf('  Probabilistic constraints on %s:\n', name);
    fprintf('    Nominal:     %.2f %s\n', nominal, units);
    fprintf('    Quantile:    %.2f %s\n', quantile, units);
    fprintf('    Percentile:  %.2f %%\n', constraints.percentile(i));
    fprintf('    Lower bound: %.2f %s\n', range(1), units);
    fprintf('    Upper bound: %.2f %s\n', range(2), units);
    fprintf('    Probability: %.2f\n', constraints.probability(i));
  end
end

function [ value, units ] = convert(value, name)
  switch lower(name)
  case 'temperature'
    value = Utils.toCelsius(value);
    units = 'C';
  case 'energy'
    units = 'J';
  case 'lifetime'
    value = Utils.toYears(value);
    units = 'years';
  otherwise
    assert(false);
  end
end
