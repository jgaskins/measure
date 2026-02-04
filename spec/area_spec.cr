require "./spec_helper"

require "measure/volume"
require "measure/area"
require "measure/length"

private alias Unit = Measure::Area::Unit

describe Measure::Area do
  it "has a magnitude and a unit" do
    area = Measure::Area.new(1, :acre)

    area.magnitude.should eq 1
    area.unit.acre?.should eq true
  end

  describe "#total_square_meters" do
    {
      1.square_meter      => 1,
      1.square_kilometer  => 1_000_000,
      1.square_centimeter => 0.0001,
      1.square_millimeter => 0.000001,
      1.square_foot       => 0.092903,
      1.square_yard       => 0.836127,
      1.square_inch       => 0.00064516,
      1.square_mile       => 2_589_988.11,
      1.acre              => 4_046.8564224,
      1.hectare           => 10_000,
      1.square_micrometer => 1e-12,
      1.square_nanometer  => 1e-18,
    }.each do |measurement, square_meters|
      it "converts #{measurement} to #{square_meters} square meters" do
        measurement.total_square_meters.should be_within 0.01, of: square_meters
      end
    end
  end

  describe "#to(unit : Unit)" do
    {
      {1.square_meter, 1, Unit::SquareMeters},
      {1.acre, 4_046.8564224, Unit::SquareMeters},
      {1.hectare, 2.47105, Unit::Acres},
      {1.square_kilometer, 100, Unit::Hectares},
      {1.square_mile, 640, Unit::Acres},
      {1.square_foot, 144, Unit::SquareInches},
      {1.square_yard, 9, Unit::SquareFeet},
      {1.square_meter, 10_000, Unit::SquareCentimeters},
      {1.square_meter, 1_000_000, Unit::SquareMillimeters},

      # Cross-system conversions (metric <-> imperial)
      {1.square_foot, 0.09290304, Unit::SquareMeters},
      {1.square_meter, 10.7639, Unit::SquareFeet},
      {1.acre, 0.404686, Unit::Hectares},
      {1.hectare, 10_000, Unit::SquareMeters},
      {1.square_mile, 2.58999, Unit::SquareKilometers},
      {1.square_kilometer, 0.386102, Unit::SquareMiles},
      {1.square_inch, 6.4516, Unit::SquareCentimeters},
      {1.square_yard, 0.836127, Unit::SquareMeters},

      # Micro/nano conversions
      {1.square_meter, 1e12, Unit::SquareMicrometers},
      {1.square_meter, 1e18, Unit::SquareNanometers},
      {1.square_centimeter, 1e8, Unit::SquareMicrometers},
      {1.square_millimeter, 1e6, Unit::SquareMicrometers},

      # Imperial internal conversions
      {1.square_mile, 27_878_400, Unit::SquareFeet},
      {1.acre, 43_560, Unit::SquareFeet},
      {1.square_mile, 3_097_600, Unit::SquareYards},
      {1.acre, 4_840, Unit::SquareYards},
    }.each do |measurement, magnitude, unit|
      it "converts #{measurement} to #{magnitude} #{unit}" do
        measurement.to(unit).magnitude.should be_within 0.01, of: magnitude
      end
    end
  end

  describe "arithmetic operators" do
    describe "#+(other : self)" do
      [
        {1.acre, 1.acre, 2.acres},
        {1.square_kilometer, 100.hectares, 2.square_kilometers},
      ].each do |a, b, sum|
        it "adds #{a} + #{b} == #{sum}" do
          (a + b).should eq sum
        end
      end

      it "adds hectares and acres" do
        (1.hectare + 1.acre).to(:hectares).magnitude.should be_within 0.0001, of: 1.40469
      end

      it "returns the value with the first area's unit" do
        (1.hectare + 1.acre).unit.should eq Unit::Hectares
      end
    end

    describe "#-(other : self)" do
      [
        {2.acres, 1.acre, 1.acre},
        {2.square_kilometers, 100.hectares, 1.square_kilometer},
      ].each do |a, b, difference|
        it "subtracts #{a} - #{b} == #{difference}" do
          (a - b).should eq difference
        end
      end

      it "subtracts hectares and acres" do
        (1.hectare - 1.acre).to(:hectares).magnitude.should be_within 0.0001, of: 0.59531
      end

      it "returns the value with the first area's unit" do
        (2.hectares - 1.acre).unit.should eq Unit::Hectares
      end
    end

    describe "#*(scalar : Number)" do
      [
        {2.acres, 3, 6.acres},
        {1.hectare, 2, 2.hectares},
        {1.square_kilometer, 0.5, 0.5.square_kilometers},
      ].each do |area, scalar, result|
        it "multiplies #{area} by #{scalar} to get #{result}" do
          (area * scalar).should eq result
        end
      end
    end

    describe "#*(length : Length)" do
      it "multiplies area by length to get volume" do
        area = 1.square_meter
        length = 1.meter
        volume = area * length

        volume.should be_a Measure::Volume
        volume.total_liters.should be_within 0.001, of: 1000
      end

      it "works with different units" do
        area = 1.square_foot
        length = 1.foot
        volume = area * length

        # 1 cubic foot ≈ 28.3168 liters
        volume.total_liters.should be_within 0.01, of: 28.3168
      end
    end

    describe "#/(scalar : Number)" do
      [
        {6.acres, 3, 2.acres},
        {1.hectare, 2, 0.5.hectares},
        {1.square_kilometer, 2, 0.5.square_kilometers},
      ].each do |area, scalar, result|
        it "divides #{area} by #{scalar} to get #{result}" do
          (area / scalar).should eq result
        end
      end

      it "raises DivisionByZeroError when dividing by zero" do
        expect_raises(DivisionByZeroError) do
          1.acre / 0
        end
      end
    end
  end

  describe "inequality operators" do
    describe "#==" do
      {
        [1.square_mile, 640.acres],
        [1.hectare, 10_000.square_meters],
        [1.square_yard, 9.square_feet, 1296.square_inches],
      }.each &.each_permutation 2 do |(a, b)|
        it "treats #{a} as equal to #{b}" do
          a.should eq b
        end
      end
    end

    describe "#<" do
      it "returns true if the area is less than the other" do
        1.acre.should be < 2.acres
        1.acre.should be < 1.hectare
      end

      it "returns false if the area is not less than the other" do
        2.acres.should_not be < 1.acre
        1.hectare.should_not be < 1.acre
      end
    end

    describe "#>" do
      it "returns true if the area is greater than the other" do
        2.acres.should be > 1.acre
        1.hectare.should be > 1.acre
      end

      it "returns false if the area is not greater than the other" do
        1.acre.should_not be > 2.acres
        1.acre.should_not be > 1.hectare
      end
    end

    describe "#<=" do
      it "returns true if the area is less than or equal to the other" do
        1.acre.should be <= 2.acres
        1.acre.should be <= 1.hectare
        1.acre.should be <= 1.acre
      end

      it "returns false if the area is not less than or equal to the other" do
        2.acres.should_not be <= 1.acre
        1.hectare.should_not be <= 1.acre
      end
    end

    describe "#>=" do
      it "returns true if the area is greater than or equal to the other" do
        2.acres.should be >= 1.acre
        1.hectare.should be >= 1.acre
        1.acre.should be >= 1.acre
      end

      it "returns false if the area is not greater than or equal to the other" do
        1.acre.should_not be >= 2.acres
        1.acre.should_not be >= 1.hectare
      end
    end
  end
end

describe Measure::Length do
  describe "#*(other : Length)" do
    it "multiplies two lengths to get an area" do
      length1 = 2.meters
      length2 = 3.meters
      area = length1 * length2

      area.should be_a Measure::Area
      area.total_square_meters.should be_within 0.001, of: 6
    end

    it "works with different units" do
      length1 = 1.foot
      length2 = 1.yard
      area = length1 * length2

      # 1 foot * 1 yard = 3 square feet
      area.to(:square_feet).magnitude.should be_within 0.001, of: 3
    end
  end

  describe "#squared" do
    it "returns the area of a square with the given side length" do
      length = 5.meters
      area = length.squared

      area.should be_a Measure::Area
      area.total_square_meters.should be_within 0.001, of: 25
    end

    it "works with different units" do
      length = 3.feet
      area = length.squared

      area.to(:square_feet).magnitude.should be_within 0.001, of: 9
    end
  end

  describe "#cubed" do
    it "returns the volume of a cube with the given side length" do
      length = 2.meters
      volume = length.cubed

      volume.should be_a Measure::Volume
      volume.total_liters.should be_within 0.001, of: 8000
    end

    it "works with different units" do
      length = 1.foot
      volume = length.cubed

      # 1 cubic foot ≈ 28.3168 liters
      volume.total_liters.should be_within 0.01, of: 28.3168
    end
  end
end
