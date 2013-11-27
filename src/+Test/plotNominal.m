function plotNominal(varargin)
  setup;

  options = Test.configure( ...
    'mapping', @(processorCount, taskCount) randi(processorCount, 1, taskCount), ...
    'priority', @(processorCount, taskCount) rand(1, taskCount), varargin{:});

  temperature = Temperature(options.temperatureOptions);
  fatigue = Fatigue(options.fatigueOptions);

  T = temperature.compute(options.dynamicPower);
  plot(temperature, T);

  [ expectation, output ] = fatigue.compute(T);

  fprintf('Mean time to failure: %.2f years\n', Utils.toYears(expectation));

  plot(fatigue, output);
end
