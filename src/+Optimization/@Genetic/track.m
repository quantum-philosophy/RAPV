function track(this, state, flag)
  if isscalar(this.objective.quantities.targetIndex)
    if this.verbose, printUniobjective(state, flag); end
    if this.visualize, plotUniobjective(state, flag); end
  else
    if this.verbose, printMultiobjective(state, flag); end
    if this.visualize, plotMultiobjective(state, flag); end
  end
end

function printUniobjective(state, flag)
  switch flag
  case 'init'
    fprintf('%10s%15s%15s%15s%15s | %s\n', 'Generation', ...
      'Best', 'Evaluations', 'Cached', 'New', ...
      'Total violations | New violations');
  case { 'iter', 'done' }
    fprintf('%10d%15.2f%15d%15.2f%15.2f | ', ...
      state.Generation, ...
      state.Best(end), ...
      state.FunEval, ...
      state.cachedCount / state.FunEval, ...
      state.newCount / size(state.Population, 1));
    fprintf('%10.2f', state.violationCount / state.FunEval);
    fprintf(' | ');
    fprintf('%10.2f', state.newViolationCount / state.newCount);
    fprintf('\n');
  end
end

function printMultiobjective(state, flag)
  switch flag
  case 'init'
    fprintf('%10s%15s%15s%15s%15s | %s\n', 'Generation', ...
      'Solutions', 'Evaluations', 'Cached', 'New', ...
      'Total violations | New violations');
  case { 'iter', 'done' }
    fprintf('%10d%15d%15d%15.2f%15.2f | ', ...
      state.Generation, ...
      sum(state.Rank == 1), ...
      state.FunEval, ...
      state.cachedCount / state.FunEval, ...
      state.newCount / size(state.Population, 1));
    fprintf('%10.2f', state.violationCount / state.FunEval);
    fprintf(' | ');
    fprintf('%10.2f', state.newViolationCount / state.newCount);
    fprintf('\n');
  end
end

function plotUniobjective(state, flag)
  switch flag
  case 'init'
    f = Plot.figure;
    set(f, 'Tag', 'figure');

    Plot.label('Generation', 'Fitness');

    h = line(NaN, NaN, 'LineStyle', 'none', ...
      'Marker', '*', 'Color', Color.pick(1));
    set(h, 'Tag', 'all');
  case { 'iter', 'done' }
    f = max(findobj('Tag', 'figure'));

    Plot.title(f, '%d generations, %d solves, %.2f cached, %.2f discarded', ...
      state.Generation, state.FunEval, ...
      state.cachedCount / state.FunEval, ...
      state.discardedCount / state.FunEval);

    h = findobj(get(f, 'Children'), 'Tag', 'all');

    Xdata = get(h, 'Xdata');
    Ydata = get(h, 'Ydata');

    set(h, 'Xdata', [ Xdata, state.Generation ], ...
      'Ydata', [ Ydata, state.Best(end) ]);
  end

  drawnow;
end

function plotMultiobjective(state, flag)
  [ ~, I ] = sort(state.Score(:, 1));

  S = state.Score(I, :);
  R = state.Rank(I);

  switch flag
  case 'init'
    f = figure;
    set(f, 'Tag', 'figure');

    Plot.label('Objective 1', 'Objective 2');

    hold on;

    h = plot(S(:, 1), S(:, 2), 'LineStyle', 'none', ...
      'Marker', 'o', 'Color', Color.pick(1));
    set(h, 'Tag', 'active');

    h = plot(NaN, NaN, 'LineStyle', 'none', ...
      'Marker', '.', 'Color', 0.8 * [ 1, 1, 1 ]);
    set(h, 'Tag', 'inactive');

    h = plot(S(R == 1, 1), S(R == 1, 2), 'LineStyle', '-', ...
      'Marker', 'o', 'Color', Color.pick(2));
    set(h, 'Tag', 'front');

    hold off;
  case { 'iter', 'done' }
    f = max(findobj('Tag', 'figure'));

    Plot.title(f, '%d generations, %d solves, %.2f cached, %.2f discarded', ...
      state.Generation, state.FunEval, ...
      state.cachedCount / state.FunEval, ...
      state.discardedCount / state.FunEval);

    h = findobj(get(f, 'Children'), 'Tag', 'active');

    Xdata = get(h, 'Xdata');
    Ydata = get(h, 'Ydata');

    set(h, 'Xdata', S(:, 1), 'Ydata', S(:, 2));

    h = findobj(get(f, 'Children'), 'Tag', 'inactive');
    set(h, 'Xdata', [ get(h, 'Xdata'), Xdata ], ...
      'Ydata', [ get(h, 'Ydata'), Ydata ]);

    h = findobj(get(f, 'Children'), 'Tag', 'front');
    set(h, 'Xdata', S(R == 1, 1), 'Ydata', S(R == 1, 2));
  end

  drawnow;
end
