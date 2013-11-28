function [ surrogate, output ] = construct(options)
  surrogate = SystemVariation(options);

  name = class(surrogate);

  time = tic;
  fprintf('%s: construction...\n', name);
  output = surrogate.compute(options.dynamicPower);
  fprintf('%s: done in %.2f seconds.\n', name, toc(time));
end