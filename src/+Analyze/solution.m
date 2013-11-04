function [ MTTF, Pburn, output ] = solution(surrogate, output, varargin)
  options = Options(varargin{:});

  data = surrogate.sample(output, options.sampleCount);

  stats = surrogate.analyze(output);

  MTTF = stats.expectation(1);
  Pburn = mean(max(data(:, 2:end), [], 2) > options.temperatureLimit);

  if nargout < 3, return; end

  etaData = data(data(:, 1) >= 0, 1) / gamma(1 + 1 / output.lifetimeOutput.beta);
  TTFdata = etaData .* (log(1 ./ (1 - rand(length(etaData), 1)))).^ ...
    (1 / output.lifetimeOutput.beta);

  output.TTFexp = MTTF;
  output.TTFvar = stats.variance(1);
  output.TTFdata = TTFdata;

  output.Texp = Utils.unpackPeaks( ...
    stats.expectation(2:end), output.lifetimeOutput);
  output.Tvar = Utils.unpackPeaks( ...
    stats.variance(2:end), output.lifetimeOutput);
  output.Tdata = data(:, 2:end);
end
