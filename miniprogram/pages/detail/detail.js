const app = getApp()
const api = require('../../utils/api')
const theme = require('../../utils/theme')

Page({
  data: {
    loading: true, key: '', reading: null, series: null, explanation: '',
    range: '7d',
    ranges: [['7d', '近 7 天'], ['30d', '近 1 个月'], ['365d', '近 1 年']],
    devColor: null, devWord: '', meterPct: null, showLegend: false
  },

  onLoad(options) {
    const key = options.key || ''
    this.setData({ key })
    this.load(key, '7d')
  },

  async load(key, range) {
    try {
      await app.ensureLogin()
      const data = await api.getIndex(key, range)
      const r = data.reading
      this.setData({
        loading: false,
        reading: r,
        series: data.series,
        explanation: data.explanation,
        range: range,
        devColor: theme.deviationColor(r.deviation),
        devWord: theme.deviationWord(r.deviation),
        meterPct: (r.deviation === null || r.deviation === undefined)
          ? null
          : (Math.max(0, Math.min(2, Number(r.deviation))) / 2 * 100).toFixed(1),
        showLegend: r.chart !== 'line'
      }, () => {
        setTimeout(() => this.drawChart(), 80)
      })
    } catch (e) {
      this.setData({ loading: false })
    }
  },

  switchRange(e) {
    this.load(this.data.key, e.currentTarget.dataset.range)
  },

  drawChart() {
    const points = (this.data.series && this.data.series.points) || []
    if (points.length === 0) return
    wx.createSelectorQuery().select('#chart').fields({ node: true, size: true }).exec((res) => {
      if (!res || !res[0] || !res[0].node) return
      const canvas = res[0].node
      const ctx = canvas.getContext('2d')
      const dpr = (wx.getSystemInfoSync().pixelRatio) || 1
      const w = res[0].width
      const h = res[0].height
      canvas.width = w * dpr
      canvas.height = h * dpr
      ctx.scale(dpr, dpr)
      const pad = 16
      const values = points.map((p) => p.value)
      const min = Math.min.apply(null, values)
      const max = Math.max.apply(null, values)
      const span = (max - min) || 1
      const X = (i) => points.length === 1 ? w / 2 : pad + (i / (points.length - 1)) * (w - 2 * pad)
      const Y = (v) => pad + (1 - (v - min) / span) * (h - 2 * pad)
      ctx.strokeStyle = '#4f46e5'
      ctx.lineWidth = 2
      ctx.lineCap = 'round'
      ctx.lineJoin = 'round'
      ctx.beginPath()
      points.forEach((p, i) => {
        if (i === 0) ctx.moveTo(X(i), Y(p.value))
        else ctx.lineTo(X(i), Y(p.value))
      })
      ctx.stroke()
      points.forEach((p, i) => {
        ctx.beginPath()
        ctx.arc(X(i), Y(p.value), 3, 0, 2 * Math.PI)
        ctx.fillStyle = '#4f46e5'
        ctx.fill()
      })
    })
  },

  back() { wx.navigateBack() }
})
