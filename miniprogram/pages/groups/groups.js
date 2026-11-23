const app = getApp()
const api = require('../../utils/api')

Page({
  data: { loading: true, groups: [], newName: '', joinCode: '' },

  onShow() { this.load() },

  async load() {
    try {
      await app.ensureLogin()
      const data = await api.getGroups()
      this.setData({ loading: false, groups: data.groups })
    } catch (e) {
      this.setData({ loading: false })
    }
  },

  onName(e) { this.setData({ newName: e.detail.value }) },
  onCode(e) { this.setData({ joinCode: e.detail.value }) },

  open(e) {
    wx.navigateTo({ url: '/pages/group/group?public_id=' + e.currentTarget.dataset.id })
  },

  async create() {
    const name = this.data.newName.trim()
    if (!name) return wx.showToast({ title: '填一下群名', icon: 'none' })
    try {
      await api.createGroup(name)
      this.setData({ newName: '' })
      this.load()
    } catch (e) {}
  },

  async join() {
    const code = this.data.joinCode.trim()
    if (!code) return wx.showToast({ title: '填一下代号', icon: 'none' })
    try {
      await api.joinGroup(code)
      this.setData({ joinCode: '' })
      this.load()
    } catch (e) {}
  }
})
