function [ surrogate, output ] = construct(options)
  iterationCount = options.get('iterationCount', 1);

  surrogate = SystemVariation(options);

  name = class(surrogate);

  time = tic;
  fprintf('%s: construction...\n', name);
  for i = 1:iterationCount
    output = surrogate.compute(options.dynamicPower);
  end
  fprintf('%s: done in %.2f seconds.\n', name, toc(time) / iterationCount);
end
