module ODE
  ODESystem = Struct.new(:derivative) do
    def derivative(t, y)
      self.derivative.call(t, y)
    end
  end

  StepResult = Struct.new(:t, :y)
end
