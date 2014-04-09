function display(this)
  quantities = this.quantities;
  targets = this.targets;
  constraints = this.constraints;

  fprintf('%s:\n', class(this));

  for i = targets.index
    name = quantities.names{i};
    [ nominal, units ] = convert(constraints.nominal(i), name);
    fprintf('  Target: %s (initial %.2f %s)\n', name, nominal, units);
  end

  for i = constraints.index
    name = quantities.names{i};

    [ nominal, units ] = convert(constraints.nominal(i), name);
    range = convert(constraints.range{i}, name);

    deterministic = isnan(constraints.quantile(i));

    if deterministic
      fprintf('  Deterministic constraint on %s:\n', name);
    else
      fprintf('  Probabilistic constraint on %s:\n', name);
    end

    fprintf('    Nominal:     %.2f %s\n', nominal, units);
    fprintf('    Lower bound: %.2f %s\n', range(1), units);
    fprintf('    Upper bound: %.2f %s\n', range(2), units);

    if deterministic, continue; end

    quantile = convert(constraints.quantile(i), name);

    fprintf('    Quantile:    %.2f %s\n', quantile, units);
    fprintf('    Percentile:  %.2f %%\n', constraints.percentile(i));
    fprintf('    Probability: %.2f\n', constraints.probability(i));
  end
end

function [ value, units ] = convert(value, name)
  switch lower(name)
  case 'time'
    units = 's';
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
