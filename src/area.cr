require "./length"
require "./volume"

module Measure
  struct Area
    include Comparable(self)

    # The numeric part of the measurement — the `1` in `1.square_meter`.
    getter magnitude : Float64

    # The unit used in measuring the area.
    getter unit : Unit

    # Instantiate an `Area` instance with the given `magnitude` and `Unit`.
    def initialize(@magnitude, @unit)
    end

    # Returns the number of square meters represented by this `Area` instance
    def total_square_meters : Float64
      magnitude / coefficient
    end

    # Output a human-readable representation of this `Area` to the given `IO`.
    def to_s(io : IO) : Nil
      io << magnitude << ' '
      unit.to_s.underscore io
    end

    # Convert this instance to the given `Unit`.
    #
    # ```
    # 1.acre.to(:square_meters)
    # # => Measure::Area(@magnitude=4046.86, @unit=Measure::Area::Unit::SquareMeter)
    # ```
    def to(unit : Unit) : self
      coefficient = coefficient(unit) / coefficient(self.unit)
      self.class.new(coefficient * magnitude, unit)
    end

    # Add two `Area`s of any units together, returning an instance using
    # `self`'s `Unit`.
    #
    # ```
    # 1.acre + 1.hectare
    # # => Measure::Area(@magnitude=3.47105, @unit=Measure::Area::Unit::Acre)
    # ```
    def +(other : self) : self
      self.class.new(magnitude + other.to(unit).magnitude, unit)
    end

    # Subtract an `Area` from `self`, returning an instance using `self`'s
    # `Unit`.
    #
    # ```
    # 2.hectares - 1.acre
    # # => Measure::Area(@magnitude=1.59514, @unit=Measure::Area::Unit::Hectare)
    # ```
    def -(other : self) : self
      self.class.new(magnitude - other.to(unit).magnitude, unit)
    end

    # Multiply by a scalar value
    #
    # ```
    # 2.acres * 5
    # # => Measure::Area(@magnitude=10.0, @unit=Measure::Area::Unit::Acre)
    # ```
    def *(scalar : Number) : self
      self.class.new(magnitude * scalar, unit)
    end

    # Multiply by a `Length` to get a `Volume`
    #
    # ```
    # 1.square_meter * 1.meter
    # # => Measure::Volume(@magnitude=1.0, @unit=Measure::Volume::Unit::CubicMeter)
    # ```
    def *(other : Length) : Volume
      case unit
      in .square_meter?, .square_meters?, .sq_m?, .m2?
        Volume.new(magnitude * other.to(:meter).magnitude, :cubic_meter)
      in .square_kilometer?, .square_kilometers?, .sq_km?, .km2?
        Volume.new(to(:sq_m).magnitude * other.to(:meter).magnitude, :cubic_meter)
      in .square_centimeters?, .square_centimeter?, .sq_cm?, .cm2?
        Volume.new(magnitude * other.to(:cm).magnitude, :cubic_centimeter)
      in .square_millimeters?, .square_millimeter?, .sq_mm?, .mm2?
        Volume.new(magnitude * other.to(:mm).magnitude, :cubic_millimeter)
      in .square_micrometers?, .square_micrometer?
        Volume.new(magnitude * other.to(:micron).magnitude, :cubic_micrometer)
      in .square_nanometers?, .square_nanometer?, .sq_nm?, .nm2?
        Volume.new(magnitude * other.to(:nm).magnitude, :cubic_nanometer)
      in .square_feet?, .square_foot?, .sq_ft?, .ft2?
        Volume.new(magnitude * other.to(:ft).magnitude, :cubic_foot)
      in .square_yards?, .square_yard?, .sq_yd?, .yd2?
        Volume.new(magnitude * other.to(:yd).magnitude, :cubic_yard)
      in .square_inches?, .square_inch?, .sq_in?, .in2?
        Volume.new(magnitude * other.to(:in).magnitude, :cubic_inch)
      in .square_miles?, .square_mile?, .sq_mi?, .mi2?
        Volume.new(magnitude * other.to(:mi).magnitude, :cubic_mile)
      in .acres?, .acre?
        Volume.new(to(:sq_ft).magnitude * other.to(:ft).magnitude, :cubic_foot)
      in .hectares?, .hectare?, .ha?
        Volume.new(to(:sq_m).magnitude * other.to(:meter).magnitude, :cubic_meter)
      end
    end

    # Divide by a scalar value
    #
    # ```
    # 10.acres / 2
    # # => Measure::Area(@magnitude=5.0, @unit=Measure::Area::Unit::Acre)
    # ```
    def /(scalar : Number) : self
      raise DivisionByZeroError.new if scalar == 0
      self.class.new(magnitude / scalar, unit)
    end

    # Returns `-1` if `self` is less than `other`, `0` if they're equal, or `1`
    # otherwise.
    #
    # ```
    # 1.hectare <=> 1.acre # => 1
    # 1.acre <=> 1.acre    # => 0
    # 1.acre <=> 1.hectare # => -1
    # 1.acre < 1.hectare   # => true
    # 1.acre > 1.hectare   # => false
    # ```
    def <=>(other : self)
      total_square_meters <=> other.total_square_meters
    end

    # Returns `true` if `self` and `other` are close enough to each other to be
    # considered equivalent.
    def ==(other : self)
      # Use relative epsilon for large values
      a = total_square_meters
      b = other.total_square_meters
      diff = (a - b).abs
      largest = Math.max(a.abs, b.abs)
      diff <= largest * Float64::EPSILON * 8
    end

    private def coefficient(unit : Unit = self.unit)
      case unit
      in .square_meter?, .square_meters?, .sq_m?, .m2?
        1
      in .square_kilometer?, .square_kilometers?, .sq_km?, .km2?
        1e-6
      in .square_centimeter?, .square_centimeters?, .sq_cm?, .cm2?
        1e4
      in .square_millimeter?, .square_millimeters?, .sq_mm?, .mm2?
        1e6
      in .square_micrometer?, .square_micrometers?
        1e12
      in .square_nanometer?, .square_nanometers?, .sq_nm?, .nm2?
        1e18
      in .square_foot?, .square_feet?, .sq_ft?, .ft2?
        SQ_FEET_PER_SQ_METER
      in .square_yard?, .square_yards?, .sq_yd?, .yd2?
        SQ_FEET_PER_SQ_METER / 9
      in .square_inch?, .square_inches?, .sq_in?, .in2?
        SQ_FEET_PER_SQ_METER * 144
      in .square_mile?, .square_miles?, .sq_mi?, .mi2?
        ACRES_PER_SQ_METER / 640
      in .acre?, .acres?
        ACRES_PER_SQ_METER
      in .hectare?, .hectares?, .ha?
        1e-4
      end
    end

    # 1 foot = 0.3048 meters (exact), so 1 sq ft = 0.09290304 m²
    private SQ_FEET_PER_SQ_METER = 1 / 0.09290304
    # 1 acre = 43560 sq ft = 4046.8564224 m² (exact)
    private ACRES_PER_SQ_METER = 1 / 4_046.8564224

    # The units available to `Area` instances.
    enum Unit
      SquareMeter
      SquareMeters = SquareMeter
      SqM          = SquareMeter
      M2           = SquareMeter

      SquareKilometer
      SquareKilometers = SquareKilometer
      SqKM             = SquareKilometer
      KM2              = SquareKilometer

      SquareCentimeter
      SquareCentimeters = SquareCentimeter
      SqCM              = SquareCentimeter
      CM2               = SquareCentimeter

      SquareMillimeter
      SquareMillimeters = SquareMillimeter
      SqMM              = SquareMillimeter
      MM2               = SquareMillimeter

      SquareMicrometer
      SquareMicrometers = SquareMicrometer

      SquareNanometer
      SquareNanometers = SquareNanometer
      SqNM             = SquareNanometer
      NM2              = SquareNanometer

      SquareFoot
      SquareFeet = SquareFoot
      SqFt       = SquareFoot
      Ft2        = SquareFoot

      SquareYard
      SquareYards = SquareYard
      SqYd        = SquareYard
      Yd2         = SquareYard

      SquareInch
      SquareInches = SquareInch
      SqIn         = SquareInch
      In2          = SquareInch

      SquareMile
      SquareMiles = SquareMile
      SqMi        = SquareMile
      Mi2         = SquareMile

      Acre
      Acres = Acre

      Hectare
      Hectares = Hectare
      Ha       = Hectare
    end
  end
end

struct Number
  {% for unit in Measure::Area::Unit.constants %}
    # Instantiate a `Measure::Area` of `self` {{unit.underscore.id}}
    #
    # ```
    # 1.{{unit.underscore.id}}
    # # => Measure::Area(@magnitude=1.0, @unit=Measure::Area::Unit::{{unit}})
    # ```
    def {{unit.underscore.id}}
      Measure::Area.new(to_f64, :{{unit.underscore.id}})
    end
  {% end %}
end
