const app = getApp()
const api = require('../../utils/api')

const BADGE_ICONS = { sparkles: '✨', fire: '🔥', trophy: '🏆', star: '⭐', clock: '⏰', chart_line: '📈' }

Page({
  data: { loading: true, user: null, progress: null, badges: [], avatar: '', warning: false, form: {} },

  onShow() {
    if (typeof this.getTabBar === 'function' && this.getTabBar()) this.getTabBar().setData({ selected: 3 })
    this.load()
  },

  async load() {
    try {
      await app.ensureLogin()
      const data = await api.getMe()
      const badges = data.progress.badges.map((b) => Object.assign({}, b, {
        icon: BADGE_ICONS[b.icon] || '🔒'
      }))
      const name = data.user.display_name || '我'
      this.setData({
        loading: false,
        user: data.user,
        progress: data.progress,
        badges: badges,
        avatar: name[0],
        warning: !data.user.sex || !data.user.birth_date,
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

  onName(e) { this.setData({ 'form.display_name': e.detail.value }) },
  onSex(e) { this.setData({ 'form.sex': e.detail.value }) },
  onBirth(e) { this.setData({ 'form.birth_date': e.detail.value }) },

  async save() {
    const f = this.data.form
    try {
      await api.updateMe({ display_name: f.display_name, sex: f.sex || null, birth_date: f.birth_date || null })
      wx.showToast({ title: '已保存' })
      this.load()
    } catch (e) {}
  },

  goSuggestions() { wx.navigateTo({ url: '/pages/suggestions/suggestions' }) },

  logout() {
    app.logout()
    wx.reLaunch({ url: '/pages/index/index' })
  }
})
