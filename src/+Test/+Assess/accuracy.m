function accuracy
  setup;
  rng(1);

  comparisonOptions = Options('quantity', 'pdf', 'range', 'unbounded', ...
    'method', 'smooth', 'distanceMetric', 'KLD', 'errorMetric', 'RMSE');

  orderSet = [ 1 2 3 4 5 ];
  sampleCountSet = [ 1e2 1e3 1e4 ];

  orderCount = length(orderSet);
  sampleCount = length(sampleCountSet);

  %
  % Monte Carlo
  %
  options = Test.configure('surrogate', 'MonteCarlo', ...
    'surrogateOptions', Options('sampleCount', max(sampleCountSet)));

  mc = SystemVariation(options);
  output = mc.compute(options.dynamicPower);

  mc = struct;
  mc.expectation = cell(sampleCount, 1);
  mc.variance = cell(sampleCount, 1);
  mc.data = cell(sampleCount, 1);

  for i = 1:sampleCount
    mc.data{i} = output.data(1:sampleCountSet(i), :);
    mc.expectation{i} = mean(mc.data{i}, 1);
    mc.variance{i} = var(mc.data{i}, [], 1);
  end

  error = struct;
  error.expectation = cell(orderCount, sampleCount);
  error.variance = cell(orderCount, sampleCount);
  error.data = cell(orderCount, sampleCount);

  %
  % Polynomial chaos
  %
  options = Test.configure('surrogate', 'PolynomialChaos');

  for i = 1:orderCount
    options.surrogateOptions.order = orderSet(i);

    surrogate = SystemVariation(options);

    fprintf('%s: evaluating order %d...\n', class(surrogate), orderSet(i));
    time = tic;

    output = surrogate.compute(options.dynamicPower);
    stats = surrogate.analyze(output);
    data = surrogate.sample(output, max(sampleCountSet));

    fprintf('%s: done in %.2f seconds.\n', class(surrogate), toc(time));

    for j = 1:sampleCount
      fprintf('%s: comparing with %d samples...\n', ...
        class(surrogate), sampleCountSet(j));
      time = tic;

      error.expectation{i, j} = abs( ...
        (mc.expectation{j} - stats.expectation) ./ mc.expectation{j});
      error.variance{i, j} = abs( ...
        (mc.variance{j} - stats.variance) ./ mc.variance{j});
      error.data{i, j} = zeros(1, surrogate.quantityCount);
      for k = 1:surrogate.quantityCount
        error.data{i, j}(k) = Utils.compareDistributions( ...
          mc.data{j}(:, k), data(:, k), comparisonOptions);
      end

      fprintf('%s: done in %.2f seconds.\n', class(surrogate), toc(time));
    end
  end

  metricNames = { 'E', 'Var', 'P' };
  metricCount = length(metricNames);

  quantityNames = SystemVariation.Base.quantityNames;
  quantityCount = length(quantityNames);

  for k = 1:quantityCount
    fprintf('Errors for %s in percentage:\n', quantityNames{k});

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
      fprintf('%15.4f', 100 * error.expectation{i, k});
      fprintf(' | ');
      fprintf('%15.4f', 100 * error.variance{i, k});
      fprintf(' | ');
      fprintf('%15.4f', error.data{i, k});
      fprintf(' | ');
      fprintf('\n');
    end

    fprintf('\n');
  end
end
