const app = getApp()
const api = require('../../utils/api')

Page({
  data: { loading: true, groups: [], mode: null, name: '', code: '' },

  onShow() {
    if (typeof this.getTabBar === 'function' && this.getTabBar()) this.getTabBar().setData({ selected: 2 })
    this.load()
  },

  async load() {
    try {
      await app.ensureLogin()
      const data = await api.getGroups()
      const groups = data.groups.map((g) => Object.assign({}, g, { initial: (g.name || '群')[0] }))
      this.setData({ loading: false, groups: groups })
    } catch (e) {
      this.setData({ loading: false })
    }
  },

  setMode(e) { this.setData({ mode: e.currentTarget.dataset.mode }) },

  onName(e) { this.setData({ name: e.detail.value }) },
  onCode(e) { this.setData({ code: e.detail.value }) },

  async create() {
    const name = this.data.name.trim()
    if (!name) return wx.showToast({ title: '填一下群名', icon: 'none' })
    try {
      await api.createGroup(name)
      this.setData({ name: '', mode: null })
      this.load()
    } catch (e) {}
  },

  async join() {
    const code = this.data.code.trim()
    if (!code) return wx.showToast({ title: '填一下代号', icon: 'none' })
    try {
      await api.joinGroup(code)
      this.setData({ code: '', mode: null })
      this.load()
    } catch (e) {}
  },

  open(e) {
    wx.navigateTo({ url: '/pages/group/group?public_id=' + e.currentTarget.dataset.id })
  }
})
