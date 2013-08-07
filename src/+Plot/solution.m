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
  Plot.title('Maximal temperature');
  Plot.label('Temperature, C', 'Probability');
  Plot.legend('Probability density', sprintf('P(burn) = %.2f%%', Pburn * 100));

  if options.has('name')
    prefix = [ options.name, ': ' ];
  else
    prefix = '';
  end

  Plot.name('%sE(MTTF) = %.2e, P(Tmax > %.2f C) = %.2f%%', prefix, ...
    MTTFexp, Utils.toCelsius(options.temperatureLimit), Pburn * 100);

  Data.observe(output.MTTFdata, 'range', 'unbounded');
  Plot.vline(MTTFexp, 'Color', 'k', 'LineStyle', '--');
  Plot.title('Mean time to failure');
  Plot.label('Time, s', 'Probability');
  Plot.legend('Probability density', sprintf('E(MTTF) = %.2e', MTTFexp));
end
