function accuracy
  setup;
  rng(0);

  comparisonOptions = Options('quantity', 'pdf', 'range', 'unbounded', ...
    'method', 'smooth', 'distanceMetric', 'KLD', 'errorMetric', 'NRMSE');

  caseCount = 10;
  iterationCount = 10;

  orderSet = 1:5;
  levelSet = 1:5;
  xCount = length(orderSet);

  sampleSet = 1e4;
  yCount = length(sampleSet);

  quantityNames = SystemVariation.Base.quantityNames;
  quantityCount = length(quantityNames);

  %
  % Monte Carlo
  %
  options = Configure.problem('surrogate', 'MonteCarlo', ...
    'surrogateOptions', Options('sampleCount', max(sampleSet)));

  mc = SystemVariation(options);

  %
  % Polynomial chaos
  %
  surrogates = cell(1, xCount);

  options = Configure.problem('surrogate', 'PolynomialChaos');

  fprintf('%20s%20s%20s%20s\n', 'Polynomial order', ...
    'Polynomial terms', 'Quadrature level', 'Quadrature nodes');
  for i = 1:xCount
    options.surrogateOptions.order = orderSet(i);
    options.surrogateOptions.quadratureOptions.level = levelSet(i);
    surrogates{i} = SystemVariation(options);
    fprintf('%20d%20d%20d%20d\n', orderSet(i), ...
      surrogates{i}.surrogate.termCount, levelSet(i), ...
      surrogates{i}.surrogate.nodeCount);
  end

  %
  % Error metrics
  %
  metricNames = { 'E', 'Var', 'f' };
  metricCount = length(metricNames);

  error = struct;
  error.expectation = cell(xCount, yCount);
  error.variance = cell(xCount, yCount);
  error.data = cell(xCount, yCount);
  for i = 1:xCount
    for j = 1:yCount
      error.expectation{i, j} = zeros(1, quantityCount);
      error.variance{i, j} = zeros(1, quantityCount);
      error.data{i, j} = zeros(1, quantityCount);
    end
  end

  Plot.figure(1200, 600);
  for l = 1:caseCount
    mapping = randi(options.processorCount, 1, options.taskCount);
    priority = rand(1, options.taskCount);

    schedule = options.scheduler.compute(mapping, priority);
    dynamicPower = options.power.compute(schedule);

    mcStats = struct;
    mcStats.expectation = cell(yCount, 1);
    mcStats.variance = cell(yCount, 1);
    mcStats.data = cell(yCount, 1);

    stats = cache(mc, dynamicPower, iterationCount);

    for i = 1:yCount
      mcStats.data{i} = stats.data(1:sampleSet(i), :);
      mcStats.expectation{i} = stats.expectation;
      mcStats.variance{i} = stats.variance;
    end

    for i = xCount:-1:1
      surrogate = surrogates{i};

      fprintf('%s: evaluating order %d...\n', class(surrogate), orderSet(i));
      time = tic;

      output = surrogate.compute(dynamicPower, 'raw', true);
      count = size(output.coefficients, 1);
      for j = 1:1
        subplot(1, 1, j);
        line(1:count, log(abs(output.coefficients(1:count, j))), ...
          'Marker', Marker.pick(i), 'Color', Color.pick(i));
      end
      stats = surrogate.analyze(output);
      stats.data = surrogate.sample(output, max(sampleSet));

      fprintf('%s: done in %.2f seconds.\n', class(surrogate), toc(time));

      for j = 1:yCount
        fprintf('%s: comparing with %d samples...\n', ...
          class(surrogate), sampleSet(j));
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

  for i = 1:xCount
    for j = 1:yCount
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
    fprintf('%5s%10s%10s%10s%10s | ', '', 'PC order', ...
      'PC terms', 'QD level', 'QD nodes');
    for i = 1:metricCount
      for j = 1:yCount
        fprintf('%15s', sprintf('%s, 10^%d', ...
          metricNames{i}, log10(sampleSet(j))));
      end
      fprintf(' | ');
    end
    fprintf('\n');

    %
    % Data
    %
    for i = 1:xCount
      fprintf('%5d%10d%10d%10d%10d | ', i, orderSet(i), ...
        surrogates{i}.surrogate.termCount, levelSet(i), ...
        surrogates{i}.surrogate.nodeCount);
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

function stats = cache(this, dynamicPower, iterationCount)
  sampleCount = this.surrogate.sampleCount;

  filename = sprintf('%s_%s.mat', class(this), ...
    DataHash({ this.toString, dynamicPower, iterationCount }));

  if File.exist(filename)
    fprintf('%s: loading data from "%s"...\n', class(this), filename);
    load(filename);
    %
    % NOTE: Offset the RNG to get the same results each time
    % the code is executed.
    %
    for i = 1:iterationCount
      this.surrogate.distribution.sample( ...
        this.surrogate.sampleCount, this.surrogate.inputCount);
    end
  else
    fprintf('%s: collecting %d samples %d times...', class(this), ...
      sampleCount, iterationCount);

    Ex = 0;
    Sx = 0;

    time = tic;
    for i = 1:iterationCount
      output = this.compute(dynamicPower, 'raw', true);

      Na = (i - 1) * sampleCount;
      Nb = 1 * sampleCount;
      Nx = Na + Nb;

      Ea = Ex;
      Eb = mean(output.data, 1);

      delta = Ea - Eb;

      Ex = (Na * Ea + Nb * Eb) / Nx;

      Sa = Sx;
      Sb = var(output.data, [], 1) * (sampleCount - 1);

      Sx = Sa + Sb + delta.^2 * Na * Nb / Nx;

      fprintf(' %d', i);
    end
    fprintf('\n');
    time = toc(time) / iterationCount;

    stats = struct;
    stats.data = output.data;
    stats.expectation = Ex;
    stats.variance = Sx / (iterationCount * sampleCount - 1);

    save(filename, 'stats', 'time', '-v7.3');
  end

  fprintf('%s: done in %.2f seconds.\n', class(this), time);
end
