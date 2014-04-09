classdef Genetic < Optimization.Base
  properties (SetAccess = 'protected')
    verbose
    visualize
    geneticOptions
  end

  methods
    function this = Genetic(varargin)
      options = Options(varargin{:});

      this = this@Optimization.Base(options);

      this.verbose = options.get('verbose', true);
      this.visualize = options.get('visualize', true);

      geneticOptions = gaoptimset;

      geneticOptions.PopulationSize = 20;
      geneticOptions.CrossoverFraction = 0.8;
      geneticOptions.Generations = 100;
      geneticOptions.StallGenLimit = 20;
      geneticOptions.TolFun = 0;
      geneticOptions.TolCon = 0;
      geneticOptions.SelectionFcn = @selectiontournament;
      geneticOptions.CrossoverFcn = @crossoversinglepoint;
      geneticOptions.UseParallel = 'never';
      geneticOptions.Vectorized = 'on';
      geneticOptions.MutationRate = 0.01; % non-standard

      %
      % Uniobjective
      %
      geneticOptions.EliteCount = ...
        floor(0.05 * geneticOptions.PopulationSize);

      %
      % Multiobjective
      %
      geneticOptions.ParetoFraction = 1;

      if options.has('geneticOptions')
        names = fieldnames(options.geneticOptions);
        for i = 1:length(names);
          geneticOptions.(names{i}) = options.geneticOptions.(names{i});
        end
      end

      this.geneticOptions = geneticOptions;
    end
  end
end
