function accuracy
  setup;
  rng(0);

  comparisonOptions = Options('quantity', 'pdf', 'range', 'unbounded', ...
    'method', 'smooth', 'distanceMetric', 'KLD', 'errorMetric', 'NRMSE');

  processorCount = 4;
  taskCount = 20 * processorCount;

  caseIndex = 1:10;
  caseCount = length(caseIndex);
  iterationCount = 10;

  polynomialOrder = 1:5;
  quadratureLevel = 1:5;
  xCount = length(polynomialOrder);

  sampleCount = 1e4;
  yCount = length(sampleCount);

  quantityNames = SystemVariation.Base.quantityNames;
  quantityCount = length(quantityNames);

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

  %
  % Additional stats
  %
  polynomialTermCount = NaN(1, xCount);
  quadratureNodeCount = NaN(1, xCount);

  Plot.figure(1200, 600);

  for l = caseIndex
    %
    % Monte Carlo
    %
    options = Configure.problem( ...
      'processorCount', processorCount, ...
      'taskCount', taskCount, ...
      'caseNumber', l, ...
      'surrogate', 'MonteCarlo', ...
      'surrogateOptions', Options( ...
        'sampleCount', max(sampleCount)));

    mc = SystemVariation(options);

    mcStats = struct;
    mcStats.expectation = cell(yCount, 1);
    mcStats.variance = cell(yCount, 1);
    mcStats.data = cell(yCount, 1);

    stats = cache(mc, options.dynamicPower, iterationCount);

    for i = 1:yCount
      mcStats.data{i} = stats.data(1:sampleCount(i), :);
      mcStats.expectation{i} = stats.expectation;
      mcStats.variance{i} = stats.variance;
    end

    %
    % Polynomial chaos
    %
    options = Configure.problem( ...
      'processorCount', processorCount, ...
      'taskCount', taskCount, ...
      'caseNumber', l, ...
      'surrogate', 'PolynomialChaos');

    for i = 1:xCount
      options.surrogateOptions.order = polynomialOrder(i);
      options.surrogateOptions.quadratureOptions.level = quadratureLevel(i);
      surrogate = SystemVariation(options);

      if l == caseIndex(1)
        polynomialTermCount(i) = surrogate.surrogate.termCount;
        quadratureNodeCount(i) = surrogate.surrogate.nodeCount;
      else
        assert(polynomialTermCount(i) == surrogate.surrogate.termCount);
        assert(quadratureNodeCount(i) == surrogate.surrogate.nodeCount);
      end

      fprintf('%s: evaluating order %d...\n', class(surrogate), polynomialOrder(i));
      time = tic;

      output = surrogate.compute(options.dynamicPower, 'raw', true);
      count = size(output.coefficients, 1);
      for j = 1:1
        subplot(1, 1, j);
        line(1:count, log(abs(output.coefficients(1:count, j))), ...
          'Marker', Marker.pick(i), 'Color', Color.pick(i));
      end
      stats = surrogate.analyze(output);
      stats.data = surrogate.sample(output, max(sampleCount));

      fprintf('%s: done in %.2f seconds.\n', class(surrogate), toc(time));

      for j = 1:yCount
        fprintf('%s: comparing with %d samples...\n', ...
          class(surrogate), sampleCount(j));
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
          metricNames{i}, log10(sampleCount(j))));
      end
      fprintf(' | ');
    end
    fprintf('\n');

    %
    % Data
    %
    for i = 1:xCount
      fprintf('%5d%10d%10d%10d%10d | ', i, ...
        polynomialOrder(i), polynomialTermCount(i), ...
        quadratureLevel(i), quadratureNodeCount(i));
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
