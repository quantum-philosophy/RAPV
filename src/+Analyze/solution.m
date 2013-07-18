function [ MTTF, Pburn, output ] = solution(pc, output, varargin)
  options = Options(varargin{:});

  MTTF = output.lifetimeOutput.totalMTTF;

  maximalData = max(pc.sample(output, options.sampleCount), [], 2);
  Pburn = mean(maximalData > options.temperatureLimit);

  if nargout < 3, return; end

  output.expectation = Utils.unpackPeaks( ...
    output.expectation, output.lifetimeOutput);
  output.variance = Utils.unpackPeaks( ...
    output.variance, output.lifetimeOutput);
  output.maximalData = maximalData;
end
