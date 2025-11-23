require "json"

module Measure
  struct Length
    include Comparable(self)
    include JSON::Serializable

    # The numeric part of the measurement — the `1` in `1.meter`.
    getter magnitude : Float64

    # The unit used in measuring the length.
    getter unit : Unit

    # Instantiate a `Length` instance with the given `magnitude` and `Unit`.
    def initialize(@magnitude, @unit)
    end

    # Returns the number of meters represented by this `Length` instance
    def total_meters : Float64
      magnitude / coefficient
    end

    # Output a human-readable representation of this `Length` to the given `IO`.
    def to_s(io : IO) : Nil
      io << magnitude << ' '
      unit.to_s.downcase io
    end

    # Convert this instance to the given `Unit`.
    #
    # ```
    # 1.mile.to(:feet)
    # # => Measure::Length(@magnitude=5280.0, @unit=Measure::Length::Unit::Foot)
    # ```
    def to(unit : Unit) : self
      coefficient = coefficient(unit) / coefficient(self.unit)
      self.class.new(coefficient * magnitude, unit)
    end

    # Add two `Length`s of any units together, returning an instance using
    # `self`'s `Unit`.
    #
    # ```
    # 1.kilometer + 1.mile
    # # => Measure::Length(@magnitude=2.6093439485009937, @unit=Measure::Length::Unit::Kilometer)
    # ```
    def +(other : self) : self
      self.class.new(magnitude + other.to(unit).magnitude, unit)
    end

    # Subtract a `Length` from `self`, returning an instance using `self`'s
    # `Unit`.
    #
    # ```
    # 1.mile - 1.kilometer
    # # => Measure::Length(@magnitude=0.37862878787878795, @unit=Measure::Length::Unit::Mile)
    # ```
    def -(other : self) : self
      self.class.new(magnitude - other.to(unit).magnitude, unit)
    end

    # Multiply by a scalar value
    #
    # ```
    # 2.miles * 5
    # # => Measure::Length(@magnitude=10.0, @unit=Measure::Length::Unit::Mile)
    # ```
    def *(scalar : Number) : self
      self.class.new(magnitude * scalar, unit)
    end

    # Multiply by a scalar value
    #
    # ```
    # 10.miles / 2
    # # => Measure::Length(@magnitude=5.0, @unit=Measure::Length::Unit::Mile)
    # ```
    def /(scalar : Number) : self
      raise DivisionByZeroError.new if scalar == 0
      self.class.new(magnitude / scalar, unit)
    end

    # Returns `-1` if `self` is less than `other`, `0` if they're equal, or `-1`
    # otherwise.
    #
    # ```
    # 1.mile <=> 1.kilometer # => 1
    # 1.mile <=> 1.mile      # => 0
    # 1.kilometer <=> 1.mile # => -1
    # 1.kilometer < 1.mile   # => true
    # 1.kilometer > 1.mile   # => false
    # ```
    def <=>(other : self)
      total_meters <=> other.total_meters
    end

    # Returns `true` if `self` and `other` are close enough to each other to be
    # considered equivalent — within a femtometer (1/1_000_000_000_000_000th of
    # a meter). This isn't _technically_ correct, but if you need that level of
    # precision, [open an issue](https://github.com/jgaskins/measure/issues/new)
    # and we can discuss how to support it.
    def ==(other : self)
      # If it's within the float ε, we can call it close enough
      (total_meters - other.total_meters).abs < Float64::EPSILON
    end

    private def coefficient(unit : Unit = self.unit)
      case unit
      in .meter?, .meters?
        1
      in .kilometer?, .kilometers?, .km?
        0.001
      in .centimeter?, .centimeters?, .cm?
        100
      in .millimeter?, .millimeters?, .mm?
        1_000
      in .micrometer?, .micrometers?, .micron?, .microns?
        1_000_000
      in .nanometer?, .nanometers?, .nm?
        1_000_000_000
      in .foot?, .feet?, .ft?
        FEET_PER_METER
      in .yard?, .yards?, .yd?, .yds?
        FEET_PER_METER / 3
      in .inch?, .inches?, .in?
        FEET_PER_METER * 12
      in .mile?, .miles?, .mi?
        FEET_PER_METER / 5280
      end
    end

    private FEET_PER_METER = 3.28084

    # The units available to `Length` instances. Note that there are multiple
    # aliases of each one. This allows you to say `length.to(:meters)` or
    # `length.to(:km)`.
    enum Unit
      Kilometer
      Kilometers = Kilometer
      KM         = Kilometer

      Meter
      Meters = Meter

      Centimeter
      Centimeters = Centimeter
      CM          = Centimeter

      Millimeter
      Millimeters = Millimeter
      MM          = Millimeter

      Micrometer
      Micrometers = Micrometer
      Micron      = Micrometer
      Microns     = Micrometer

      Nanometer
      Nanometers = Nanometer
      NM         = Nanometer

      Foot
      Feet = Foot
      Ft   = Foot

      Yard
      Yards = Yard
      Yd    = Yard
      Yds   = Yard

      Inch
      Inches = Inch
      In     = Inch

      Mile
      Miles = Mile
      Mi    = Mile
    end
  end
end

struct Number
  {% for unit in Measure::Length::Unit.constants %}
    # Instantiate a `Measure::Length` of `self` {{unit.downcase.id}}
    #
    # ```
    # 1.{{unit.underscore.id}}
    # # => Measure::Length(@magnitude=1.0, @unit=Measure::Length::Unit::{{unit}})
    # ```
    def {{unit.underscore.id}}
      Measure::Length.new(to_f64, :{{unit.underscore.id}})
    end
  {% end %}
end
