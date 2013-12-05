function compute(varargin)
  setup;

  options = Configure.problem(varargin{:});
  [ surrogate, output ] = construct(options);
  stats = postprocess(surrogate, output, options);
  report(surrogate, output, stats);
end
