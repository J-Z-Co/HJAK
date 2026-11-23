const app = getApp()
const api = require('../../utils/api')

Page({
  data: { loading: true, suggestions: [], body: '' },

  onLoad() { this.load() },

  async load() {
    try {
      await app.ensureLogin()
      const data = await api.getSuggestions()
      this.setData({ loading: false, suggestions: data.suggestions })
    } catch (e) {
      this.setData({ loading: false })
    }
  },

  onBody(e) { this.setData({ body: e.detail.value }) },

  async submit() {
    const body = this.data.body.trim()
    if (!body) return wx.showToast({ title: '写点内容', icon: 'none' })
    try {
      await api.createSuggestion(body)
      this.setData({ body: '' })
      this.load()
    } catch (e) {}
  },

  async vote(e) {
    const id = e.currentTarget.dataset.id
    const choice = e.currentTarget.dataset.choice
    try {
      await api.voteSuggestion(id, choice)
      this.load()
    } catch (e) {}
  }
})
