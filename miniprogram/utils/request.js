// 请求基地址。
// 通过 wx.getAccountInfoSync().miniProgram.envVersion 自动区分环境，避免「上传时忘了改地址」：
//   develop        —— 开发者工具/预览：走本机后端 http://127.0.0.1:3000（开发期勾选「不校验合法域名」）
//   trial/release  —— 体验版/提交审核/正式版：走已备案的 https 域名
// 上线前把 PROD_BASE_URL 替换成你的真实域名（不带路径、结尾不带 /），与公众平台「request 合法域名」一致。
const PROD_BASE_URL = 'https://hjak.cn'
const DEV_BASE_URL = 'http://127.0.0.1:3000'

function resolveBaseUrl() {
  try {
    if (wx.getAccountInfoSync().miniProgram.envVersion === 'develop') {
      return DEV_BASE_URL
    }
  } catch (e) {
    // 取不到环境信息时按生产地址处理，保证线上可用
  }
  return PROD_BASE_URL
}

function request(path, options) {
  options = options || {}
  const app = getApp()
  const token = app.globalData.token || wx.getStorageSync('token')

  return new Promise((resolve, reject) => {
    wx.request({
      url: resolveBaseUrl() + path,
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
