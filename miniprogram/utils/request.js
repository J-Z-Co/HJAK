// 请求基地址。
// 开发期：启动 Rails 后填 http://127.0.0.1:3000，并在开发者工具里勾选「不校验合法域名」。
// 上线期：改成已备案的 https 域名（与公众平台「request 合法域名」一致）。
const BASE_URL = 'http://172.19.176.1:3000'

function request(path, options) {
  options = options || {}
  const app = getApp()
  const token = app.globalData.token || wx.getStorageSync('token')

  return new Promise((resolve, reject) => {
    wx.request({
      url: BASE_URL + path,
      method: options.method || 'GET',
      data: options.data || {},
      header: Object.assign(
        { 'Content-Type': 'application/json' },
        token ? { Authorization: 'Bearer ' + token } : {}
      ),
      success(res) {
        if (res.statusCode === 401) {
          // token 失效：静默重新登录后重试一次。
          app.globalData.token = ''
          app.login().then(() => {
            request(path, options).then(resolve, reject)
          }).catch(reject)
          return
        }
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(res.data)
        } else {
          const msg = (res.data && res.data.error) || ('请求失败(' + res.statusCode + ')')
          wx.showToast({ title: msg, icon: 'none' })
          reject(new Error(msg))
        }
      },
      fail(err) {
        wx.showToast({ title: '网络错误', icon: 'none' })
        reject(err)
      }
    })
  })
}

module.exports = {
  get: (path) => request(path, { method: 'GET' }),
  post: (path, data) => request(path, { method: 'POST', data }),
  patch: (path, data) => request(path, { method: 'PATCH', data }),
  del: (path) => request(path, { method: 'DELETE' })
}
