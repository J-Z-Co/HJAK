const app = getApp()
const api = require('../../utils/api')

Page({
  data: { loading: true, key: '', reading: null, series: null, explanation: '' },

  onLoad(options) {
    const key = options.key || ''
    this.setData({ key: key })
    this.load(key)
  },

  async load(key) {
    try {
      await app.ensureLogin()
      const data = await api.getIndex(key, '7d')
      this.setData({
        loading: false,
        reading: data.reading,
        series: data.series,
        explanation: data.explanation
      })
    } catch (e) {
      this.setData({ loading: false })
    }
  }
})
