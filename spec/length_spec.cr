require "./spec_helper"

require "measure/length"
require "json"

private alias Unit = Measure::Length::Unit

describe Measure::Length do
  it "has a magnitude and a unit" do
    length = Measure::Length.new(1, :foot)

    length.magnitude.should eq 1
    length.unit.foot?.should eq true
  end

  describe "#total_meters" do
    {
      1.foot  => 0.3048,
      1.meter => 1,
      1.yard  => 0.9144,
      1.mile  => 1609.344,
    }.each do |measurement, meters|
      it "converts #{measurement} to #{meters} meters" do
        measurement.total_meters.should be_within 0.0001, of: meters
      end
    end
  end

  describe "#to(unit : Unit)" do
    {
      {1.meter, 1, Unit::Meters},
      {1.foot, 0.3048, Unit::Meters},
      {1.meter, 3.28084, Unit::Feet},
      {1.yard, 0.9144, Unit::Meters},
      {1.mile, 1609.344, Unit::Meters},
      {1.mile, 1.609344, Unit::Kilometers},
      {5280.feet, 1, Unit::Mile},
      {1.kilometer, 1_000, Unit::Meters},
      {100.meters, 0.1, Unit::Kilometers},
      {6.inches, 0.5, Unit::Feet},
      {1.foot, 12, Unit::Inches},
      {1.meter, 1_000, Unit::Millimeters},
      {1.meter, 1_000_000, Unit::Micrometers},
      {1.meter, 1_000_000_000, Unit::Nanometers},
    }.each do |measurement, magnitude, unit|
      it "converts #{measurement} to #{magnitude} #{unit}" do
        measurement.to(unit).magnitude.should be_within 0.001, of: magnitude
      end
    end
  end

  describe "arithmetic operators" do
    describe "#+(other : self)" do
      [
        {1.foot, 1.foot, 2.feet},
        {1.yard, 12.inches, 4.feet},
        {1.kilometer, 100.meters, 1_100.meters},
      ].each do |a, b, sum|
        it "adds #{a} + #{b} == #{sum}" do
          (a + b).should eq sum
        end
      end

      it "returns the value with the first length's unit" do
        (1.foot + 6.inches).unit.should eq Unit::Feet
      end

      it "handles very large lengths" do
        (1e20.meters + 1e20.meters).should eq 2e20.meters
      end

      it "handles very small lengths" do
        (1e-20.meters + 1e-20.meters).should eq 2e-20.meters
      end

      it "handles zero-length measurements" do
        (0.meters + 1.foot).should eq 1.foot
      end
    end

    describe "#-(other : self)" do
      [
        {2.feet, 1.foot, 1.foot},
        {1.yard, 12.inches, 2.feet},
        {1.kilometer, 100.meters, 900.meters},
      ].each do |a, b, difference|
        it "subtracts #{a} - #{b} == #{difference}" do
          (a - b).should eq difference
        end
      end

      it "returns the value with the first length's unit" do
        (2.feet - 6.inches).unit.should eq Unit::Feet
      end
    end

    describe "#*(scalar : Number)" do
      [
        {2.feet, 3, 6.feet},
        {1.yard, 2, 2.yards},
        {1.kilometer, 0.5, 500.meters},
      ].each do |length, scalar, result|
        it "multiplies #{length} by #{scalar} to get #{result}" do
          (length * scalar).should eq result
        end
      end
    end

    describe "#*(length : Length)" do
      [
        {2.inches, 3.inches, 6.square_inches},
        {2.feet, 1.yard, 6.square_feet},
        {2.feet, 3.feet, 6.square_feet},
        {2.feet, 3.feet, 6.square_feet},
        {2.feet, 3.feet, 6.square_feet},
      ].each do |a, b, result|
        it "multiplies #{a} by #{b} to get #{result}" do
          (a * b).should eq result
        end
      end
    end

    describe "#/(scalar : Number)" do
      [
        {6.feet, 3, 2.feet},
        {1.yard, 2, 0.5.yards},
        {1.kilometer, 2, 500.meters},
      ].each do |length, scalar, result|
        it "divides #{length} by #{scalar} to get #{result}" do
          (length / scalar).should eq result
        end
      end

      it "raises DivisionByZeroError when dividing by zero" do
        expect_raises(DivisionByZeroError) do
          1.foot / 0
        end
      end
    end

    describe "#squared" do
      {
        {3.feet, 9.square_feet},
        {1.yard, 1.square_yard},
        {100.mm, 0.01.square_meters},
        {100.microns, 0.01.square_millimeters},
      }.each do |length, result|
        it "converts #{length} cubed to #{result}" do
          length.squared.should eq result
        end
      end
    end

    describe "#cubed" do
      {
        {3.feet, 27.cubic_feet},
        {1.yard, 1.cubic_yard},
        {3.mm, 27.cubic_millimeters},
      }.each do |length, result|
        it "converts #{length} cubed to #{result}" do
          length.cubed.should eq result
        end
      end
    end
  end

  describe "inequality operators" do
    describe "#==" do
      {
        [1.mile, 5280.feet, 1760.yards],
        [1.foot, 12.inches],
        [1.yard, 3.feet, 36.inches],
        [1.kilometer, 1_000.meters],
        # Floats are fun: 0.1 + 0.2 == 0.30000000000000004
        # We ignore rounding errors like this because even our unit conversions
        # aren't this precise.
        [0.3.meters, (0.1 + 0.2).meters],
      }.each &.each_permutation 2 do |(a, b)|
        it "treats #{a} as equal to #{b}" do
          a.should eq b
        end
      end
    end

    describe "#<" do
      it "returns true if the length is less than the other" do
        1.foot.should be < 2.feet
        1.yard.should be < 1.meter
      end

      it "returns false if the length is not less than the other" do
        2.feet.should_not be < 1.foot
        1.meter.should_not be < 1.yard
      end
    end

    describe "#>" do
      it "returns true if the length is greater than the other" do
        2.feet.should be > 1.foot
        1.meter.should be > 1.yard
      end

      it "returns false if the length is not greater than the other" do
        1.foot.should_not be > 2.feet
        1.yard.should_not be > 1.meter
      end
    end

    describe "#<=" do
      it "returns true if the length is less than or equal to the other" do
        1.foot.should be <= 2.feet
        1.yard.should be <= 1.meter
        1.foot.should be <= 1.foot
      end

      it "returns false if the length is not less than or equal to the other" do
        2.feet.should_not be <= 1.foot
        1.meter.should_not be <= 1.yard
      end
    end

    describe "#>=" do
      it "returns true if the length is greater than or equal to the other" do
        2.feet.should be >= 1.foot
        1.meter.should be >= 1.yard
        1.foot.should be >= 1.foot
      end

      it "returns false if the length is not greater than or equal to the other" do
        1.foot.should_not be >= 2.feet
        1.yard.should_not be >= 1.meter
      end
    end
  end

  describe "JSON serialization" do
    describe "#to_json" do
      it "serializes the length to JSON" do
        2.feet.to_json.should eq %({"magnitude":2.0,"unit":"foot"})
      end
    end

    describe ".from_json" do
      it "deserializes the length from JSON" do
        length = Measure::Length.from_json(%({"magnitude":2.0,"unit":"foot"}))
        length.should eq 2.feet
      end
    end
  end
end
