const app = getApp()
const api = require('../../utils/api')
const theme = require('../../utils/theme')

function decorateReading(r) {
  const style = theme.INDEX_STYLES[r.key] || { color: "#78716c", bg: "#f5f5f4", icon: "•" }
  const color = theme.deviationColor(r.deviation)
  const meterPct = (r.deviation === null || r.deviation === undefined)
    ? null
    : (Math.max(0, Math.min(2, Number(r.deviation))) / 2 * 100).toFixed(1)
  return Object.assign({}, r, {
    tileColor: style.color,
    tileBg: style.bg,
    icon: style.icon,
    devColor: color,
    devWord: theme.deviationWord(r.deviation),
    meterPct: meterPct
  })
}

Page({
  data: { loading: true, board: null, brief: null, meanColor: null, meanWord: "", meanPct: null },

  onShow() {
    if (typeof this.getTabBar === 'function' && this.getTabBar()) this.getTabBar().setData({ selected: 1 })
    this.load()
  },

  async load() {
    try {
      await app.ensureLogin()
      const data = await api.getIndices()
      const board = data.board
      const brief = {
        lines: data.brief.lines,
        groups: data.brief.groups.map((g) => Object.assign({}, g, {
          readings: g.readings.map(decorateReading)
        }))
      }
      const mean = (board.mean === null || board.mean === undefined) ? null : Number(board.mean)
      this.setData({
        loading: false,
        board: board,
        brief: brief,
        meanColor: theme.deviationColor(mean),
        meanWord: theme.deviationWord(mean),
        meanPct: mean === null ? null : (Math.max(0, Math.min(2, mean)) / 2 * 100).toFixed(1)
      })
    } catch (e) {
      this.setData({ loading: false })
    }
  },

  onReadingTap(e) {
    const key = e.currentTarget.dataset.key
    const clickable = e.currentTarget.dataset.clickable === 'true'
    if (clickable) {
      wx.navigateTo({ url: '/pages/detail/detail?key=' + key })
    }
  },

})
