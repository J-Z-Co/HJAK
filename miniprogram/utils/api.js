const http = require('./request')

module.exports = {
  // 鉴权
  login: (code) => http.post('/api/v1/auth/wechat', { code }),
  getMe: () => http.get('/api/v1/me'),
  updateMe: (data) => http.patch('/api/v1/me', data),

  // 记录
  getMeasurementsNew: () => http.get('/api/v1/measurements/new'),
  createMeasurements: (data) => http.post('/api/v1/measurements', data),
  deleteMeasurement: (id) => http.del('/api/v1/measurements/' + id),

  // 指数
  getIndices: () => http.get('/api/v1/indices'),
  getIndex: (key, range) => http.get('/api/v1/indices/' + key + '?range=' + (range || '7d')),

  // 群组
  getGroups: () => http.get('/api/v1/groups'),
  createGroup: (name) => http.post('/api/v1/groups', { name }),
  joinGroup: (code) => http.post('/api/v1/groups/join', { code }),
  getGroup: (publicId, board) => http.get('/api/v1/groups/' + publicId + '?board=' + (board || 'health')),
  getGroupYear: (publicId) => http.get('/api/v1/groups/' + publicId + '/year'),
  nudge: (publicId, subjectId) => http.post('/api/v1/groups/' + publicId + '/nudge', { subject_id: subjectId }),
  leaveGroup: (publicId) => http.del('/api/v1/groups/' + publicId + '/membership'),

  // 建议
  getSuggestions: () => http.get('/api/v1/suggestions'),
  createSuggestion: (body) => http.post('/api/v1/suggestions', { body }),
  voteSuggestion: (id, choice) => http.post('/api/v1/suggestions/' + id + '/vote', { choice })
}
