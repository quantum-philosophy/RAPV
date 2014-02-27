function accuracy
  setup;
  rng(1);

  comparisonOptions = Options('quantity', 'pdf', 'range', 'unbounded', ...
    'method', 'smooth', 'distanceMetric', 'KLD', 'errorMetric', 'NRMSE');

  caseCount = 10;

  orderSet = [ 1 2 3 4 5 ];
  orderCount = length(orderSet);

  sampleCountSet = [ 1e4 ];
  sampleCount = length(sampleCountSet);

  quantityNames = SystemVariation.Base.quantityNames;
  quantityCount = length(quantityNames);

  %
  % Monte Carlo
  %
  options = Configure.problem('surrogate', 'MonteCarlo', ...
    'surrogateOptions', Options('sampleCount', max(sampleCountSet)));

  mc = SystemVariation(options);

  %
  % Polynomial chaos
  %
  surrogates = cell(1, orderCount);

  options = Configure.problem('surrogate', 'PolynomialChaos');
  for i = 1:orderCount
    options.surrogateOptions.order = orderSet(i);
    surrogates{i} = SystemVariation(options);
  end

  %
  % Error metrics
  %
  metricNames = { 'E', 'Var', 'f' };
  metricCount = length(metricNames);

  error = struct;
  error.expectation = cell(orderCount, sampleCount);
  error.variance = cell(orderCount, sampleCount);
  error.data = cell(orderCount, sampleCount);
  for i = 1:orderCount
    for j = 1:sampleCount
      error.expectation{i, j} = zeros(1, quantityCount);
      error.variance{i, j} = zeros(1, quantityCount);
      error.data{i, j} = zeros(1, quantityCount);
    end
  end

  for l = 1:caseCount
    mapping = randi(options.processorCount, 1, options.taskCount);
    priority = rand(1, options.taskCount);

    schedule = options.scheduler.compute(mapping, priority);
    dynamicPower = options.power.compute(schedule);

    output = mc.compute(dynamicPower, 'raw', true);

    mcStats = struct;
    mcStats.expectation = cell(sampleCount, 1);
    mcStats.variance = cell(sampleCount, 1);
    mcStats.data = cell(sampleCount, 1);

    for i = 1:sampleCount
      mcStats.data{i} = output.data(1:sampleCountSet(i), :);
      mcStats.expectation{i} = mean(mcStats.data{i}, 1);
      mcStats.variance{i} = var(mcStats.data{i}, [], 1);
    end

    for i = 1:orderCount
      surrogate = surrogates{i};

      fprintf('%s: evaluating order %d...\n', class(surrogate), orderSet(i));
      time = tic;

      output = surrogate.compute(dynamicPower, 'raw', true);
      stats = surrogate.analyze(output);
      stats.data = surrogate.sample(output, max(sampleCountSet));

      fprintf('%s: done in %.2f seconds.\n', class(surrogate), toc(time));

      for j = 1:sampleCount
        fprintf('%s: comparing with %d samples...\n', ...
          class(surrogate), sampleCountSet(j));
        time = tic;

        error.expectation{i, j} = error.expectation{i, j} + ...
          abs((mcStats.expectation{j} - stats.expectation) ./ mcStats.expectation{j});
        error.variance{i, j} = error.variance{i, j} + ...
          abs((mcStats.variance{j} - stats.variance) ./ mcStats.variance{j});
        for k = 1:surrogate.quantityCount
          error.data{i, j}(k) = error.data{i, j}(k) + ...
            Utils.compareDistributions(mcStats.data{j}(:, k), ...
              stats.data(:, k), comparisonOptions);
        end

        fprintf('%s: done in %.2f seconds.\n', class(surrogate), toc(time));
      end
    end
  end

  for i = 1:orderCount
    for j = 1:sampleCount
      error.expectation{i, j} = error.expectation{i, j} / caseCount;
      error.variance{i, j} = error.variance{i, j} / caseCount;
      error.data{i, j} = error.data{i, j} / caseCount;
    end
  end

  for k = 1:quantityCount
    fprintf('%s:\n', quantityNames{k});

    %
    % Header
    %
    fprintf('%5s | ', 'Order');
    for i = 1:metricCount
      for j = 1:sampleCount
        fprintf('%15s', sprintf('%s, 10^%d', ...
          metricNames{i}, log10(sampleCountSet(j))));
      end
      fprintf(' | ');
    end
    fprintf('\n');

    %
    % Data
    %
    for i = 1:orderCount
      fprintf('%5d | ', orderSet(i));
      fprintf('%15.4f', 100 * cellfun(@(x) x(k), error.expectation(i, :)));
      fprintf(' | ');
      fprintf('%15.4f', 100 * cellfun(@(x) x(k), error.variance(i, :)));
      fprintf(' | ');
      fprintf('%15.4f', cellfun(@(x) x(k), error.data(i, :)));
      fprintf(' | ');
      fprintf('\n');
    end

    fprintf('\n');
  end
end
