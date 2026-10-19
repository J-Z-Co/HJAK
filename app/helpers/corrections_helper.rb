module CorrectionsHelper
  def correction_value(measurement)
    if measurement.metric_type == "blood_pressure"
      "#{plain_number(measurement.value)}/#{plain_number(measurement.value_secondary)}"
    else
      plain_number(measurement.value)
    end
  end

  def plain_number(number)
    return "" if number.nil?

    number.to_s("F").sub(/\.0+\z/, "").sub(/(\.\d*?)0+\z/, "\\1")
  end

  def correction_date(measurement)
    date = measurement.recorded_on
    year = date.year == Time.zone.today.year ? "" : "#{date.year} 年 "
    "#{year}#{date.month} 月 #{date.day} 日"
  end
end
