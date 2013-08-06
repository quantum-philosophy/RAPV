function [ MTTFexp, Pburn, output ] = solution(pc, output, varargin)
  options = Options(varargin{:});

  [ MTTFexp, Pburn, output ] = Analyze.solution(pc, output, options);

  Plot.figure(1000, 300);

  subplot(1, 2, 1);
  Plot.temperatureVariation(output.Texp, output.Tvar, ...
    'figure', false, 'layout', 'one', 'index', output.lifetimeOutput.peakIndex);
  Plot.title('E(MTTF) = %.2e', MTTFexp);

  subplot(1, 2, 2);
  Data.observe(Utils.toCelsius(max(output.Tdata, [], 2)), ...
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

  Plot.name('%sE(MTTF) = %.2e, P(Tmax > %.2f C) = %.4f', ...
    prefix, MTTFexp, Utils.toCelsius(options.temperatureLimit), Pburn);

  Data.observe(output.MTTFdata, 'range', 'unbounded');
  Plot.label('MTTF', 'Probability');
  Plot.title('Probability density');
end
