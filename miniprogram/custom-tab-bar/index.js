Component({
  data: {
    selected: 0,
    list: [
      { pagePath: '/pages/record/record', text: '记录', icon: '/images/tab-record.svg', color: '#7c3aed', bg: '#f5f3ff' },
      { pagePath: '/pages/index/index', text: '指数', icon: '/images/tab-indices.svg', color: '#4f46e5', bg: '#eef2ff' },
      { pagePath: '/pages/groups/groups', text: '群组', icon: '/images/tab-groups.svg', color: '#ea580c', bg: '#fff7ed' },
      { pagePath: '/pages/profile/profile', text: '我的', icon: '/images/tab-me.svg', color: '#059669', bg: '#ecfdf5' }
    ]
  },
  methods: {
    switchTab(e) {
      const path = e.currentTarget.dataset.path
      const index = Number(e.currentTarget.dataset.index)
      this.setData({ selected: index })
      wx.switchTab({ url: path })
    }
  }
})
