function stats = postprocess(surrogate, output, options)
  sampleCount = 1e5;

  name = class(surrogate);

  time = tic;
  fprintf('%s: analysis...\n', name);
  stats = surrogate.analyze(output);
  fprintf('%s: done in %.2f seconds.\n', name, toc(time));

  computeExpectation = ~isfield(stats, 'expectation') || ...
    isempty(stats.expectation) || any(isnan(stats.expectation(:)));
  computeVariance = ~isfield(stats, 'variance') || ...
    isempty(stats.variance) || any(isnan(stats.variance(:)));

  if ~isfield(output, 'data')
    time = tic;
    fprintf('%s: collecting %d samples...\n', name, sampleCount);
    output.data = surrogate.sample(output, sampleCount);
    fprintf('%s: done in %.2f seconds.\n', name, toc(time));
  end

  if computeExpectation
    stats.expectation = mean(output.data, 1);
  end

  if computeVariance
    stats.variance = var(output.data, [], 1);
  end

  temperature = struct;
  energy = struct;
  lifetime = struct;

  [ temperature.expectation, energy.expectation, lifetime.expectation ] = ...
    decode(stats.expectation);

  [ temperature.variance, energy.variance, lifetime.variance ] = ...
    decode(stats.variance);

  [ temperature.data, energy.data, lifetime.data ] = ...
    decode(output.data);

  [ T, output ] = surrogate.temperature.computeWithLeakage( ...
    options.dynamicPower);

  temperature.nominal = max(T(:));
  energy.nominal = options.samplingInterval * sum(output.P(:));
  lifetime.nominal = surrogate.fatigue.compute(T);

  stats = struct;
  stats.temperature = temperature;
  stats.energy = energy;
  stats.lifetime = lifetime;
end

function [ temperature, energy, lifetime ] = decode(data)
  temperature = data(:, 1);
  energy = data(:, 2);
  lifetime = data(:, 3);
end
