function accuracy
  setup;
  rng(1);

  processorCount = 4;
  stepCount = 1e2;

  comparisonOptions = Options('quantity', 'pdf', 'range', 'unbounded', ...
    'method', 'smooth', 'distanceMetric', 'KLD', 'errorMetric', 'RMSE');

  orderSet       = [ 1 2 3 4 5 6 ];
  sampleCountSet = [ 1e2 1e3 1e4 1e5 ];

  pick = [ 4 1e5 50 ];

  orderCount = length(orderSet);
  sampleCount = length(sampleCountSet);

  options = Test.configure('processModel', 'Normal', ...
    'processorCount', processorCount, 'stepCount', stepCount);

  %
  % Monte Carlo
  %
  mc = Temperature.MonteCarlo.DynamicSteadyState(options);

  [ ~, output ] = mc.compute(options.dynamicPower, ...
    options.steadyStateOptions, 'sampleCount', max(sampleCountSet));

  mcTexp = cell(sampleCount, 1);
  mcTvar = cell(sampleCount, 1);
  mcTdata = cell(sampleCount, 1);

  for i = 1:sampleCount
    mcTdata{i} = output.Tdata(1:sampleCountSet(i), :, :);
    mcTexp{i} = squeeze(mean(mcTdata{i}, 1));
    mcTvar{i} = squeeze(var(mcTdata{i}, [], 1));
  end

  errorExp = zeros(orderCount, sampleCount);
  errorVar = zeros(orderCount, sampleCount);
  errorPDF = zeros(orderCount, sampleCount);

  printHeader(comparisonOptions, sampleCountSet);

  %
  % Polynomial chaos
  %
  for i = 1:orderCount
    options.surrogateOptions.order = orderSet(i);

    fprintf('%5d | ', orderSet(i));

    surrogate = Temperature.Chaos.DynamicSteadyState(options);

    [ Texp, output ] = surrogate.compute(options.dynamicPower, ...
      options.steadyStateOptions);
    Tdata = surrogate.sample(output, max(sampleCountSet));

    for j = 1:sampleCount
      errorExp(i, j) = Error.compute( ...
        comparisonOptions.errorMetric, mcTexp{j}, Texp);
      errorVar(i, j) = Error.compute( ...
        comparisonOptions.errorMetric, mcTvar{j}, output.Tvar);

      if orderSet(i) == pick(1) && sampleCountSet(j) == pick(2)
        errorPDF(i, j) = Data.compare(Utils.toCelsius(mcTdata{j}), ...
          Utils.toCelsius(Tdata), comparisonOptions, 'draw', true);

        expectationError = abs(mcTexp{j} - Texp);
        varianceError = abs(mcTvar{j} - output.Tvar);

        figure;
        subplot(1, 2, 1);
        Plot.title('Expectation (%s %.4f)', ...
          comparisonOptions.errorMetric, errorExp(i, j));
        Plot.label('', 'Absolute error');
        subplot(1, 2, 2);
        Plot.title('Variance (%s %.4f)', ...
          comparisonOptions.errorMetric, errorVar(i, j));
        Plot.label('', 'Absolute error');
        Plot.name('Errors of analytical expectation and variance');

        time = 0:(stepCount - 1);
        for k = 1:processorCount
          color = Color.pick(k);
          subplot(1, 2, 1);
          line(time, expectationError(k, :), 'Color', color);
          subplot(1, 2, 2);
          line(time, varianceError(k, :), 'Color', color);
        end

        Data.compare(Utils.toCelsius(mcTdata{j}(:, :, pick(3))), ...
          Utils.toCelsius(Tdata(:, :, pick(3))), ...
          comparisonOptions, 'draw', true, 'layout', 'one', ...
          'names', { 'MC', 'PC' });
      else
        errorPDF(i, j) = Data.compare(mcTdata{j}, Tdata, ...
          comparisonOptions);
      end

      fprintf('%15.4f', errorPDF(i, j));
    end

    fprintf(' | ');

    for j = 1:sampleCount
      fprintf('%15.4f', errorExp(i, j));
    end

    fprintf(' | ');

    for j = 1:sampleCount
      fprintf('%15.4f', errorVar(i, j));
    end

    fprintf('\n');
  end
end

function printHeader(comparisonOptions, sampleCountSet)
  sampleCount = length(sampleCountSet);

  fprintf('\n');

  names = { ...
    [ comparisonOptions.distanceMetric, '(PDF)' ], ...
    [ comparisonOptions.errorMetric, '(Exp)' ], ...
    [ comparisonOptions.errorMetric, '(Var)' ] };

  fprintf('%5s | ', '');
  for i = 1:length(names)
    if i > 1, fprintf(' | '); end

    s = names{i};
    start = true;
    while length(s) < 15 * sampleCount
      if start
        s = [ ' ', s ];
        start = false;
      else
        s = [ s, ' ' ];
        start = true;
      end
    end

    fprintf(s);
  end
  fprintf('\n');

  fprintf('%5s | ', 'Order');
  for i = 1:length(names)
    if i > 1, fprintf(' | '); end

    for j = 1:sampleCount
      fprintf('%15s', sprintf('MC %.1e', sampleCountSet(j)));
    end
  end
  fprintf('\n');
end
