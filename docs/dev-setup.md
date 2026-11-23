# 本地开发环境搭建

小程序是「前端」，Rails 是「后端」。跑起来需要两样东西同时在场：

1. **Rails 后端**跑在 `localhost:3000`；
2. **微信开发者工具**打开 `miniprogram/` 目录，去调 `localhost:3000`。

两者都在 Windows 上完成，代码只保留一份（本仓库）。下面两种方式二选一。

---

## 方式 A：Docker Desktop（推荐，最省事）

Docker Desktop 会自动装好 WSL2 后端，代码留在 Windows 副本即可，不用来回同步。

```powershell
# 1) 安装 Docker Desktop for Windows，重启后等任务栏鲸鱼图标变绿

# 2) 起服务（仓库根目录）
cd D:\deepseek\hbyang\周的工作\HJAK-inspect
docker compose up -d --build
docker compose exec web bin/rails db:prepare     # 仅首次

# 3) 验证：浏览器打开 http://localhost:3000/up 应返回 200
```

微信登录凭据（注册小程序后填）：在根目录建 `.env`：

```env
WECHAT_APPID=wx你的AppID
WECHAT_SECRET=你的AppSecret
```

填完重启：`docker compose up -d`。

---

## 方式 B：纯 WSL2（不用 Docker）

适合不想装 Docker 的情况。注意：这条路需要先把代码推到 GitHub，再从 WSL 里 clone（因为我在 Windows 副本里改的文件需要先进入版本库）。

### 1. 装 WSL2

在 PowerShell（管理员）运行：

```powershell
wsl --install -d Ubuntu
```

重启后打开 Ubuntu。

### 2. 装 Ruby 3.4（rbenv）

```bash
sudo apt update && sudo apt install -y git curl libssl-dev libreadline-dev zlib1g-dev \
  autoconf bison build-essential libyaml-dev libncurses5-dev libffi-dev libgdbm-dev \
  libpq-dev nodejs

git clone https://github.com/rbenv/rbenv.git ~/.rbenv
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'eval "$(~/.rbenv/bin/rbenv init - bash)"' >> ~/.bashrc
exec $SHELL
rbenv install 3.4.10
rbenv global 3.4.10
gem install bundler
```

### 3. 装并启动 PostgreSQL

```bash
sudo apt install -y postgresql postgresql-contrib
sudo service postgresql start
sudo -u postgres createuser -s "$USER"
```

### 4. 拉代码并启动

```bash
cd ~
git clone https://github.com/J-Z-Co/HJAK.git hjax
cd hjax
bundle install
bin/rails db:prepare
bin/dev          # 或 bin/rails server
```

WSL2 默认会把 `localhost` 转发到 Windows，所以 Windows 上的开发者工具能直接访问 `localhost:3000`。

---

## 打开小程序（两种方式都适用）

1. 微信开发者工具 → 「导入项目」→ 目录选 `miniprogram/` → AppID 填你的真实 AppID。
2. 把 `miniprogram/utils/request.js` 里的 `BASE_URL` 改成 `http://127.0.0.1:3000`。
3. 开发者工具「详情 → 本地设置」勾选「不校验合法域名」。
4. 编译 → 预览。

> 微信一键登录需要**真实注册的小程序 AppID + AppSecret**（个人注册免费）。只有 `touristappid` 时，登录接口会报「missing WeChat appid」。

---

## 常见问题

| 现象 | 处理 |
|---|---|
| `docker compose up` 报权限错误 | 代码在 Windows 盘（D:\）上，Docker Desktop 需在设置里允许该盘的文件共享 |
| `docker compose up` 报路径/挂载/文件错误 | 项目路径含中文（`周的工作`），部分 Docker 版本对非 ASCII 路径支持不佳，把项目复制到纯英文路径（如 `D:\dev\hjax`）再试 |
| `db:prepare` 连不上数据库 | 确认 `db` 容器已 healthy（`docker compose ps`），再重跑 |
| 开发者工具报「不在合法域名」 | 勾选「不校验合法域名」，或确认 BASE_URL 与后端一致 |
| 登录返回 `missing WeChat appid` | 没填 `.env` 里的 WECHAT_APPID/WECHAT_SECRET，或没重启 web 容器 |
| `bundle install` 慢/失败 | 换国内镜像：`bundle config mirror.https://rubygems.org https://mirrors.tuna.tsinghua.edu.cn/rubygems` |
| 镜像下载极慢（postgres/ruby 拉几小时） | 国内直连 Docker Hub 慢：Docker Desktop → Settings → Docker Engine，加 `"registry-mirrors"`（用阿里云镜像加速器的专属地址，或当前可用的公共加速器），Apply & Restart 后重拉 |
