function systemVariation = SystemVariation(varargin)
  options = Options(varargin{:});

  surrogate = options.get('surrogate', 'PolynomialChaos');

  systemVariation = SystemVariation.(surrogate)(options);
end
