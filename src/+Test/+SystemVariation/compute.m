function compute(varargin)
  setup;

  options = Configure.problem(varargin{:});
  [ surrogate, output ] = construct(options);
  stats = postprocess(surrogate, output);
  report(surrogate, output, stats);
end
