function report(surrogate, output, quantities)
  display(surrogate, output);

  if surrogate.inputCount <= 3
    plot(surrogate, output);
  end

  fprintf('%25s%15s%15s%15s\n', 'Quantity', 'Nominal', ...
    'Expectation', 'Deviation');

  for i = 1:surrogate.quantityCount
    name = lower(surrogate.quantityNames{i});
    reportOne(name, quantities.(name));
  end
end

function reportOne(quantity, stats)
  expectation = stats.expectation;
  variance = stats.variance;
  data = stats.data;
  nominal = stats.nominal;

  switch quantity
  case 'temperature'
    name = 'Maximal temperature';
    nominal = Utils.toCelsius(nominal);
    expectation = Utils.toCelsius(expectation);
    deviation = sqrt(variance);
    data = Utils.toCelsius(data);
  case 'energy'
    name = 'Energy consumption';
    deviation = sqrt(variance);
  case 'lifetime'
    name = 'Mean time to failure';
    nominal = Utils.toYears(nominal);
    expectation = Utils.toYears(expectation);
    deviation = Utils.toYears(sqrt(variance));
    data = Utils.toYears(data);
  otherwise
    assert(false);
  end

  fprintf('%25s%15.4f%15.4f%15.4f\n', ...
    name, nominal, expectation, deviation);

  if isempty(data), return; end

  Plot.distribution(data, 'method', 'smooth', 'range', 'unbounded');

  Plot.vline(nominal, 'number', 2);
  Plot.vline(expectation, 'number', 3);
  Plot.vline(expectation + deviation, 'number', 3, 'auxiliary', true);
  Plot.vline(expectation - deviation, 'number', 3, 'auxiliary', true);

  Plot.title(name);
  Plot.legend('Density', 'Nominal', 'Expectation', '+/- Deviation');

  switch quantity
  case 'temperature'
    Plot.label('Maximal temperature, C', 'Probability density');
  case 'energy'
    Plot.label('Energy consumption, J', 'Probability density');
  case 'lifetime'
    Plot.label('Mean time to failure, years', 'Probability density');
    limit = xlim;
    xlim([ 0, limit(2) ]);
  otherwise
    assert(false);
  end
end
