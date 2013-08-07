function [ MTTF, Pburn, output ] = solution(pc, output, varargin)
  options = Options(varargin{:});

  [ MTTF, Pburn, output ] = Analyze.solution(pc, output, options);

  Plot.figure(1000, 300);
  if options.has('name'), Plot.name(options.name); end

  %
  % Thermal cycles
  %
  subplot(1, 2, 1);
  Plot.temperatureVariation(output.Texp, output.Tvar, ...
    'figure', false, 'layout', 'one', ...
    'index', output.lifetimeOutput.peakIndex);
  Plot.title('Thermal cycles');

  %
  % Probability density of the maximal temperature
  %
  subplot(1, 2, 2);
  Data.observe(Utils.toCelsius(max(output.Tdata, [], 2)), ...
    'figure', false, 'layout', 'one', 'range', 'unbounded');
  Plot.vline(Utils.toCelsius(options.temperatureLimit), ...
    'Color', 'k', 'LineStyle', '--');
  Plot.title('Maximal temperature');
  Plot.label('Temperature, C', 'Probability');
  Plot.legend('Probability density', ...
    sprintf('P(burn) = %.2f%%', Pburn * 100));

  %
  % Probability density of the time to failure
  %
  Data.observe(Utils.toYears(output.TTFdata), 'range', 'unbounded');
  Plot.vline(Utils.toYears(MTTF), 'Color', 'k', 'LineStyle', '--');
  Plot.title('Time to failure');
  Plot.label('Time, years', 'Probability');
  Plot.legend('Probability density', ...
    sprintf('MTTF = %.2f years', Utils.toYears(MTTF)));
end
