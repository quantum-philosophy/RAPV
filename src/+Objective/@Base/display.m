function display(this)
  quantities = this.quantities;

  fprintf('%s:\n', class(this));

  for i = 1:quantities.count
    name = quantities.names{i};

    [ nominal, units ] = convert(quantities.nominal(i), name);
    range = convert(quantities.range{i}, name);

    constraint = ismember(i, quantities.constraintIndex);
    deterministic = isnan(quantities.quantile(i));

    if ~constraint
      fprintf('  Nonconstraint: %s\n', name);
    elseif deterministic
      fprintf('  Deterministic constraint: %s\n', name);
    else
      fprintf('  Probabilistic constraint: %s\n', name);
    end

    fprintf('    Nominal:     %.2f %s\n', nominal, units);

    if ~constraint, continue; end

    fprintf('    Lower bound: %.2f %s\n', range(1), units);
    fprintf('    Upper bound: %.2f %s\n', range(2), units);

    if deterministic, continue; end

    quantile = convert(quantities.quantile(i), name);

    fprintf('    Quantile:    %.2f %s\n', quantile, units);
    fprintf('    Percentile:  %.2f %%\n', quantities.percentile(i));
    fprintf('    Probability: %.2f\n', quantities.probability(i));
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
