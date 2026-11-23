const app = getApp()
const api = require('../../utils/api')

Page({
  data: { loading: true, brief: null, readings: [] },

  onShow() { this.load() },

  async load() {
    try {
      await app.ensureLogin()
      const data = await api.getIndices()
      this.setData({ loading: false, brief: data.brief, readings: data.board.readings })
    } catch (e) {
      this.setData({ loading: false })
    }
  },

  goDetail(e) {
    wx.navigateTo({ url: '/pages/detail/detail?key=' + e.currentTarget.dataset.key })
  },

  goRecord() {
    wx.navigateTo({ url: '/pages/record/record' })
  }
})
