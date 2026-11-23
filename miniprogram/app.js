const api = require('./utils/api')

App({
  globalData: {
    token: '',
    user: null
  },

  onLaunch() {
    const token = wx.getStorageSync('token')
    if (token) this.globalData.token = token
  },

  // 确保已登录（wx.login 是静默的，无需用户授权）。返回 Promise<token>
  ensureLogin() {
    if (this.globalData.token) return Promise.resolve(this.globalData.token)
    return this.login()
  },

  login() {
    return new Promise((resolve, reject) => {
      wx.login({
        success: (res) => {
          if (!res.code) return reject(new Error('wx.login 未返回 code'))
          api.login(res.code).then((data) => {
            this.globalData.token = data.token
            this.globalData.user = data.user
            wx.setStorageSync('token', data.token)
            resolve(data.token)
          }).catch(reject)
        },
        fail: reject
      })
    })
  },

  logout() {
    this.globalData.token = ''
    this.globalData.user = null
    wx.removeStorageSync('token')
  }
})
