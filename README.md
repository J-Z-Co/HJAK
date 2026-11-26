# 梅珊知安 · 健康指数追踪

面向家庭的身体健康指标记录与追踪应用：记录体重、腰围、血压等 7 项指标，自动算出
BMI、体脂率、基础代谢率等 8 项健康指数，支持家人组群、排行榜、互相提醒。

- **技术栈**：Ruby on Rails 8.1 + PostgreSQL + Devise + Tailwind + Hotwire
- **前端形态**：传统网页（服务端渲染）＋ 微信小程序（JSON API 驱动）
- **部署**：Docker Compose 自托管（大陆 CVM + ICP 备案）

## 目录结构

```
app/                  Rails 网页应用（服务端渲染）
app/controllers/api/  小程序 JSON API（/api/v1）
app/services/         业务逻辑（指数计算、榜单、徽章等，均与前端无关）
miniprogram/          微信小程序前端（原生 JS + WXSS，7 个页面）
spec/                 测试（含 spec/requests/api/ 的 API 请求测试）
deploy/               Nginx 配置 + 证书目录（证书被 .gitignore 忽略）
docs/                 api-v1.md / deploy.md / dev-setup.md
```

## 快速开始（本地开发）

推荐 Docker Desktop：

```bash
docker compose up -d --build
docker compose exec web bin/rails db:prepare   # 仅首次
```

打开 `http://localhost:3000` 即为网页版。详见 [docs/dev-setup.md](docs/dev-setup.md)。

## 小程序

用微信开发者工具「导入项目」，目录选 `miniprogram/`。开发期把
`miniprogram/utils/request.js` 里的 `BASE_URL` 指向 `http://127.0.0.1:3000`，
并勾选「不校验合法域名」。

接口完整文档见 [docs/api-v1.md](docs/api-v1.md)。

## 测试

```bash
bundle exec rspec                    # 全部
bundle exec rspec spec/requests/api  # 只跑小程序 API 测试
```

## 部署到大陆服务器

需要：已 ICP 备案的域名 + 大陆云服务器（CVM）＋ HTTPS 证书。完整步骤见
[docs/deploy.md](docs/deploy.md)。
