const app = getApp()
const api = require('../../utils/api')

Page({
  data: { loading: true, rows: [], recorded_on: '', idempotency_key: '' },

  onLoad() { this.load() },

  async load() {
    try {
      await app.ensureLogin()
      const data = await api.getMeasurementsNew()
      const rows = data.rows.map((r) => Object.assign({}, r, { input_value: '', input_secondary: '' }))
      this.setData({
        loading: false,
        rows: rows,
        recorded_on: data.recorded_on,
        idempotency_key: data.idempotency_key
      })
    } catch (e) {
      this.setData({ loading: false })
    }
  },

  onInput(e) {
    const index = e.currentTarget.dataset.index
    const field = e.currentTarget.dataset.field
    this.setData({ ['rows[' + index + '].' + field]: e.detail.value })
  },

  async submit() {
    const measurements = {}
    this.data.rows.forEach((row) => {
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
      setTimeout(() => wx.navigateBack(), 600)
    } catch (e) {}
  }
})
