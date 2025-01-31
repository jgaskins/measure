require "json"

module Measure
  struct Length
    include Comparable(self)
    include JSON::Serializable

    getter magnitude : Float64
    getter unit : Unit

    def initialize(@magnitude, @unit)
    end

    def total_meters
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
      total_meters <=> other.total_meters
    end

    def ==(other : self)
      # If it's within a femtometer, we can call it close enough
      (total_meters - other.total_meters).abs < 1e-15
    end

    private def coefficient(unit : Unit = self.unit)
      case unit
      in .meter?, .meters?
        1
      in .kilometer?, .kilometers?, .km?
        0.001
      in .centimeter?, .centimeters? , .cm?
        100
      in .millimeter?, .millimeters?, .mm?
        1_000
      in .micrometer?, .micrometers?, .micron?, .microns?
        1_000_000
      in .nanometer?, .nanometers?, .nm?
        1_000_000_000
      in .foot?, .feet?
        FEET_PER_METER
      in .yard?, .yards?
        FEET_PER_METER / 3
      in .inch?, .inches?
        FEET_PER_METER * 12
      in .mile?, .miles?, .mi?
        FEET_PER_METER / 5280
      end
    end

    private FEET_PER_METER = 3.28084

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

      Yard
      Yards = Yard

      Inch
      Inches = Inch

      Mile
      Miles = Mile
      Mi    = Mile
    end
  end
end

struct Number
  {% for unit in Measure::Length::Unit.constants %}
    def {{unit.downcase.id}}
      Measure::Length.new(to_f64, :{{unit.downcase.id}})
    end
  {% end %}
end
