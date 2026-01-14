require "./spec_helper"

require "measure/volume"

private alias Unit = Measure::Volume::Unit

describe Measure::Volume do
  it "has a magnitude and a unit" do
    volume = Measure::Volume.new(1, :gallon)

    volume.magnitude.should eq 1
    volume.unit.gallon?.should eq true
  end

  describe "#total_liters" do
    {
      1.liter      => 1,
      1.milliliter => 0.001,
      1.centiliter => 0.01,
      1.kiloliter  => 1_000,
      1.gallon     => 3.78541,
      1.quart      => 0.946353,
      1.pint       => 0.473176,
      1.cup        => 0.236588,
      1.fl_oz      => 0.0295735,
      1.tbsp       => 0.0147868,
      1.tsp        => 0.00492892,
      1.m3         => 1_000,
      1.cc         => 0.001,
    }.each do |measurement, liters|
      it "converts #{measurement} to #{liters} liters" do
        measurement.total_liters.should be_within 0.0001, of: liters
      end
    end
  end

  describe "#to(unit : Unit)" do
    {
      {1.liter, 1, Unit::Liters},
      {1.gallon, 3.78541, Unit::Liters},
      {1.liter, 0.264172, Unit::Gallons},
      {1.quart, 0.946353, Unit::Liters},
      {4.quarts, 1, Unit::Gallons},
      {1.gallon, 4, Unit::Quarts},
      {1.gallon, 8, Unit::Pints},
      {1.gallon, 16, Unit::Cups},
      {1.gallon, 128, Unit::FluidOunces},
      {1.liter, 1_000, Unit::Milliliters},
      {1_000.milliliters, 1, Unit::Liters},
      {1.kiloliter, 1_000, Unit::Liters},
      {1.m3, 1_000, Unit::Liters},
      {1.liter, 1_000, Unit::CC},
      {1.cc, 1, Unit::Milliliters},
      {1.tbsp, 3, Unit::Teaspoons},
      {1.fl_oz, 2, Unit::Tablespoons},
    }.each do |measurement, magnitude, unit|
      it "converts #{measurement} to #{magnitude} #{unit}" do
        measurement.to(unit).magnitude.should be_within 0.001, of: magnitude
      end
    end
  end

  describe "arithmetic operators" do
    describe "#+(other : self)" do
      [
        {1.liter, 1.liter, 2.liters},
        {1.gallon, 1.quart, 1.25.gallons},
        {1.liter, 500.milliliters, 1.5.liters},
      ].each do |a, b, sum|
        it "adds #{a} + #{b} == #{sum}" do
          (a + b).should eq sum
        end
      end

      it "returns the value with the first volume's unit" do
        (1.gallon + 1.quart).unit.should eq Unit::Gallons
      end

      it "handles very large volumes" do
        (1e20.liters + 1e20.liters).should eq 2e20.liters
      end

      it "handles very small volumes" do
        (1e-20.liters + 1e-20.liters).should eq 2e-20.liters
      end

      it "handles zero-volume measurements" do
        (0.liters + 1.gallon).should eq 1.gallon
      end
    end

    describe "#-(other : self)" do
      [
        {2.liters, 1.liter, 1.liter},
        {1.gallon, 1.quart, 0.75.gallons},
        {1.liter, 500.milliliters, 0.5.liters},
      ].each do |a, b, difference|
        it "subtracts #{a} - #{b} == #{difference}" do
          (a - b).should eq difference
        end
      end

      it "returns the value with the first volume's unit" do
        (2.gallons - 1.quart).unit.should eq Unit::Gallons
      end
    end

    describe "#*(scalar : Number)" do
      [
        {2.liters, 3, 6.liters},
        {1.gallon, 2, 2.gallons},
        {1.kiloliter, 0.5, 500.liters},
      ].each do |volume, scalar, result|
        it "multiplies #{volume} by #{scalar} to get #{result}" do
          (volume * scalar).should eq result
        end
      end
    end

    describe "#/(scalar : Number)" do
      [
        {6.liters, 3, 2.liters},
        {1.gallon, 2, 0.5.gallons},
        {1.kiloliter, 2, 500.liters},
      ].each do |volume, scalar, result|
        it "divides #{volume} by #{scalar} to get #{result}" do
          (volume / scalar).should eq result
        end
      end

      it "raises DivisionByZeroError when dividing by zero" do
        expect_raises(DivisionByZeroError) do
          1.liter / 0
        end
      end
    end
  end

  describe "inequality operators" do
    describe "#==" do
      {
        [1.gallon, 4.quarts, 8.pints, 16.cups],
        [1.liter, 1_000.milliliters, 100.centiliters],
        [1.m3, 1_000.liters, 1.kiloliter],
        [1.fl_oz, 2.tablespoons, 6.teaspoons],
        # Floats are fun: 0.1 + 0.2 == 0.30000000000000004
        # We ignore rounding errors like this because even our unit conversions
        # aren't this precise.
        [0.3.liters, (0.1 + 0.2).liters],
      }.each &.each_permutation 2 do |(a, b)|
        it "treats #{a} as equal to #{b}" do
          a.should eq b
        end
      end
    end

    describe "#<" do
      it "returns true if the volume is less than the other" do
        1.liter.should be < 2.liters
        1.quart.should be < 1.liter
      end

      it "returns false if the volume is not less than the other" do
        2.liters.should_not be < 1.liter
        1.gallon.should_not be < 1.liter
      end
    end

    describe "#>" do
      it "returns true if the volume is greater than the other" do
        2.liters.should be > 1.liter
        1.gallon.should be > 1.liter
      end

      it "returns false if the volume is not greater than the other" do
        1.liter.should_not be > 2.liters
        1.quart.should_not be > 1.liter
      end
    end

    describe "#<=" do
      it "returns true if the volume is less than or equal to the other" do
        1.liter.should be <= 2.liters
        1.quart.should be <= 1.liter
        1.liter.should be <= 1.liter
      end

      it "returns false if the volume is not less than or equal to the other" do
        2.liters.should_not be <= 1.liter
        1.gallon.should_not be <= 1.liter
      end
    end

    describe "#>=" do
      it "returns true if the volume is greater than or equal to the other" do
        2.liters.should be >= 1.liter
        1.gallon.should be >= 1.liter
        1.liter.should be >= 1.liter
      end

      it "returns false if the volume is not greater than or equal to the other" do
        1.liter.should_not be >= 2.liters
        1.quart.should_not be >= 1.liter
      end
    end
  end
end
