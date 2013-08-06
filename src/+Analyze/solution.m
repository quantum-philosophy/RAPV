function [ MTTFexp, Pburn, output ] = solution(pc, output, varargin)
  options = Options(varargin{:});

  data = pc.sample(output, options.sampleCount);
  Tdata = data(:, 2:end);

  MTTFexp = output.expectation(1);
  Pburn = mean(max(Tdata, [], 2) > options.temperatureLimit);

  if nargout < 3, return; end

  output.MTTFexp = MTTFexp;
  output.MTTFvar = output.variance(1);
  output.MTTFdata = data(data(:, 1) > 0, 1);

  output.Texp = Utils.unpackPeaks( ...
    output.expectation(2:end), output.lifetimeOutput);
  output.Tvar = Utils.unpackPeaks( ...
    output.variance(2:end), output.lifetimeOutput);
  output.Tdata = Tdata;
end
