function speedWithProcessors
  speed( ...
    'range', [ 2 4 8 16 32 ], ...
    'repeat', [ 4 2 1 1 1 ], ...
    'configure', @(processorCount) Test.configure( ...
      'processorCount', processorCount, 'stepCount', 1e3));
end
