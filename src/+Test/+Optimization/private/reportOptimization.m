function reportOptimization(quantities, output, time)
  [ caseCount, iterationCount ] = size(output);

  globalValue = NaN(caseCount, iterationCount, quantities.count);
  globalChange = NaN(caseCount, iterationCount, quantities.count);
  bestIndex = NaN(caseCount, 1);

  fprintf('%10s%10s%10s', 'Case', 'Iteration', 'Time, m');
  for k = 1:quantities.count
    fprintf('%15s (%15s)', quantities.names{k}, 'Change, %');
  end
  fprintf('\n');

  for i = 1:caseCount
    for j = 1:iterationCount
      %
      % NOTE: Not ready for multiple solutions.
      %
      solutionCount = length(output{i, j}.solutions);
      assert(solutionCount == 1);

      solution = output{i, j}.solutions{1};

      fprintf('%10d%10d%10.2f', i, j, time(i, j) / 60);

      if any(solution.fitness >= Objective.Base.maximalFitness)
        fprintf('%15s (%15s)\n', 'NA', 'NA');
        continue;
      end

      %
      % NOTE: Not ready for multiobjective optimization.
      %
      if isnan(bestIndex(i)) || ...
        solution.fitness < output{i, bestIndex(i)}.solutions{1}.fitness

        bestIndex(i) = j;
      end

      for k = 1:quantities.count
        value = solution.expectation(k);
        change = value / quantities.nominal(k);

        globalValue(i, j, k) = value;
        globalChange(i, j, k) = change;

        fprintf('%15.2e (%15.2f)', value, change * 100);
      end

      fprintf('\n');
    end

    if iterationCount == 1 || isnan(bestIndex(i)), continue; end

    fprintf('%10s%10s%10.2f', 'Best', '', time(i, bestIndex(i)) / 60);
    for k = 1:quantities.count
      value = globalValue(i, bestIndex(i), k);
      change = globalChange(i, bestIndex(i), k);

      fprintf('%15.2e (%15.2f)', value, change * 100);
    end
    fprintf('\n\n');
  end

  I = find(~isnan(bestIndex));
  J = bestIndex(I);

  if isempty(I), return; end

  time = select(time, I, J);

  fprintf('%10s%10s%10.2f', 'Average', '', mean(time) / 60);
  for k = 1:quantities.count
    value = select(globalValue(:, :, k), I, J);
    change = select(globalChange(:, :, k), I, J);

    fprintf('%15.2e (%15.2f)', mean(value), mean(change) * 100);
  end
  fprintf('\n');
end

function result = select(A, I, J)
  result = zeros(1, length(I));
  for i = 1:length(I)
    result(i) = A(I(i), J(i));
  end
end
