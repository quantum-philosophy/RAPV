function computeNominal(varargin)
  setup;

  options = Test.configure( ...
    'mapping', @(processorCount, taskCount) randi(processorCount, 1, taskCount), ...
    'priority', @(processorCount, taskCount) rand(1, taskCount), varargin{:});

  temperature = Temperature(options.temperatureOptions);
  fatigue = Fatigue(options.fatigueOptions);

  [ T, output ] = temperature.compute(options.dynamicPower);
  plot(temperature, T);

  temperature = max(T(:));
  energy = options.samplingInterval * sum(output.P(:));

  [ lifetime, output ] = fatigue.compute(T);
  plot(fatigue, output);

  fprintf('Maximal temperature:  %.2f C\n', Utils.toCelsius(temperature));
  fprintf('Energy consumption:   %.2f J\n', energy);
  fprintf('Mean time to failure: %.2f years\n', Utils.toYears(lifetime));
end
