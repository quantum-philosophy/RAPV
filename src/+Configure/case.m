function options = Case(varargin)
  options = Options(varargin{:});

  options.ensure('processorCount', 4);
  options.ensure('taskCount', 20 * options.processorCount);
  options.ensure('caseNumber', 1);

  options.setupName = sprintf('%03d_%03d', ...
    options.processorCount, options.taskCount);

  options.caseName = File.join(options.setupName, ...
    sprintf('%03d', options.caseNumber));
end
