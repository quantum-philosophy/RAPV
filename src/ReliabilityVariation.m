function reliabilityVariation = ReliabilityVariation(varargin)
  options = Options(varargin{:});

  surrogate = options.get('surrogate', 'PolynomialChaos');

  reliabilityVariation = ReliabilityVariation.(surrogate)(options);
end
