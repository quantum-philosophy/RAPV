function accuracy
  setup;
  rng(1);

  stepCount = 1e2;
  chaosSampleCount = 1e5;

  comparisonOptions = Options('quantity', 'pdf', 'range', 'unbounded', ...
    'method', 'smooth', 'errorMetric', 'NRMSE');

  display(comparisonOptions, 'Comparison options');

  orderSet       = [ 1 2 3 4 5 6 7 ];
  sampleCountSet = [ 1e2 1e3 1e4 1e5 ];

  pick = [ 4 1e4 50 ];

  orderCount = length(orderSet);
  sampleCount = length(sampleCountSet);

  options = Test.configure('stepCount', stepCount);
  display(options);

  %
  % Monte Carlo simulation
  %
  mc = Temperature.MonteCarlo.DynamicSteadyState(options);

  [ ~, output ] = mc.compute(options.dynamicPower, ...
    options.steadyStateOptions, 'sampleCount', max(sampleCountSet), ...
    'verbose', true);

  mcTDATA = output.Tdata(randperm(max(sampleCountSet)), :, :);

  mcTexp = cell(sampleCount, 1);
  mcTvar = cell(sampleCount, 1);
  mcTdata = cell(sampleCount, 1);

  for i = 1:sampleCount
    mcTdata{i} = mcTDATA(1:sampleCountSet(i), :, :);
    mcTexp{i} = mean(mcTdata{i}, 1);
    mcTvar{i} = var(mcTdata{i}, [], 1);
  end

  errorExp = zeros(orderCount, sampleCount);
  errorVar = zeros(orderCount, sampleCount);
  errorPDF = zeros(orderCount, sampleCount);

  printHeader(sampleCountSet);

  %
  % Polynomial chaos expansion
  %
  for i = 1:orderCount
    options.chaosOptions.order = orderSet(i);
    options.chaosOptions.quadratureOptions.polynomialOrder = orderSet(i);

    fprintf('%5d | ', orderSet(i));

    chaos = Temperature.Chaos.DynamicSteadyState(options);

    [ Texp, output ] = chaos.compute(options.dynamicPower, ...
      options.steadyStateOptions);
    Tdata = chaos.sample(output.coefficients, chaosSampleCount);

    for j = 1:sampleCount
      errorExp(i, j) = Error.computeNRMSE(mcTexp{j}, Texp);
      errorVar(i, j) = Error.computeNRMSE(mcTvar{j}, output.Tvar);

      if orderSet(i) == pick(1) && sampleCountSet(j) == pick(2)
        errorPDF(i, j) = Data.compare(Utils.toCelsius(mcTdata{j}), ...
          Utils.toCelsius(Tdata), comparisonOptions, 'draw', true);
        Data.compare(Utils.toCelsius(mcTdata{j}(:, :, pick(3))), ...
          Utils.toCelsius(Tdata(:, :, pick(3))), ...
          comparisonOptions, 'draw', true, 'layout', 'one');
      else
        errorPDF(i, j) = Data.compare(mcTdata{j}, Tdata, ...
          comparisonOptions);
      end

      fprintf('%15.2f', errorPDF(i, j) * 100);
    end

    fprintf(' | ');

    for j = 1:sampleCount
      fprintf('%15.2f', errorExp(i, j) * 100);
    end

    fprintf(' | ');

    for j = 1:sampleCount
      fprintf('%15.2f', errorVar(i, j) * 100);
    end

    fprintf('\n');
  end
end

function printHeader(sampleCountSet)
  sampleCount = length(sampleCountSet);

  fprintf('\n');

  names = { 'NRMSE(PDF) * 100', 'NRMSE(Exp) * 100', 'NRMSE(Var) * 100' };

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
