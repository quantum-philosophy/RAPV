function track(this, state, flag)
  if this.objective.dimensionCount == 1
    printUniobjective(state, flag);
    plotUniobjective(state, flag);
  else
    printMultiobjective(state, flag);
    plotMultiobjective(state, flag);
  end
end

function printUniobjective(state, flag)
  switch flag
  case 'init'
    fprintf('%10s%15s%15s%15s%15s\n', 'Generation', 'Evaluations', ...
      'Cached', 'Discarded', 'Best');
  case { 'iter', 'done' }
    fprintf('%10d%15d%15.2f%15.2f%15.2e\n', ...
      state.Generation, state.FunEval, ...
      state.cachedCount / state.FunEval, ...
      state.discardedCount / state.FunEval, ...
      state.Best(end));
  end
end

function printMultiobjective(state, flag)
  switch flag
  case 'init'
    fprintf('%10s%15s%15s%15s%15s\n', 'Generation', 'Evaluations', ...
      'Cached', 'Discarded', 'Non-dominants');
  case { 'iter', 'done' }
    fprintf('%10d%15d%15.2f%15.2f%15d\n', ...
      state.Generation, state.FunEval, ...
      state.cachedCount / state.FunEval, ...
      state.discardedCount / state.FunEval, ...
      sum(state.Rank == 1));
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
    f = findobj('Tag', 'figure');

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
    f = findobj('Tag', 'figure');

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
