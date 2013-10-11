function [ MTTF, Pburn, output ] = solution(surrogate, output, varargin)
  options = Options(varargin{:});

  [ MTTF, Pburn, output ] = Analyze.solution(surrogate, output, options);

  Plot.figure(1200, 300);
  if options.has('name'), Plot.name(options.name); end

  %
  % Thermal cycles
  %
  subplot(1, 3, 1);
  Plot.temperatureVariation(output.Texp, output.Tvar, ...
    'figure', false, 'layout', 'one', ...
    'index', output.lifetimeOutput.peakIndex);
  Plot.title('Thermal cycles');

  %
  % Probability density of the maximal temperature
  %
  subplot(1, 3, 2);
  Statistic.observe(Utils.toCelsius(max(output.Tdata, [], 2)), ...
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
  subplot(1, 3, 3);
  Statistic.observe(Utils.toYears(output.TTFdata), ...
    'figure', false, 'layout', 'one', 'range', 'unbounded');
  Plot.vline(Utils.toYears(MTTF), 'Color', 'k', 'LineStyle', '--');
  Plot.title('Time to failure');
  Plot.label('Time, years', 'Probability');
  Plot.legend('Probability density', ...
    sprintf('MTTF = %.2f years', Utils.toYears(MTTF)));
end
