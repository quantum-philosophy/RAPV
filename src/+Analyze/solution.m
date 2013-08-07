function [ MTTF, Pburn, output ] = solution(pc, output, varargin)
  options = Options(varargin{:});

  data = pc.sample(output, options.sampleCount);

  MTTF = output.expectation(1);
  Pburn = mean(max(data(:, 2:end), [], 2) > options.temperatureLimit);

  if nargout < 3, return; end

  etaData = data(data(:, 1) >= 0, 1) / gamma(1 + 1 / output.lifetimeOutput.beta);
  TTFdata = etaData .* (log(1 ./ (1 - rand(length(etaData), 1)))).^ ...
    (1 / output.lifetimeOutput.beta);

  output.TTFexp = MTTF;
  output.TTFvar = output.variance(1);
  output.TTFdata = TTFdata;

  output.Texp = Utils.unpackPeaks( ...
    output.expectation(2:end), output.lifetimeOutput);
  output.Tvar = Utils.unpackPeaks( ...
    output.variance(2:end), output.lifetimeOutput);
  output.Tdata = data(:, 2:end);
end
