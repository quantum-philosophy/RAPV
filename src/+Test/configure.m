function options = configure(varargin)
  options = Configure.systemSimulation( ...
    'assetPath', File.join('+Test', 'Assets'), varargin{:});
  options.leakageModel = 'LinearInterpolation';
  options.leakageOptions.LCount = 50;
  options.leakageOptions.TCount = 50;
  options.leakageOptions.TLimit = Utils.toKelvin([0, 400]);
  options.leakageOptions.order = [ 3, 2 ];

  options = Configure.processVariation(options);
  options.processModel = 'Normal';
  options.processOptions.threshold = 0.96;

  options = Configure.polynomialChaos(options);
  options.surrogateOptions.order = 4;

  options.steadyStateOptions = Options( ...
    'algorithm', 'condensedEquation', ...
    'version', 2, ...
    'iterationLimit', 20, ...
    'temperatureLimit', Utils.toKelvin(400), ...
    'tolerance', 0.5, ...
    'verbose', true);

  options.optimizationOptions = Options( ...
    'sampleCount', 1e4, ...
    'temperatureLimit', Utils.toKelvin(120));

  geneticOptions = gaoptimset;
  geneticOptions.PopulationSize = 10;
  geneticOptions.EliteCount = floor(0.05 * geneticOptions.PopulationSize); % uniobjective
  geneticOptions.CrossoverFraction = 0.8;
  geneticOptions.ParetoFraction = 1; % multiobjective
  geneticOptions.Generations = 500;
  geneticOptions.StallGenLimit = 100;
  geneticOptions.TolFun = 0;
  geneticOptions.SelectionFcn = @selectiontournament;
  geneticOptions.CrossoverFcn = @crossoversinglepoint;
  geneticOptions.UseParallel = 'always';
  geneticOptions.MutationRate = 0.01; % non-standard

  options.geneticOptions = geneticOptions;
end
