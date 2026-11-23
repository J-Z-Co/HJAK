const app = getApp()
const api = require('../../utils/api')

Page({
  data: {
    loading: true, public_id: '', group: null, boards: [], board: 'health', rows: []
  },

  onLoad(options) {
    this.setData({ public_id: options.public_id || '' })
    this.load()
  },

  async load() {
    try {
      await app.ensureLogin()
      const data = await api.getGroup(this.data.public_id, this.data.board)
      const rows = data.rows.map((r, i) => Object.assign({}, r, { _key: r.user ? r.user.id : i }))
      this.setData({ loading: false, group: data.group, boards: data.boards, board: data.board, rows: rows })
    } catch (e) {
      this.setData({ loading: false })
    }
  },

  switchBoard(e) {
    this.setData({ board: e.currentTarget.dataset.key })
    this.load()
  },

  async nudge(e) {
    try {
      await api.nudge(this.data.public_id, e.currentTarget.dataset.id)
      wx.showToast({ title: '已提醒' })
      this.load()
    } catch (e) {}
  },

  async leave() {
    const res = await new Promise((resolve) => {
      wx.showModal({ title: '退出群组', content: '确定退出这个群组吗？', success: resolve })
    })
    if (!res.confirm) return
    try {
      await api.leaveGroup(this.data.public_id)
      wx.navigateBack()
    } catch (e) {}
  }
})
