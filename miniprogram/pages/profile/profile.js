const app = getApp()
const api = require('../../utils/api')

Page({
  data: {
    loading: true, user: null, progress: null, edit: false,
    form: { display_name: '', sex: '', birth_date: '' }
  },

  onShow() { this.load() },

  async load() {
    try {
      await app.ensureLogin()
      const data = await api.getMe()
      this.setData({
        loading: false,
        user: data.user,
        progress: data.progress,
        form: {
          display_name: data.user.display_name || '',
          sex: data.user.sex || '',
          birth_date: data.user.birth_date || ''
        }
      })
    } catch (e) {
      this.setData({ loading: false })
    }
  },

  toggleEdit() { this.setData({ edit: !this.data.edit }) },
  onName(e) { this.setData({ 'form.display_name': e.detail.value }) },
  onSex(e) { this.setData({ 'form.sex': e.detail.value }) },
  onBirth(e) { this.setData({ 'form.birth_date': e.detail.value }) },

  async save() {
    const f = this.data.form
    try {
      await api.updateMe({ display_name: f.display_name, sex: f.sex || null, birth_date: f.birth_date || null })
      wx.showToast({ title: '已保存' })
      this.setData({ edit: false })
      this.load()
    } catch (e) {}
  },

  logout() {
    app.logout()
    wx.reLaunch({ url: '/pages/index/index' })
  }
})
