require "./spec_helper"

require "measure/weight"

private alias Unit = Measure::Weight::Unit

describe Measure::Weight do
  it "has a magnitude and a unit" do
    weight = Measure::Weight.new(1, :pound)

    weight.magnitude.should eq 1
    weight.unit.pound?.should eq true
  end

  describe "#total_grams" do
    {
      1.gram      => 1,
      1.kilogram  => 1_000,
      1.milligram => 0.001,
      1.pound     => 453.592,
      1.ounce     => 28.3495,
      1.ton       => 907_185.81887,
    }.each do |measurement, grams|
      it "converts #{measurement} to #{grams} grams" do
        measurement.total_grams.should be_within 0.001, of: grams
      end
    end
  end

  describe "#to(unit : Unit)" do
    {
      {1.gram, 1, Unit::Grams},
      {1.pound, 453.592, Unit::Grams},
      {1.kilogram, 2.20462, Unit::Pounds},
      {1.ounce, 0.0625, Unit::Pounds},
      {1.ton, 2_000, Unit::Pounds},
      {1.ton, 1, Unit::Tons},
      {1_000.grams, 1, Unit::Kilograms},
      {500.grams, 0.5, Unit::Kilograms},
      {16.ounces, 1, Unit::Pounds},
      {1.pound, 16, Unit::Ounces},
    }.each do |measurement, magnitude, unit|
      it "converts #{measurement} to #{magnitude} #{unit}" do
        measurement.to(unit).magnitude.should be_within 0.001, of: magnitude
      end
    end
  end

  describe "arithmetic operators" do
    describe "#+(other : self)" do
      [
        {1.pound, 1.pound, 2.pounds},
        {1.kilogram, 500.grams, 1.5.kilograms},
        {1.ton, 2_000.pounds, 2.tons},
      ].each do |a, b, sum|
        it "adds #{a} + #{b} == #{sum}" do
          (a + b).should eq sum
        end
      end

      it "returns the value with the first weight's unit" do
        (1.pound + 16.ounces).unit.should eq Unit::Pounds
      end
    end

    describe "#-(other : self)" do
      [
        {2.pounds, 1.pound, 1.pound},
        {1.kilogram, 500.grams, 0.5.kilograms},
        {1.ton, 1_000.pounds, 0.5.tons},
      ].each do |a, b, difference|
        it "subtracts #{a} - #{b} == #{difference}" do
          (a - b).should eq difference
        end
      end

      it "returns the value with the first weight's unit" do
        (2.pounds - 16.ounces).unit.should eq Unit::Pounds
      end
    end

    describe "#*(scalar : Number)" do
      [
        {2.pounds, 3, 6.pounds},
        {1.kilogram, 2, 2.kilograms},
        {1.ton, 0.5, 1_000.pounds},
      ].each do |weight, scalar, result|
        it "multiplies #{weight} by #{scalar} to get #{result}" do
          (weight * scalar).should eq result
        end
      end
    end

    describe "#/(scalar : Number)" do
      [
        {6.pounds, 3, 2.pounds},
        {1.kilogram, 2, 0.5.kilograms},
        {1.ton, 2, 1_000.pounds},
      ].each do |weight, scalar, result|
        it "divides #{weight} by #{scalar} to get #{result}" do
          (weight / scalar).should eq result
        end
      end

      it "raises DivisionByZeroError when dividing by zero" do
        expect_raises(DivisionByZeroError) do
          1.pound / 0
        end
      end
    end
  end

  describe "inequality operators" do
    describe "#==" do
      {
        [1.ton, 2_000.pounds, 32_000.ounces],
        [0.0005.tons, 1.pound, 16.ounces],
        [1.kilogram, 1_000.grams, 1_000_000.milligrams],
      }.each &.each_permutation 2 do |(a, b)|
        it "treats #{a} as equal to #{b}" do
          a.should eq b
        end
      end
    end

    describe "#<" do
      it "returns true if the weight is less than the other" do
        1.pound.should be < 2.pounds
        1.kilogram.should be < 1.ton
      end

      it "returns false if the weight is not less than the other" do
        2.pounds.should_not be < 1.pound
        1.ton.should_not be < 1.kilogram
      end
    end

    describe "#>" do
      it "returns true if the weight is greater than the other" do
        2.pounds.should be > 1.pound
        1.ton.should be > 1.kilogram
      end

      it "returns false if the weight is not greater than the other" do
        1.pound.should_not be > 2.pounds
        1.kilogram.should_not be > 1.ton
      end
    end

    describe "#<=" do
      it "returns true if the weight is less than or equal to the other" do
        1.pound.should be <= 2.pounds
        1.kilogram.should be <= 1.ton
        1.pound.should be <= 1.pound
      end

      it "returns false if the weight is not less than or equal to the other" do
        2.pounds.should_not be <= 1.pound
        1.ton.should_not be <= 1.kilogram
      end
    end

    describe "#>=" do
      it "returns true if the weight is greater than or equal to the other" do
        2.pounds.should be >= 1.pound
        1.ton.should be >= 1.kilogram
        1.pound.should be >= 1.pound
      end

      it "returns false if the weight is not greater than or equal to the other" do
        1.pound.should_not be >= 2.pounds
        1.kilogram.should_not be >= 1.ton
      end
    end
  end
end
