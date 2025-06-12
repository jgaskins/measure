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

## Precision

It's important to note that this shard stores the magnitude of the measurement as a `Float64`. This means it is limited to the precision 64-bit IEEE754 floating-point numbers.

### Why [`Float64`](https://crystal-lang.org/api/1.16.3/Float64.html) when [`BigDecimal`](https://crystal-lang.org/api/1.16.3/BigDecimal.html) is right there?

Measurements of nearly everything are less precise than we think they are. If you pull out a tape measure and measure something as being 10 feet long, that measurement is only as precise as your eyes, the placement of both ends of the tape, and the markings on the tape itself. It might be within 1/16th of an inch, but it's not going to be *exactly* 10 feet. Even objects measured and cut by machine are subject to the precision of that machine — they may be within 1/64th of an inch, but they won't be *exactly* 10 feet, either.

The point is that measurements just need to be close enough. `Float64` gets us close enough.

The [`spider-gazelle/crunits`](https://github.com/spider-gazelle/crunits) shard offers arbitrary precision for measurements. It's also a lot slower and doesn't offer the same compile-time guarantees that this shard does. But if you feel you need arbitrary precision, use `crunits`.

<details><summary>Comparison to <code>crunits</code></summary>

`crunits` is a Crystal port of the [Ruby `unitwise` gem](https://github.com/joshwlewis/unitwise).
The Ruby gem is _amazing_, to be clear, and the Crystal shard appears to support
similar levels of flexibility and extensibility.

The reason I chose not to use it and instead write `Measure` is that `Units`
handles measurements as `BigDecimal` for the magnitude and `String` for the unit
of measure. This has two primary drawbacks.

The first is that, if you use the wrong unit of measure (misspell it, for example), you can't find out until run time. So if you wrote `"hours"` instead of `"hour"`, you may not notice until that code is in production. This fits the Ruby perspective well enough, but `Measure` leans on the Crystal type system so you can detect these sorts of bugs much earlier. You can argue that you should see it work before deploying it, but let's be real, we've all screwed this up. We've YOLOed code to prod, written tests that didn't test what we thought we were testing and never saw them fail, etc. We're not perfect. If you haven't, let me know and I'll hire you.

The second is that using `BigDecimal` and `String` makes `crunits` very malleable (you don't have to patch the shard to add units, for example), but it's also significantly slower. `BigDecimal` allows arbitrary precision, but that precision has a performance cost. If you need this precision, use `crunits`. `String`s for units mean every instantiation, arithmetic operation, conversion, etc all involve string parsing. This adds a lot of overhead. On my machine, the benchmarks look like this:

```
Instantiation
crunits   4.84k (206.70µs) (± 1.50%)  908kB/op  245402.46× slower
measure   1.19G (  0.84ns) (± 1.33%)   0.0B/op            fastest

Arithmetic
crunits   1.44M (693.46ns) (± 0.58%)  1.93kB/op  359.61× slower
measure 518.57M (  1.93ns) (± 3.71%)    0.0B/op         fastest

Conversion
crunits  13.28k ( 75.30µs) (± 0.71%)  290kB/op  78776.24× slower
measure   1.05G (  0.96ns) (± 1.42%)   0.0B/op           fastest
```

For some of these, the monotonic clock is overcounting how long it takes to run the block for `Measure` because it doesn't have sufficient precision, so the real difference may be significantly larger. But even so, a factor of 360-245k is pretty huge. Relying on primitive 64-bit floats and enums makes `Measure` significantly faster.

Chances are, instantiating `Units::Measurement` instances won't be a bottleneck in your application, but it and the heap-memory usage (`Units::Measurement` allocates almost 1MB of heap per instance) are factors to consider.

</details>

## Contributing

1. Fork it (<https://github.com/jgaskins/measure/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Jamie Gaskins](https://github.com/jgaskins) - creator and maintainer
