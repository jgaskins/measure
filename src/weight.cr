module Measure
  struct Weight
    include Comparable(self)

    getter magnitude : Float64
    getter unit : Unit

    def initialize(@magnitude, @unit)
    end

    def total_grams
      magnitude / coefficient
    end

    def to_s(io) : Nil
      io << magnitude << ' '
      unit.to_s.downcase io
    end

    def to(unit : Unit) : self
      coefficient = coefficient(unit) / coefficient(self.unit)
      self.class.new(coefficient * magnitude, unit)
    end

    def +(other : self) : self
      self.class.new(magnitude + other.to(unit).magnitude, unit)
    end

    def -(other : self) : self
      self.class.new(magnitude - other.to(unit).magnitude, unit)
    end

    def *(scalar : Number) : self
      self.class.new(magnitude * scalar, unit)
    end

    def /(scalar : Number) : self
      raise DivisionByZeroError.new if scalar == 0
      self.class.new(magnitude / scalar, unit)
    end

    def <=>(other : self)
      total_grams <=> other.total_grams
    end

    def ==(other : self)
      # If it's within a femtogram, we can call it close enough
      (total_grams - other.total_grams).abs < 1e-15
    end

    private def coefficient(unit : Unit = self.unit)
      case unit
      in .gram?, .grams?
        1
      in .kilogram?, .kilograms?, .kg?
        1 / 1_000
      in .milligram?, .milligrams?, .mg?
        1_000
      in .pound?, .pounds?, .lb?
        POUNDS_PER_GRAM
      in .ounce?, .ounces?, .oz?
        POUNDS_PER_GRAM * 16
      in .ton?, .tons?, .t?
        POUNDS_PER_GRAM / 2_000
      end
    end

    private POUNDS_PER_GRAM = 0.00220462

    enum Unit
      Gram
      Grams      = Gram
      Kilogram
      Kilograms  = Kilogram
      KG         = Kilogram
      Milligram
      Milligrams = Milligram
      MG         = Milligram
      Pound
      Pounds     = Pound
      LB         = Pound
      Ounce
      Ounces     = Ounce
      OZ         = Ounce
      Ton
      Tons       = Ton
      T          = Ton
    end
  end
end

struct Number
  {% for unit in Measure::Weight::Unit.constants %}
    def {{unit.downcase.id}}
      Measure::Weight.new(to_f64, :{{unit.downcase.id}})
    end
  {% end %}
end
