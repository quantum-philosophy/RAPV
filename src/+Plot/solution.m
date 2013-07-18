function [ MTTF, Pburn, output ] = solution(pc, output, varargin)
  options = Options(varargin{:});

  [ MTTF, Pburn, output ] = Analyze.solution(pc, output, options);

  figure('Position', [ 100, 500, 1000, 300 ]);

  subplot(1, 2, 1);
  Plot.temperatureVariation(output.expectation, output.variance, ...
    'figure', false, 'layout', 'one', 'index', output.lifetimeOutput.peakIndex);
  Plot.title('MTTF = %.2e', MTTF);

  subplot(1, 2, 2);
  Data.observe(Utils.toCelsius(output.maximalData), ...
    'figure', false, 'layout', 'one', 'range', 'unbounded');
  Plot.vline(Utils.toCelsius(options.temperatureLimit), ...
    'Color', 'k', 'LineStyle', '--');
  Plot.label('Temperature, C', 'Probability');
  Plot.title('P(Tmax > %.2f C) = %.4f', ...
    Utils.toCelsius(options.temperatureLimit), Pburn);
  Plot.legend('Probability density', 'Temperature limit');

  if options.has('name')
    prefix = [ options.name, ': ' ];
  else
    prefix = '';
  end

  Plot.name('%sMTTF = %.2e, P(Tmax > %.2f C) = %.4f', ...
    prefix, MTTF, Utils.toCelsius(options.temperatureLimit), Pburn);
end
