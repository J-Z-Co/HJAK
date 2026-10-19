module ThemeHelper
  # 每个分页一种主色。类名写全，Tailwind 才扫得到
  TAB_THEMES = {
    record: { hero: "from-violet-600 via-fuchsia-500 to-pink-500", pill: "bg-violet-100 text-violet-700", accent: "text-violet-600" },
    indices: { hero: "from-indigo-600 via-blue-500 to-cyan-400", pill: "bg-blue-100 text-blue-700", accent: "text-blue-600" },
    groups: { hero: "from-rose-500 via-orange-500 to-amber-400", pill: "bg-orange-100 text-orange-700", accent: "text-orange-600" },
    me: { hero: "from-emerald-600 via-teal-500 to-cyan-500", pill: "bg-emerald-100 text-emerald-700", accent: "text-emerald-600" }
  }.freeze

  METRIC_STYLES = {
    "weight" => [ :scales, "bg-violet-100 text-violet-600" ],
    "height" => [ :body_height, "bg-sky-100 text-sky-600" ],
    "waist" => [ :body_waist, "bg-amber-100 text-amber-600" ],
    "hip" => [ :body_hip, "bg-rose-100 text-rose-600" ],
    "neck" => [ :body_neck, "bg-teal-100 text-teal-600" ],
    "blood_pressure" => [ :gauge, "bg-red-100 text-red-600" ],
    "resting_heart_rate" => [ :heartbeat, "bg-pink-100 text-pink-600" ]
  }.freeze

  INDEX_STYLES = {
    "bmi" => [ :scales, "bg-violet-100 text-violet-600" ],
    "bmr" => [ :flame, "bg-orange-100 text-orange-600" ],
    "navy" => [ :drop_half, "bg-sky-100 text-sky-600" ],
    "rfm" => [ :drop_half, "bg-cyan-100 text-cyan-600" ],
    "whtr" => [ :body_waist, "bg-amber-100 text-amber-600" ],
    "whr" => [ :body_hip, "bg-rose-100 text-rose-600" ],
    "central_obesity" => [ :body_waist, "bg-yellow-100 text-yellow-700" ],
    "cardio" => [ :heartbeat, "bg-red-100 text-red-600" ]
  }.freeze

  # 记录页四档时效：药丸用的颜色与文字
  STATUS_PILLS = {
    due: [ "bg-green-500 text-white", "该测了" ],
    overdue: [ "bg-amber-400 text-amber-950", "已逾期" ],
    early: [ "bg-violet-100 text-violet-700", "未到下次" ],
    never: [ "bg-stone-200 text-stone-600", "未点亮" ]
  }.freeze

  # 页顶横幅。总是用 render layout:，partial 里的 yield 才只拿到这里的块
  def hero(title:, **options, &block)
    render(layout: "shared/hero", locals: { title:, **options }) { block ? capture(&block) : "" }
  end

  def theme
    TAB_THEMES.fetch(current_tab || :record)
  end

  def icon_tile(name, classes, size: "size-11")
    glyph = BodyIconsHelper::BODY_ICONS.key?(name) ? body_icon(name, size: "size-[62%]") : icon(name, size: "size-[55%]", stroke: 1.8)
    tag.span(glyph, class: "inline-flex #{size} shrink-0 items-center justify-center rounded-2xl #{classes}")
  end

  def metric_tile(key, size: "size-11")
    name, classes = METRIC_STYLES.fetch(key, [ :sparkles, "bg-stone-100 text-stone-600" ])
    icon_tile(name, classes, size:)
  end

  def index_tile(key, size: "size-11")
    name, classes = INDEX_STYLES.fetch(key, [ :sparkles, "bg-stone-100 text-stone-600" ])
    icon_tile(name, classes, size:)
  end

  def status_pill(status)
    classes, text = STATUS_PILLS.fetch(status)
    tag.span(text, class: "inline-flex shrink-0 items-center rounded-full px-2.5 py-0.5 text-xs font-semibold #{classes}")
  end

  # 偏离分 0 在健康区，(0, 1) 亚健康，1 起警告
  def deviation_word(deviation)
    return if deviation.nil?

    if deviation <= 0 then "健康区"
    elsif deviation < 1 then "需留意"
    else "警告"
    end
  end

  def deviation_pill(deviation)
    word = deviation_word(deviation)
    return unless word

    tag.span(word, class: "inline-flex shrink-0 items-center rounded-full px-2.5 py-0.5 text-xs font-semibold text-white", style: "background-color: #{::Indices::Palette.css(deviation)}")
  end

  # 偏离刻度条：0 到 2，底色用偏离色的渐变，圆点落在当前偏离分上
  def deviation_meter(deviation, track: nil, css: nil)
    stops = ::Indices::Palette::STOPS.map { |at, rgb| "rgb(#{rgb.join(",")}) #{(at / 2.0 * 100).round}%" }.join(", ")
    percent = (deviation.to_f.clamp(0, 2) / 2.0 * 100).round(1)
    tag.div(class: "relative h-2.5 #{css}", aria: { hidden: true }) do
      safe_join([
        tag.div(class: "absolute inset-x-0 top-1/2 h-1.5 -translate-y-1/2 rounded-full opacity-35 #{track}", style: ("background: linear-gradient(90deg, #{stops})" unless track)),
        tag.div(class: "absolute left-0 top-1/2 h-1.5 -translate-y-1/2 rounded-full", style: "width: #{percent}%; background: linear-gradient(90deg, #{stops}); background-size: #{percent.zero? ? 100 : (10000 / percent).round(1)}% 100%"),
        tag.div(class: "absolute top-1/2 size-3.5 -translate-x-1/2 -translate-y-1/2 rounded-full border-2 border-white shadow", style: "left: clamp(7px, #{percent}%, calc(100% - 7px)); background-color: #{::Indices::Palette.css(deviation)}")
      ])
    end
  end

  # 进度环：done / total，画成 SVG 圆环
  def progress_ring(done, total, size: 64, stroke: 7, track: "rgba(255,255,255,0.25)", color: "#fff")
    radius = (size - stroke) / 2.0
    circumference = 2 * Math::PI * radius
    ratio = total.zero? ? 1.0 : (done.to_f / total).clamp(0, 1)
    tag.svg(viewBox: "0 0 #{size} #{size}", width: size, height: size, class: "-rotate-90", aria: { hidden: true }) do
      safe_join([
        tag.circle(cx: size / 2.0, cy: size / 2.0, r: radius, fill: "none", stroke: track, "stroke-width": stroke),
        tag.circle(cx: size / 2.0, cy: size / 2.0, r: radius, fill: "none", stroke: color, "stroke-width": stroke,
                   "stroke-linecap": "round", "stroke-dasharray": format("%.2f", circumference),
                   "stroke-dashoffset": format("%.2f", circumference * (1 - ratio)))
      ])
    end
  end
end
