function accuracy
  setup;
  rng(0);

  comparisonOptions = Options('quantity', 'pdf', 'range', 'unbounded', ...
    'method', 'smooth', 'distanceMetric', 'KLD', 'errorMetric', 'NRMSE');

  caseCount = 10;

  orderSet = 1:5;
  levelSet = orderSet;
  setCount = length(orderSet);

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
  surrogates = cell(1, setCount);

  options = Configure.problem('surrogate', 'PolynomialChaos');

  fprintf('%20s%20s%20s%20s\n', 'Polynomial order', ...
    'Polynomial terms', 'Quadrature level', 'Quadrature nodes');
  for i = 1:setCount
    options.surrogateOptions.order = orderSet(i);
    options.surrogateOptions.quadratureOptions.level = levelSet(i);
    surrogates{i} = SystemVariation(options);
    fprintf('%20d%20d%20d%20d\n', options.surrogateOptions.order, ...
      surrogates{i}.surrogate.termCount, ...
      options.surrogateOptions.quadratureOptions.level, ...
      surrogates{i}.surrogate.nodeCount);
  end

  %
  % Error metrics
  %
  metricNames = { 'E', 'Var', 'f' };
  metricCount = length(metricNames);

  error = struct;
  error.expectation = cell(setCount, sampleCount);
  error.variance = cell(setCount, sampleCount);
  error.data = cell(setCount, sampleCount);
  for i = 1:setCount
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

    [ output, fromCache ] = cache(mc, 'compute', dynamicPower, 'raw', true);
    if fromCache
      %
      % NOTE: Offset the RNG to get the same results each time
      % the code is executed.
      %
      mc.surrogate.distribution.sample( ...
        mc.surrogate.sampleCount, mc.surrogate.inputCount);
    end

    mcStats = struct;
    mcStats.expectation = cell(sampleCount, 1);
    mcStats.variance = cell(sampleCount, 1);
    mcStats.data = cell(sampleCount, 1);

    for i = 1:sampleCount
      mcStats.data{i} = output.data(1:sampleCountSet(i), :);
      mcStats.expectation{i} = mean(mcStats.data{i}, 1);
      mcStats.variance{i} = var(mcStats.data{i}, [], 1);
    end

    for i = setCount:-1:1
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

  for i = 1:setCount
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
    fprintf('%5s | ', '');
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
    for i = 1:setCount
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

function [ output, fromCache ] = cache(this, method, varargin)
  fromCache = false;

  filename = sprintf('%s_%s.mat', class(this), ...
    DataHash({ this.toString, method, varargin(:) }));

  if File.exist(filename)
    fprintf('%s: loading data from "%s"...\n', class(this), filename);
    load(filename);
    fromCache = true;
  else
    fprintf('%s: collecting data...\n', class(this));

    time = tic;
    output = this.(method)(varargin{:});
    time = toc(time);

    save(filename, 'output', 'time', '-v7.3');
  end

  fprintf('%s: done in %.2f seconds.\n', class(this), time);
end
