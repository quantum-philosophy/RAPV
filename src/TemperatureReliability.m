function temperatureReliability = TemperatureReliability(varargin)
  options = Options(varargin{:});

  surrogate = options.get('surrogate', 'PolynomialChaos');

  temperatureReliability = TemperatureReliability.(surrogate)(options);
end
