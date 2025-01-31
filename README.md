# Measure

This shard lets you measure, compare, and convert values in different units of measure.

For example, you can do things like:
- Compare a weight in ounces to one in grams
- Convert a length in miles to one in kilometers

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     measure:
       github: jgaskins/measure
   ```

2. Run `shards install`

## Usage

[API reference](https://jgaskins.dev/measure)

### Length

You measure lengths with `Measure::Length`. You can either instantiate it with the constructor or the shorthand methods on `Number`:

```crystal
require "measure/length"

# Both of these expressions are equivalent:
Measure::Length.new(50, :miles)
50.miles
```

You can also convert measurements to other units:

```crystal
50.miles.to(:km)
# => Measure::Length(@magnitude=80.46719742504969, @unit=Measure::Length::Unit::Kilometer)
10.miles.to(:feet)
# => Measure::Length(@magnitude=52800.0, @unit=Measure::Length::Unit::Foot)
1.foot.to(:cm)
# => Measure::Length(@magnitude=30.47999902464003, @unit=Measure::Length::Unit::Centimeter)
6.feet.to(:inches)
# => Measure::Length(@magnitude=72.0, @unit=Measure::Length::Unit::Inch)
```

The full list of length units are available [here](https://jgaskins.dev/measure/Measure/Length/Unit.html).

### Weight

Similar to `Measure::Length` for length/distance measurements, we measure weights with `Measure::Weight`:

```crystal
require "measure/weight"

# Both of these expressions are equivalent:
Measure::Weight.new(50, :pounds)
50.pounds
```

It also supports conversions:

```crystal
50000.grams.to(:pounds)
# => Measure::Weight(@magnitude=110.231, @unit=Measure::Weight::Unit::Pound)
50000.grams.to(:kilograms)
# => Measure::Weight(@magnitude=50.0, @unit=Measure::Weight::Unit::Kilogram)
50.grams.to(:ounces)
# => Measure::Weight(@magnitude=1.763696, @unit=Measure::Weight::Unit::Ounce)

```

## Contributing

1. Fork it (<https://github.com/jgaskins/measure/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Jamie Gaskins](https://github.com/jgaskins) - creator and maintainer
