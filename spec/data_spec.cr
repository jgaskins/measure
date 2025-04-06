require "./spec_helper"

require "measure/data"

private alias Unit = Measure::Data::Unit

describe Measure::Data do
  it "has a magnitude and a unit" do
    data = Measure::Data.new(1, :kilobyte)

    data.magnitude.should eq 1
    data.unit.kilobyte?.should eq true
  end

  describe "#total_bytes" do
    {
      1.bit      => 1/8,
      1.byte     => 1,
      1.kilobyte => 1_000,
      1.kibibyte => 1_024,
      1.megabyte => 1_000_000,
      1.mibibyte => 1024 ** 2,
    }.each do |measurement, bytes|
      it "converts #{measurement} to #{bytes} bytes" do
        measurement.total_bytes.should be_within 0.001, of: bytes
      end
    end
  end

  describe "#to(unit : Unit)" do
    {
      1.byte => 1.byte,
      1.byte => 8.bits,
      1.kilobyte => 1_000.bytes,
      1.kibibyte => 1.024.kilobytes,
      1.kibibyte => 1_024.bytes,
      1.megabyte => 1_000.kilobytes,
      1.mibibyte => 1_024.kibibytes,
    }.each do |source, target|
      it "converts #{source} to #{target.magnitude} #{target.unit}" do
        source.to(target.unit).magnitude.should be_within 0.001, of: target.magnitude
      end
    end
  end

  describe "arithmetic operators" do
    describe "#+(other : self)" do
      [
        {1.kilobyte, 1.kilobyte, 2.kilobytes},
        {1.kilobyte, 1.kibibyte, 2_024.bytes},
        {1.megabyte, 1.mibibyte, 2_048_576.bytes},
      ].each do |a, b, sum|
        it "adds #{a} + #{b} == #{sum}" do
          (a + b).should eq sum
        end
      end

      it "returns the value with the first weight's unit" do
        (1.kibibyte + 1_024.bytes).unit.should eq Unit::Kibibyte
      end
    end

    describe "#-(other : self)" do
      [
        {2.kilobytes, 1.kilobyte, 1.kilobyte},
        {2_024.bytes, 1.kibibyte, 1.kilobyte},
        {2_048_576.bytes, 1.mibibyte, 1.megabyte},
      ].each do |a, b, difference|
        it "subtracts #{a} - #{b} == #{difference}" do
          (a - b).should eq difference
        end
      end

      it "returns the value with the first weight's unit" do
        (2.kibibytes - 1_024.bytes).unit.should eq Unit::Kibibyte
      end
    end

    describe "#*(scalar : Number)" do
      [
        {2.kilobytes, 3, 6.kilobytes},
        {1.kibibyte, 2, 2.kibibytes},
        {2.kilobytes, 0.5, 1.kilobyte},
      ].each do |weight, scalar, result|
        it "multiplies #{weight} by #{scalar} to get #{result}" do
          (weight * scalar).should eq result
        end
      end
    end

    describe "#/(scalar : Number)" do
      [
        {6.kilobytes, 3, 2.kilobytes},
        {1.kibibyte, 2, 0.5.kibibytes},
        {2.kilobytes, 2, 1_000.bytes},
      ].each do |weight, scalar, result|
        it "divides #{weight} by #{scalar} to get #{result}" do
          (weight / scalar).should eq result
        end
      end

      it "raises DivisionByZeroError when dividing by zero" do
        expect_raises(DivisionByZeroError) do
          1.kilobyte / 0
        end
      end
    end
  end

  describe "inequality operators" do
    describe "#==" do
      {
        [1.kibibyte, 1.024.kilobytes, 1_024.bytes],
        [1.mibibyte, 1_024.kibibytes, 1_048_576.bytes],
      }.each &.each_permutation 2 do |(a, b)|
        it "treats #{a} as equal to #{b}" do
          a.should eq b
        end
      end
    end

    describe "#<" do
      it "returns true if the data is less than the other" do
        1.kilobyte.should be < 1.kibibyte
        1.kilobyte.should be < 2.kilobytes
      end

      it "returns false if the data is not less than the other" do
        2.kilobyte.should_not be < 1.kibibyte
        2.kilobyte.should_not be < 1.kilobytes
      end
    end

    describe "#>" do
      it "returns true if the data is less than the other" do
        1.kibibyte.should be > 1.kilobyte
        2.kilobyte.should be > 1.kilobytes
      end

      it "returns false if the data is not less than the other" do
        1.kilobyte.should_not be > 1.kibibyte
        1.kilobyte.should_not be > 2.kilobytes
      end
    end

    describe "#<=" do
      it "returns true if the data is less than the other" do
        1.kilobyte.should be <= 1.kibibyte
        1.kilobyte.should be <= 2.kilobytes
        1.kilobyte.should be <= 1.kilobyte
      end

      it "returns false if the data is not less than the other" do
        2.kilobyte.should_not be <= 1.kibibyte
        2.kibibyte.should_not be <= 2.kilobytes
      end
    end

    describe "#>=" do
      it "returns true if the data is less than the other" do
        1.kibibyte.should be >= 1.kibibyte
        2.kilobytes.should be >= 1.kilobyte
        1.kilobyte.should be >= 1.kilobyte
      end

      it "returns false if the data is not less than the other" do
        1.kilobyte.should_not be >= 1.kibibyte
        1.kibibyte.should_not be >= 2.kilobytes
      end
    end
  end
end
