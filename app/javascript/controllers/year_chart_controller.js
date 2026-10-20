import { Controller } from "@hotwired/stimulus"

const COLORS = [ "#D98978", "#5B8A72", "#7C6A9A", "#3F6F8C", "#B45309", "#C9A56B" ]

export default class extends Controller {
  static values = { payload: Object }
  static targets = [ "svg", "legend" ]

  async connect() {
    const members = this.payloadValue.members || []
    const numbers = members.flatMap((member) => member.values.filter((value) => value != null))
    if (numbers.length === 0) return

    const d3 = await import("d3")
    const width = this.svgTarget.clientWidth || 320
    const height = 220
    const margin = { top: 16, right: 8, bottom: 16, left: 36 }
    const svg = d3.select(this.svgTarget)
    svg.selectAll("*").remove()
    svg.attr("viewBox", `0 0 ${width} ${height}`)
    const high = Math.max(...numbers)
    const span = high === 0 ? 0.1 : high * 0.08
    const x = d3.scaleLinear().domain([ 0, 51 ]).range([ margin.left, width - margin.right ])
    const y = d3.scaleLinear().domain([ 0, high + span ]).range([ margin.top, height - margin.bottom ])
    const line = d3.line()
      .defined((value) => value != null)
      .x((_value, index) => x(index))
      .y((value) => y(value))

    svg.append("g")
      .attr("transform", `translate(${margin.left},0)`)
      .call(d3.axisLeft(y).ticks(4).tickFormat((value) => value.toFixed(2)))
      .call((group) => group.selectAll("text").attr("font-size", 10))

    let colorIndex = 0
    members.forEach((member, index) => {
      const item = this.legendTargets[index]
      const hasValue = member.values.some((value) => value != null)
      if (!hasValue) {
        item?.querySelector("[data-swatch]")?.remove()
        return
      }

      const color = COLORS[colorIndex % COLORS.length]
      colorIndex += 1
      if (item) {
        item.style.color = color
        const swatch = item.querySelector("[data-swatch]")
        if (swatch) swatch.style.backgroundColor = color
      }
      svg.append("path")
        .attr("fill", "none")
        .attr("stroke", color)
        .attr("stroke-width", 2.5)
        .attr("d", line(member.values))
    })
  }
}
