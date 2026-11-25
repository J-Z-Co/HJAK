const app = getApp()
const api = require('../../utils/api')
const theme = require('../../utils/theme')

function decorate(row) {
  const style = theme.METRIC_STYLES[row.key] || { color: "#78716c", bg: "#f5f5f4", icon: "•" }
  const pill = theme.STATUS_PILLS[row.status] || theme.STATUS_PILLS.never
  return Object.assign({}, row, {
    input_value: row.submitted_value || '',
    input_secondary: row.submitted_secondary || '',
    tileColor: style.color,
    tileBg: style.bg,
    icon: style.icon,
    pillText: pill.text,
    pillBg: pill.bg,
    pillColor: pill.color
  })
}

Page({
  data: { loading: true, shown: [], early: [], recorded_on: '', idempotency_key: '', progress: null, eyebrow: '', earlyOpen: false },

  onShow() {
    if (typeof this.getTabBar === 'function' && this.getTabBar()) this.getTabBar().setData({ selected: 0 })
    this.load()
  },

  async load() {
    try {
      await app.ensureLogin()
      const data = await api.getMeasurementsNew()
      const rows = data.rows.map(decorate)
      const shown = rows.filter((r) => ['due', 'overdue', 'never'].indexOf(r.status) >= 0)
      const early = rows.filter((r) => ['early', 'settled'].indexOf(r.status) >= 0)
      const d = new Date(data.recorded_on + 'T00:00:00')
      const weekdays = ['日', '一', '二', '三', '四', '五', '六']
      this.setData({
        loading: false,
        shown: shown,
        early: early,
        recorded_on: data.recorded_on,
        idempotency_key: data.idempotency_key,
        progress: data.progress,
        eyebrow: (d.getMonth() + 1) + '月 ' + d.getDate() + '日 · 星期' + weekdays[d.getDay()]
      })
    } catch (e) {
      this.setData({ loading: false })
    }
  },

  onDate(e) { this.setData({ recorded_on: e.detail.value }) },

  toggleEarly() { this.setData({ earlyOpen: !this.data.earlyOpen }) },

  onInput(e) {
    const list = e.currentTarget.dataset.list
    const index = e.currentTarget.dataset.index
    const field = e.currentTarget.dataset.field
    this.setData({ [list + '[' + index + '].' + field]: e.detail.value })
  },

  async submit() {
    const all = this.data.shown.concat(this.data.early)
    const measurements = {}
    all.forEach((row) => {
      if (row.blood_pressure) {
        if (row.input_value || row.input_secondary) {
          measurements[row.key] = { value: row.input_value, value_secondary: row.input_secondary }
        }
      } else if (row.input_value) {
        measurements[row.key] = { value: row.input_value }
      }
    })

    if (Object.keys(measurements).length === 0) {
      wx.showToast({ title: '还没有填写', icon: 'none' })
      return
    }

    try {
      await api.createMeasurements({
        recorded_on: this.data.recorded_on,
        idempotency_key: this.data.idempotency_key,
        measurements: measurements
      })
      wx.showToast({ title: '已保存' })
      this.load()
    } catch (e) {}
  }
})
