module Measure
  struct Weight
    include Comparable(self)

    # The numeric part of the measurement — the `1` in `1.kilogram`.
    getter magnitude : Float64

    # The unit used in measuring the weight.
    getter unit : Unit

    # Instantiate a `Weight` instance with the given `magnitude` and `Unit`.
    def initialize(@magnitude, @unit)
    end

    # Returns the number of grams represented by this `Weight` instance
    def total_grams
      magnitude / coefficient
    end

    # Output a human-readable representation of this `Weight` to the given `IO`.
    def to_s(io) : Nil
      io << magnitude << ' '
      unit.to_s.downcase io
    end

    # Convert this instance to the given `Unit`.
    #
    # ```
    # 1.kilogram.to(:lbs)
    # # => Measure::Weight(@magnitude=2.20462, @unit=Measure::Weight::Unit::Pound)
    # ```
    def to(unit : Unit) : self
      coefficient = coefficient(unit) / coefficient(self.unit)
      self.class.new(coefficient * magnitude, unit)
    end

    # Add two `Weight`s of any units together, returning an instance using
    # `self`'s `Unit`.
    #
    # ```
    # 1.kilogram + 1.pound
    # # => Measure::Weight(@magnitude=1.4535929094356397, @unit=Measure::Weight::Unit::Kilogram)
    # ```
    def +(other : self) : self
      self.class.new(magnitude + other.to(unit).magnitude, unit)
    end

    # Subtract a `Length` from `self`, returning an instance using `self`'s
    # `Unit`.
    #
    # ```
    # 1.kilogram - 1.pound
    # # => Measure::Weight(@magnitude=0.5464070905643603, @unit=Measure::Weight::Unit::Kilogram)
    # ```
    def -(other : self) : self
      self.class.new(magnitude - other.to(unit).magnitude, unit)
    end

    # Multiply by a scalar value
    #
    # ```
    # 2.kg * 5
    # # => Measure::Length(@magnitude=10.0, @unit=Measure::Length::Unit::Kilogram)
    # ```
    def *(scalar : Number) : self
      self.class.new(magnitude * scalar, unit)
    end

    # Multiply by a scalar value
    #
    # ```
    # 10.kg / 2
    # # => Measure::Length(@magnitude=2.0, @unit=Measure::Length::Unit::Kilogram)
    # ```
    def /(scalar : Number) : self
      raise DivisionByZeroError.new if scalar == 0
      self.class.new(magnitude / scalar, unit)
    end

    # Returns `-1` if `self` is less than `other`, `0` if they're equal, or `-1`
    # otherwise.
    #
    # ```
    # 1.kg <=> 1.lb # => 1
    # 1.lb <=> 1.lb # => 0
    # 1.lb <=> 1.kg # => -1
    # 1.lb < 1.kg   # => true
    # 1.lb > 1.kg   # => false
    # ```
    def <=>(other : self)
      total_grams <=> other.total_grams
    end

    # Returns `true` if `self` and `other` are close enough to each other to be
    # considered equivalent — within a femtogram (1/1_000_000_000_000_000th of
    # a gram). This isn't _technically_ correct, but if you need that level of
    # precision, [open an issue](https://github.com/jgaskins/measure/issues/new)
    # and we can discuss how to support it.
    def ==(other : self)
      # If it's within a femtogram, we can call it close enough
      (total_grams - other.total_grams).abs < 1e-15
    end

    private def coefficient(unit : Unit = self.unit)
      case unit
      in .gram?, .grams?, .g?
        1
      in .kilogram?, .kilograms?, .kg?
        1 / 1_000
      in .milligram?, .milligrams?, .mg?
        1_000
      in .pound?, .pounds?, .lb?, .lbs?
        POUNDS_PER_GRAM
      in .ounce?, .ounces?, .oz?
        POUNDS_PER_GRAM * 16
      in .ton?, .tons?, .t?
        POUNDS_PER_GRAM / 2_000
      end
    end

    private POUNDS_PER_GRAM = 0.00220462

    # The units available to `Weight` instances. Note that there are multiple
    # aliases of each one. This allows you to say `weight.to(:pounds)` or
    # `weight.to(:kilograms)`.
    enum Unit
      Gram
      Grams = Gram
      G     = Gram

      Kilogram
      Kilograms = Kilogram
      KG        = Kilogram

      Milligram
      Milligrams = Milligram
      MG         = Milligram

      Pound
      Pounds = Pound
      LB     = Pound
      LBS    = Pound

      Ounce
      Ounces = Ounce
      OZ     = Ounce

      Ton
      Tons = Ton
      T    = Ton
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
