module MeasurementsHelper
  def sparkline_tag(row)
    points = row.history
    return if points.empty?

    primary = points.map { |item| item.value.to_f }
    secondary = points.map { |item| item.value_secondary&.to_f }
    paired = secondary.any?
    samples = paired ? primary + secondary.compact : primary
    low, high = samples.minmax
    left = 18.0
    right = 98.0
    top = 3.5
    bottom = 20.0
    xs = sparkline_xs(points.size, left, right)
    y_of = sparkline_y(low, high, top, bottom)
    high_text, low_text = sparkline_bounds(low, high)
    with_year = points.first.recorded_on.year != points.last.recorded_on.year
    start_label = sparkline_day(points.first.recorded_on, with_year)
    end_label = sparkline_day(points.last.recorded_on, with_year)

    tag.svg(
      viewBox: "0 0 100 29",
      class: "mt-2 block h-auto w-full",
      role: "img",
      aria: { label: "最近 #{points.size} 次#{row.entry.label}，#{low_text} 到 #{high_text}" },
      style: "font-family: ui-sans-serif, system-ui, sans-serif"
    ) do
      safe_join([
        tag.line(x1: left, y1: top, x2: left, y2: bottom, stroke: "#a8a29e", "stroke-width": "0.45"),
        tag.line(x1: left, y1: bottom, x2: right, y2: bottom, stroke: "#a8a29e", "stroke-width": "0.45"),
        sparkline_mark(xs, primary.map { |value| y_of.call(value) }, "#44403c"),
        (sparkline_mark(xs, secondary.map { |value| value && y_of.call(value) }, "#a8a29e") if paired),
        sparkline_text(high_text, left - 1.2, top + 2.4, "end"),
        (sparkline_text(low_text, left - 1.2, bottom, "end") if high_text != low_text),
        sparkline_text(start_label, left, 27, "start"),
        (sparkline_text(end_label, right, 27, "end") if end_label != start_label)
      ].compact)
    end
  end

  private

  def sparkline_xs(count, left, right)
    return [ (left + right) / 2 ] if count == 1

    count.times.map { |index| left + index * (right - left) / (count - 1) }
  end

  def sparkline_y(low, high, top, bottom)
    return ->(_value) { (top + bottom) / 2 } if high == low

    span = high - low
    ->(value) { bottom - ((value - low) / span * (bottom - top)) }
  end

  def sparkline_bounds(low, high)
    precise = (high - low).abs < 1 || [ low, high ].any? { |value| (value - value.round).abs > 0.05 }
    high_text = sparkline_tick(high, precise)
    low_text = sparkline_tick(low, precise)
    if high_text == low_text && high != low
      high_text = format("%.1f", high)
      low_text = format("%.1f", low)
    end
    [ high_text, low_text ]
  end

  def sparkline_tick(value, precise)
    text = precise ? format("%.1f", value) : format("%.0f", value)
    text.sub(/\.0\z/, "")
  end

  def sparkline_day(date, with_year)
    prefix = with_year ? "#{date.year % 100}/" : ""
    "#{prefix}#{date.month}/#{date.day}"
  end

  def sparkline_text(content, x_pos, y_pos, anchor)
    tag.text(
      content,
      x: format("%.1f", x_pos),
      y: format("%.1f", y_pos),
      "text-anchor": anchor,
      "font-size": "3.4",
      fill: "#44403c"
    )
  end

  def sparkline_mark(xs, ys, stroke)
    usable = xs.zip(ys).select { |_x, y| y }
    return if usable.empty?

    if usable.size == 1
      tag.circle(cx: format("%.2f", usable[0][0]), cy: format("%.2f", usable[0][1]), r: "1.3", fill: stroke)
    else
      pairs = usable.map { |x_pos, y_pos| "#{format('%.2f', x_pos)},#{format('%.2f', y_pos)}" }.join(" ")
      tag.polyline(
        points: pairs,
        fill: "none",
        stroke: stroke,
        "stroke-width": "1.2",
        "stroke-linejoin": "round",
        "stroke-linecap": "round"
      )
    end
  end
end
