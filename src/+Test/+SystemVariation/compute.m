function compute(varargin)
  setup;
  options = Test.configure(varargin{:});
  [ surrogate, output ] = construct(options);
  stats = postprocess(surrogate, output, options);
  report(surrogate, output, stats);
end
