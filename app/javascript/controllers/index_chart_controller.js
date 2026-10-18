import { Controller } from "@hotwired/stimulus"

let d3

export default class extends Controller {
  static targets = [ "svg", "readout" ]
  static values = { payload: Object }

  async connect() {
    const payload = this.payloadValue
    if (!payload.points?.length) return
    d3 = await import("d3")

    const width = Math.max(this.element.clientWidth, 280)
    const height = payload.kind === "cardio" ? 300 : 220
    const svg = d3.select(this.svgTarget)
      .attr("viewBox", `0 0 ${width} ${height}`)
      .attr("preserveAspectRatio", "xMidYMid meet")
    const margin = { top: 16, right: 16, bottom: 28, left: 44 }

    if (payload.kind === "cardio") this.#cardio(svg, payload, width, height, margin)
    else this.#trend(svg, payload, width, height, margin)
    this.#bind(svg)
  }

  #trend(svg, payload, width, height, margin) {
    const points = payload.points.map((point) => ({ ...point, at: new Date(point.at) }))
    const x = this.#x(points, width, margin)
    const yValues = points.flatMap((point) => [ point.value, point.low_warn, point.low_health, point.high_health, point.high_warn ])
    const y = this.#y(yValues, height, margin)

    points.forEach((point, index) => {
      const x0 = index === 0 ? margin.left : x(points[index - 1].at)
      const x1 = x(point.at)
      this.#bands(svg, point, x0, x1, y)
    })
    const last = points[points.length - 1]
    this.#bands(svg, last, x(last.at), width - margin.right, y)
    if (payload.kind === "central") this.#guides(svg, last, margin.left, width - margin.right, y)

    this.#line(svg, points, x, y, (point) => point.value)
    this.#axis(svg, x, y, width, height, margin)
  }

  #cardio(svg, payload, width, height, margin) {
    const points = payload.points.map((point) => ({ ...point, at: new Date(point.at) }))
    const mid = Math.round(height * 0.58)
    const x = this.#x(points, width, margin)
    const pressure = this.#y(points.flatMap((point) => [ point.systolic, point.diastolic, 80, 120, 135, 85 ]), mid, margin)
    const pulseTop = mid + 16
    const pulse = this.#y(points.flatMap((point) => [ point.heart_rate, 50, 60, 100, 120 ]), height, { ...margin, top: pulseTop })

    points.forEach((point, index) => {
      const x0 = index === 0 ? margin.left : x(points[index - 1].at)
      const x1 = x(point.at)
      svg.append("rect")
        .attr("x", x0)
        .attr("width", Math.max(x1 - x0, 0))
        .attr("y", pressure(Math.max(point.systolic, point.diastolic)))
        .attr("height", Math.max(pressure(Math.min(point.systolic, point.diastolic)) - pressure(Math.max(point.systolic, point.diastolic)), 0))
        .attr("fill", "#EDE9FE")
        .attr("opacity", 0.9)
    })

    this.#line(svg, points, x, pressure, (point) => point.systolic)
    this.#line(svg, points, x, pressure, (point) => point.diastolic)
    this.#rule(svg, 120, margin.left, width - margin.right, pressure, "收缩压 120")
    this.#rule(svg, 80, margin.left, width - margin.right, pressure, "舒张压 80")
    this.#line(svg, points, x, pulse, (point) => point.heart_rate)
    this.#rule(svg, 60, margin.left, width - margin.right, pulse, "心率 60")
    this.#rule(svg, 100, margin.left, width - margin.right, pulse, "心率 100")
    this.#axis(svg, x, pressure, width, mid, margin)
    this.#axis(svg, x, pulse, width, height, { ...margin, top: pulseTop })
  }

  #x(points, width, margin) {
    const dates = points.map((point) => point.at)
    const start = dates.length === 1 ? d3.timeDay.offset(dates[0], -1) : d3.min(dates)
    const finish = dates.length === 1 ? d3.timeDay.offset(dates[0], 1) : d3.max(dates)
    return d3.scaleTime().domain([ start, finish ]).range([ margin.left, width - margin.right ])
  }

  #y(values, height, margin) {
    const finite = values.filter((value) => value != null && !Number.isNaN(Number(value))).map(Number)
    const lowest = Math.min(...finite)
    const highest = Math.max(...finite)
    const pad = lowest === highest ? 1 : (highest - lowest) * 0.15
    return d3.scaleLinear().domain([ lowest - pad, highest + pad ]).range([ height - margin.bottom, margin.top ])
  }

  #bands(svg, point, x0, x1, y) {
    if (point.high_health == null) return

    const domain = y.domain()
    const healthBottom = point.low_health == null ? domain[0] : point.low_health
    const strips = [ [ healthBottom, point.high_health, "#EDE9FE" ] ]
    if (point.low_warn != null && point.low_health != null) {
      strips.push([ domain[0], point.low_warn, "#FECACA" ], [ point.low_warn, point.low_health, "#FEF9C3" ])
    }
    if (point.high_warn != null) {
      strips.push([ point.high_health, point.high_warn, "#FEF9C3" ], [ point.high_warn, domain[1], "#FECACA" ])
    }
    strips.forEach(([ from, to, fill ]) => {
      const top = y(Math.max(from, to))
      const bottom = y(Math.min(from, to))
      svg.append("rect")
        .attr("x", x0)
        .attr("width", Math.max(x1 - x0, 0))
        .attr("y", top)
        .attr("height", Math.max(bottom - top, 0))
        .attr("fill", fill)
    })
  }

  #guides(svg, point, x0, x1, y) {
    if (point.high_health == null) return
    this.#rule(svg, point.high_health, x0, x1, y, "前期")
    this.#rule(svg, point.high_warn, x0, x1, y, "肥胖")
  }

  #rule(svg, value, x0, x1, y, label) {
    svg.append("line")
      .attr("x1", x0)
      .attr("x2", x1)
      .attr("y1", y(value))
      .attr("y2", y(value))
      .attr("stroke", "#78716c")
      .attr("stroke-dasharray", "4 3")
    svg.append("text")
      .attr("x", x1)
      .attr("y", y(value) - 4)
      .attr("text-anchor", "end")
      .attr("font-size", 11)
      .attr("fill", "#44403c")
      .text(label)
  }

  #line(svg, points, x, y, valueOf) {
    const line = d3.line().x((point) => x(point.at)).y((point) => y(valueOf(point)))
    svg.append("path").attr("d", line(points)).attr("fill", "none").attr("stroke", "#1c1917").attr("stroke-width", 2)
    const marks = svg.selectAll(null).data(points).enter().append("g").attr("class", "point")
    marks.attr("transform", (point) => `translate(${x(point.at)},${y(valueOf(point))})`)
    marks.append("circle").attr("r", 14).attr("fill", "transparent")
    marks.append("circle").attr("class", "dot").attr("r", 4).attr("fill", "#1c1917")
  }

  #bind(svg) {
    if (!this.hasReadoutTarget) return

    const marks = svg.selectAll("g.point")
    marks
      .style("cursor", "pointer")
      .on("click", (event, point) => {
        event.stopPropagation()
        const node = event.currentTarget
        const pinned = node.dataset.pinned === "1"
        this.#clearMarks(marks)
        if (pinned) {
          this.readoutTarget.textContent = this.readoutTarget.dataset.latest
          return
        }
        node.dataset.pinned = "1"
        d3.select(node).select("circle.dot").attr("r", 7)
        this.readoutTarget.textContent = point.label || point.text
      })
      .on("mouseenter", (_event, point) => {
        if (svg.node().querySelector("[data-pinned='1']")) return
        this.readoutTarget.textContent = point.label || point.text
      })
      .on("mouseleave", () => {
        if (svg.node().querySelector("[data-pinned='1']")) return
        this.readoutTarget.textContent = this.readoutTarget.dataset.latest
      })
    svg.on("click", () => {
      this.#clearMarks(marks)
      this.readoutTarget.textContent = this.readoutTarget.dataset.latest
    })
  }

  #clearMarks(marks) {
    marks.each(function () {
      delete this.dataset.pinned
      d3.select(this).select("circle.dot").attr("r", 4)
    })
  }

  #axis(svg, x, y, width, height, margin) {
    svg.append("g")
      .attr("transform", `translate(0,${height - margin.bottom})`)
      .call(d3.axisBottom(x).ticks(4).tickFormat(d3.timeFormat("%m/%d")))
      .call((group) => group.selectAll("text").attr("font-size", 11))
    svg.append("g")
      .attr("transform", `translate(${margin.left},0)`)
      .call(d3.axisLeft(y).ticks(4))
      .call((group) => group.selectAll("text").attr("font-size", 11))
  }
}
