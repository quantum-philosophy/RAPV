function speedWithSteps
  speed( ...
    'range', [ 1e1 1e2 1e3 1e4 1e5 ], ...
    'repeat', [ 4 4 1 1 1 ], ...
    'configure', @(stepCount) Test.configure( ...
      'processorCount', 4, 'stepCount', stepCount));
end
