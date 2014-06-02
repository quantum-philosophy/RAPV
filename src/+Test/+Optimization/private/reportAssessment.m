function reportAssessment(quantities, optimizationOutput, assessmentOutput)
  [ caseCount, iterationCount ] = size(optimizationOutput);

  failCount = 0;

  fprintf('%10s%10s%10s (%40s)\n', 'Case', 'Iteration', 'Result', ...
    'Offset / Violation, %');
  for i = 1:caseCount
    %
    % NOTE: Not ready for multiple objectives.
    %
    fitness = NaN(1, iterationCount);
    valid = false(1, iterationCount);

    for j = 1:iterationCount
      %
      % NOTE: Not ready for multiple solutions.
      %
      solutionCount = length(optimizationOutput{i, j}.solutions);
      assert(solutionCount == 1);

      solution = optimizationOutput{i, j}.solutions{1};
      assessment = assessmentOutput{i, j}.solutions{1};

      if all(solution.fitness < Objective.Base.maximalFitness)
        fitness(j) = solution.fitness;
      end

      fprintf('%10d%10d', i, j);
      if any(assessment.violation > 0)
        fprintf('%10s (', 'failed');
        fprintf('%10.2f', assessment.violation * 100);
        fprintf(')');
      else
        valid(j) = true;

        fprintf('%10s (', 'passed');
        change = solution.expectation ./ quantities.nominal;
        trueChange = assessment.expectation ./ quantities.nominal;
        fprintf('%10.2f', (trueChange - change) * 100);
        fprintf(')');
      end
      fprintf('\n');
    end

    J = find(~isnan(fitness));
    [ ~, k ] = min(fitness(J));

    if isempty(J) || ~valid(J(k))
      failCount = failCount + 1;
    end
  end

  fprintf('\n');
  fprintf('Failure rate: %.2f %%\n', failCount / caseCount * 100);
end
