function sweep(varargin)
  setup;

  names = { 'MonteCarlo', 'PolynomialChaos' };

  lowerBound = 0;
  upperBound = 1;
  errorMetric = 'NRMSE';

  options = Configure.problem(varargin{:}, 'surrogate', names{1});
  [ oneSurrogate, oneOutput ] = construct(options);

  if options.get('compare', false)
    options = Configure.problem(varargin{:}, 'surrogate', names{2});
    [ twoSurrogate, twoOutput ] = construct(options);

    if isa(twoSurrogate.surrogate.distribution, 'ProbabilityDistribution.Gaussian')
      lowerBound = max(sqrt(eps), lowerBound);
      upperBound = min(1 - sqrt(eps), upperBound);
    end
  end

  parameters = options.processOptions.parameters;
  parameterCount = length(parameters);
  dimensions = oneSurrogate.process.dimensions;

  sweeps = cell(1, parameterCount);
  nominals = cell(1, parameterCount);
  for i = 1:parameterCount
    sweeps{i} = linspace( ...
      max(lowerBound, sqrt(eps)), ...
      min(upperBound, 1 - sqrt(eps)), 200);
    nominals{i} = 0.5 * ones(length(sweeps{i}), dimensions(i));
  end

  parameterLine = sweeps{1}; % for simplicity

  Iparameter = 1;
  Ivariable = num2cell(ones(1, parameterCount));

  while true
    Iparameter = askInteger('parameters', parameterCount, Iparameter);
    if isempty(Iparameter)
      Iparameter = 1;
      continue;
    end

    for i = Iparameter
      Ivariable{i} = askInteger([ 'variables for Parameter ', ...
        num2str(i) ], dimensions(i), Ivariable{i});
      if isempty(Ivariable{i})
        Ivariable{i} = 1;
        continue;
      end
    end

    parameters = nominals;
    for i = Iparameter
      for j = Ivariable{i}
        parameters{i}(:, j) = sweeps{i};
      end
    end

    fprintf('%s: evaluation...\n', class(oneSurrogate));
    time = tic;
    mcData = oneSurrogate.evaluate(oneOutput, cell2mat(parameters), true); % uniform
    fprintf('%s: done in %.2f seconds.\n', class(oneSurrogate), toc(time));

    if ~exist('twoSurrogate', 'var')
      Plot.figure(1400, 400);
      Plot.name('System variation');

      for i = 1:oneSurrogate.quantityCount
        subplot(1, oneSurrogate.quantityCount, i);
        Plot.line(parameterLine, mcData(:, i), 'number', i);
        Plot.title('%s %s/%s', ...
          oneSurrogate.quantityNames{i}, String(Iparameter), ...
          String(Ivariable(Iparameter)));
      end
    else
      fprintf('%s: evaluation...\n', class(twoSurrogate));
      time = tic;
      surrogateData = twoSurrogate.evaluate( ...
        twoOutput, cell2mat(parameters), true); % uniform
      fprintf('%s: done in %.2f seconds.\n', class(twoSurrogate), toc(time));

      Plot.figure(1400, 400);
      Plot.name('Absolute error');

      for i = 1:oneSurrogate.quantityCount
        subplot(1, oneSurrogate.quantityCount, i);
        Plot.line(parameterLine, abs(mcData(:, i) - ...
          surrogateData(:, i)) ./ mcData(:, i), 'number', i);
        Plot.title('%s %s %.4f', oneSurrogate.quantityNames{i}, errorMetric, ...
          Error.compute(errorMetric, mcData(:, i), surrogateData(:, i)));
      end

      set(gca, 'YScale', 'log');

      Plot.figure(1400, 400);
      Plot.name('System variation');

      for i = 1:oneSurrogate.quantityCount
        subplot(1, oneSurrogate.quantityCount, i);
        Plot.line(parameterLine, mcData(:, i), 'number', i);
        Plot.line(parameterLine, surrogateData(:, i), ...
          'auxiliary', true, 'style', { 'Color', 'k' });
        Plot.title('%s %s/%s', ...
          oneSurrogate.quantityNames{i}, String(Iparameter), ...
          String(Ivariable(Iparameter)));
      end
    end

    if ~Console.question('Sweep more? '), break; end
  end
end

function index = askInteger(name, maximum, index)
  if maximum == 1
    index = 1;
    return;
  end

  index = Console.request( ...
    'prompt', sprintf('Which %s (up to %d)? [%s] ', name, ...
    maximum, String(index)), 'default', index);

  if any(index < 1) || any(index > maximum), index = []; end
end
