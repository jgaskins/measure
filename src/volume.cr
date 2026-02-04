module Measure
  struct Volume
    include Comparable(self)

    # The numeric part of the measurement — the `1` in `1.liter`.
    getter magnitude : Float64

    # The unit used in measuring the volume.
    getter unit : Unit

    # Instantiate a `Volume` instance with the given `magnitude` and `Unit`.
    def initialize(@magnitude, @unit)
    end

    # Returns the number of liters represented by this `Volume` instance
    def total_liters : Float64
      magnitude / coefficient
    end

    # Output a human-readable representation of this `Volume` to the given `IO`.
    def to_s(io : IO) : Nil
      io << magnitude << ' '
      unit.to_s.downcase io
    end

    # Convert this instance to the given `Unit`.
    #
    # ```
    # 1.gallon.to(:liters)
    # # => Measure::Volume(@magnitude=3.78541, @unit=Measure::Volume::Unit::Liter)
    # ```
    def to(unit : Unit) : self
      coefficient = coefficient(unit) / coefficient(self.unit)
      self.class.new(coefficient * magnitude, unit)
    end

    # Add two `Volume`s of any units together, returning an instance using
    # `self`'s `Unit`.
    #
    # ```
    # 1.liter + 1.gallon
    # # => Measure::Volume(@magnitude=4.78541, @unit=Measure::Volume::Unit::Liter)
    # ```
    def +(other : self) : self
      self.class.new(magnitude + other.to(unit).magnitude, unit)
    end

    # Subtract a `Volume` from `self`, returning an instance using `self`'s
    # `Unit`.
    #
    # ```
    # 1.gallon - 1.liter
    # # => Measure::Volume(@magnitude=0.735764, @unit=Measure::Volume::Unit::Gallon)
    # ```
    def -(other : self) : self
      self.class.new(magnitude - other.to(unit).magnitude, unit)
    end

    # Multiply by a scalar value
    #
    # ```
    # 2.liters * 5
    # # => Measure::Volume(@magnitude=10.0, @unit=Measure::Volume::Unit::Liter)
    # ```
    def *(scalar : Number) : self
      self.class.new(magnitude * scalar, unit)
    end

    # Divide by a scalar value
    #
    # ```
    # 10.liters / 2
    # # => Measure::Volume(@magnitude=5.0, @unit=Measure::Volume::Unit::Liter)
    # ```
    def /(scalar : Number) : self
      raise DivisionByZeroError.new if scalar == 0
      self.class.new(magnitude / scalar, unit)
    end

    # Returns `-1` if `self` is less than `other`, `0` if they're equal, or `1`
    # otherwise.
    #
    # ```
    # 1.gallon <=> 1.liter # => 1
    # 1.liter <=> 1.liter  # => 0
    # 1.liter <=> 1.gallon # => -1
    # 1.liter < 1.gallon   # => true
    # 1.liter > 1.gallon   # => false
    # ```
    def <=>(other : self)
      total_liters <=> other.total_liters
    end

    # Returns `true` if `self` and `other` are close enough to each other to be
    # considered equivalent. This isn't _technically_ correct, but if you need
    # that level of precision,
    # [open an issue](https://github.com/jgaskins/measure/issues/new)
    # and we can discuss how to support it.
    def ==(other : self)
      # If it's within the float ε, we can call it close enough
      (total_liters - other.total_liters).abs < Float64::EPSILON
    end

    private def coefficient(unit : Unit = self.unit)
      case unit
      in .liter?, .liters?, .l?
        1
      in .milliliter?, .milliliters?, .ml?
        1e3
      in .centiliter?, .centiliters?, .cl?
        1e2
      in .kiloliter?, .kiloliters?, .kl?
        1e-3
      in .cubic_meter?, .cubic_meters?, .m3?
        1e-3
      in .cubic_centimeter?, .cubic_centimeters?, .cc?, .cm3?
        1e3
      in .cubic_millimeter?, .cubic_millimeters?, .mm3?
        1e6
      in .cubic_micrometer?, .cubic_micrometers?, .cubic_micron?, .cubic_microns?
        1e15
      in .cubic_nanometer?, .cubic_nanometers?, .nm3?
        1e24
      in .cubic_foot?, .cubic_feet?, .ft3?
        1 / LITERS_PER_CUBIC_FOOT
      in .cubic_yard?, .cubic_yards?, .yd3?
        1 / (LITERS_PER_CUBIC_FOOT * 27)
      in .cubic_inch?, .cubic_inches?, .in3?
        1728 / LITERS_PER_CUBIC_FOOT
      in .cubic_mile?, .cubic_miles?, .mi3?
        1.0 / (LITERS_PER_CUBIC_FOOT * 5280.0 ** 3)
      in .gallon?, .gallons?, .gal?
        GALLONS_PER_LITER
      in .quart?, .quarts?, .qt?
        GALLONS_PER_LITER * 4
      in .pint?, .pints?, .pt?
        GALLONS_PER_LITER * 8
      in .cup?, .cups?
        GALLONS_PER_LITER * 16
      in .fluid_ounce?, .fluid_ounces?, .fl_oz?
        GALLONS_PER_LITER * 128
      in .tablespoon?, .tablespoons?, .tbsp?
        GALLONS_PER_LITER * 256
      in .teaspoon?, .teaspoons?, .tsp?
        GALLONS_PER_LITER * 768
      end
    end

    private LITERS_PER_CUBIC_FOOT = 28.316846592
    private GALLONS_PER_LITER     =     0.264172

    # The units available to `Volume` instances. Note that there are multiple
    # aliases of each one. This allows you to say `volume.to(:liters)` or
    # `volume.to(:ml)`.
    enum Unit
      Liter
      Liters = Liter
      L      = Liter

      Milliliter
      Milliliters = Milliliter
      ML          = Milliliter

      Centiliter
      Centiliters = Centiliter
      CL          = Centiliter

      Kiloliter
      Kiloliters = Kiloliter
      KL         = Kiloliter

      CubicMeter
      CubicMeters = CubicMeter
      M3          = CubicMeter

      CubicCentimeter
      CubicCentimeters = CubicCentimeter
      CC               = CubicCentimeter
      CM3              = CubicCentimeter

      CubicMillimeter
      CubicMillimeters = CubicMillimeter
      MM3              = CubicMillimeter

      CubicMicrometer
      CubicMicrometers = CubicMicrometer
      CubicMicron      = CubicMicrometer
      CubicMicrons     = CubicMicrometer

      CubicNanometer
      CubicNanometers = CubicNanometer
      NM3             = CubicNanometer

      CubicFoot
      CubicFeet = CubicFoot
      Ft3       = CubicFoot

      CubicYard
      CubicYards = CubicYard
      Yd3        = CubicYard

      CubicInch
      CubicInches = CubicInch
      In3         = CubicInch

      CubicMile
      CubicMiles = CubicMile
      Mi3        = CubicMile

      Gallon
      Gallons = Gallon
      Gal     = Gallon

      Quart
      Quarts = Quart
      Qt     = Quart

      Pint
      Pints = Pint
      Pt    = Pint

      Cup
      Cups = Cup

      FluidOunce
      FluidOunces = FluidOunce
      FlOz        = FluidOunce

      Tablespoon
      Tablespoons = Tablespoon
      Tbsp        = Tablespoon

      Teaspoon
      Teaspoons = Teaspoon
      Tsp       = Teaspoon
    end
  end
end

struct Number
  {% for unit in Measure::Volume::Unit.constants %}
    # Instantiate a `Measure::Volume` of `self` {{unit.downcase.id}}
    #
    # ```
    # 1.{{unit.underscore.id}}
    # # => Measure::Volume(@magnitude=1.0, @unit=Measure::Volume::Unit::{{unit}})
    # ```
    def {{unit.underscore.id}}
      Measure::Volume.new(to_f64, :{{unit.underscore.id}})
    end
  {% end %}
end
