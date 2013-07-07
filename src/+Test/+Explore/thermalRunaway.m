function thermalRunaway
  close all;
  setup;

  options = Test.configure('processorCount', 2, ...
    'expectation', 45e-9, 'deviation', 0.05 * 45e-9);
  steadyStateOptions = options.steadyStateOptions;

  chaos = Temperature.Chaos.DynamicSteadyState(options);
  display(chaos);

  dimensionCount = chaos.process.dimensionCount;

  pairs = combnk(1:dimensionCount, 2);

  switch options.processModel
  case 'Beta'
    x = linspace( ...
      chaos.process.transformation.customDistribution.a + 1e-6, ...
      chaos.process.transformation.customDistribution.b - 1e-6, 20);
  otherwise
    assert(false);
  end

  y = x;

  [ X, Y ] = meshgrid(x, y);

  for k = 1:size(pairs, 1)
    rvs = zeros(dimensionCount, length(x)^2);
    rvs(pairs(k, :), :) = [ X(:)'; Y(:)' ];

    L = chaos.process.evaluate(rvs')';

    [ T, output ] = chaos.computeWithLeakage( ...
      options.dynamicPower, 'L', L, steadyStateOptions);

    R = reshape(output.iterationCount, length(x), []);
    Tmax = Utils.toCelsius( ...
      reshape(max(max(T, [], 1), [], 2), length(x), []));

    figure;
    Plot.title('Variables %d and %d', pairs(k, 1), pairs(k, 2));

    subplot(1, 2, 1);
    surfc(X, Y, R);
    Colormap.data(R, [ 0, steadyStateOptions.iterationLimit ]);
    zlim([ 0, steadyStateOptions.iterationLimit ]);
    view(50, 50);

    subplot(1, 2, 2);
    surfc(X, Y, Tmax);
    Colormap.data(Tmax, [ 0, Utils.toCelsius(steadyStateOptions.temperatureLimit) ]);
    zlim([ 0, Utils.toCelsius(steadyStateOptions.temperatureLimit) ]);
    view(50, 50);
  end
end
