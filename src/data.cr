struct Measure::Data
  include Comparable(self)

  getter magnitude : Float64
  getter unit : Unit

  def initialize(@magnitude, @unit)
  end

  def total_bytes
    magnitude / coefficient
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
    total_bytes <=> other.total_bytes
  end

  def ==(other : self)
    pp self: { inspect: self, total_bytes: total_bytes},
      other: { inspect: other, total_bytes: other.total_bytes }
    # If it's within 1 bit, we can call it close enough
    (total_bytes - other.total_bytes).abs < 1/8
  end

  private def coefficient(unit : Unit = self.unit)
    case unit
    in .bit?, .bits?
      8
    in .byte?, .bytes?, .b?
      1
    in .kilobyte?, .kilobytes?, .kb?
      1e-3
    in .megabyte?, .megabytes?, .mb?
      1e-6
    in .gigabyte?, .gigabytes?, .gb?
      1e-9
    in .terabyte?, .terabytes?, .tb?
      1e-12
    in .petabyte?, .petabytes?, .pb?
      1e-15
    in .kibibyte?, .kibibytes?, .ki_b?
      1 / (1 << 10)
    in .mibibyte?, .mibibytes?, .mi_b?
      1 / (1 << 20)
    in .gibibyte?, .gibibytes?, .gi_b?
      1 / (1 << 30)
    in .tibibyte?, .tibibytes?, .ti_b?
      1 / (1 << 40)
    in .pibibyte?, .pibibytes?, .pi_b?
      1 / (1 << 50)
    end
  end

  enum Unit
    Bit
    Bits = Bit

    Byte
    Bytes = Byte
    B     = Byte

    Kilobyte
    Kilobytes = Kilobyte
    KB        = Kilobyte

    Megabyte
    Megabytes = Megabyte
    MB        = Megabyte

    Gigabyte
    Gigabytes = Gigabyte
    GB        = Gigabyte

    Terabyte
    Terabytes = Terabyte
    TB        = Terabyte

    Petabyte
    Petabytes = Petabyte
    PB        = Petabyte

    Kibibyte
    Kibibytes = Kibibyte
    KiB       = Kibibyte

    Mibibyte
    Mibibytes = Mibibyte
    MiB       = Mibibyte

    Gibibyte
    Gibibytes = Gibibyte
    GiB       = Gibibyte

    Tibibyte
    Tibibytes = Tibibyte
    TiB       = Tibibyte

    Pibibyte
    Pibibytes = Pibibyte
    PiB       = Pibibyte
  end
end

struct Number
  {% for unit in Measure::Data::Unit.constants %}
    def {{unit.downcase.id}}
      Measure::Data.new(to_f64, :{{unit.downcase.id}})
    end
  {% end %}
end
