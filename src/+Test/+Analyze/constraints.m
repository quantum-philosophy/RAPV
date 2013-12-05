function constraints(varargin)
  setup;

  options = Configure.problem( ...
    'mapping', @(processorCount, taskCount) ...
      randi(processorCount, 1, taskCount), ...
    'priority', @(processorCount, taskCount) ...
      rand(1, taskCount), varargin{:});

  surrogate = SystemVariation(options);

  names = surrogate.quantityNames;
  count = surrogate.quantityCount;

  quantities = Analyze.constraints(surrogate, options);

  for i = 1:count
    nominal = quantities.nominal(i);
    lowerBound = quantities.range{i}(1);
    upperBound = quantities.range{i}(2);

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

    fprintf('%s:\n', names{i});
    fprintf('  Nominal value: %.2f %s\n', nominal, units);
    fprintf('  Constraint:\n');
    fprintf('    Lower bound: %.2f %s\n', lowerBound, units);
    fprintf('    Upper bound: %.2f %s\n', upperBound, units);
    fprintf('    Probability: %.4f (initial %.4f)\n', ...
      quantities.probability(i), quantities.initialProbability(i));
  end
end
