# 大陆服务器部署指南（自托管）

本指南把 HJAK 从 Vercel 迁到大陆云服务器（腾讯云/阿里云 CVM），用 `docker compose` 跑
Postgres + Rails/Puma + Nginx，供网页和微信小程序共用。

## 0. 为什么要迁

微信小程序后台的「request 合法域名」强制要求：**已 ICP 备案的域名 + HTTPS**。Vercel 在
海外，无法备案，因此后端必须迁到大陆服务器。

## 0.5 备案前：用公网 IP 在服务器上快速试跑（可选）

想在备案通过前就在服务器上调试，可跳过域名，直接用「公网 IP + 端口」访问（仅调试，发布仍走下方正式流程）。

1. SSH 登录 CVM（腾讯云控制台「登录」按钮，或本地 SSH）。
2. 装 Docker（装完建议配腾讯云内网镜像加速 `mirror.ccs.tencentyun.com`）：

   ```bash
   curl -fsSL https://get.docker.com | sh
   sudo systemctl enable --now docker
   ```

3. 拉代码：

   ```bash
   git clone https://github.com/J-Z-Co/HJAK.git
   cd HJAK
   ```

4. 建 `.env`（填 `WECHAT_APPID` / `WECHAT_SECRET`）：

   ```bash
   cp .env.example .env && vi .env
   ```

5. 起开发服务：

   ```bash
   docker compose up -d --build
   docker compose exec web bin/rails db:prepare
   ```

6. 腾讯云「安全组」放行 **3000** 端口（入站 TCP 3000，来源 0.0.0.0/0）。
7. 浏览器访问 `http://<公网IP>:3000/up` 应返回 200。

小程序端把 `BASE_URL` 改成 `http://<公网IP>:3000`，开发者工具勾「不校验合法域名」。

> 备案期间 80/443 通常被封，但 3000 等自定义端口一般不受影响。这只是调试环境，正式发布仍用下方「域名 + HTTPS」流程。

## 1. 买域名 + 云服务器 + 备案（一次性，约 1–3 周）

1. 在**腾讯云或阿里云**买域名，完成**域名实名认证**（个人用身份证）。
2. 买一台大陆节点的**云服务器 CVM**（包年包月 ≥ 3 个月，这是备案前提）。Ubuntu 22.04/24.04 均可。
3. 在云厂商控制台进入「**ICP 备案**」，按提示提交主体（个人）与网站信息、身份证、人脸核验。
4. 接入商初审（1–2 工作日）→ 通信管理局审核（各省 1–20 工作日不等）→ 拿到 **ICP 备案号**。

> 备案期间大陆服务器的 80/443 端口通常被云厂商封禁，**属于正常现象**，备案通过后自动解封。

## 2. 解析域名 + 申请 HTTPS 证书

1. 备案通过后，在云厂商控制台给域名加一条 **A 记录**，指向 CVM 的公网 IP。
2. 在云厂商控制台申请**免费 DV 证书**（腾讯云/阿里云每年送若干张），绑定你的域名。
3. 下载 **nginx 格式**的证书，得到两个文件：
   - `fullchain.pem`（证书链）—— 放到本仓库 `deploy/certs/fullchain.pem`
   - `privkey.pem`（私钥）—— 放到本仓库 `deploy/certs/privkey.pem`

## 3. 配置服务器环境

SSH 登录 CVM，安装 Docker 与 Compose 插件：

```bash
curl -fsSL https://get.docker.com | sh
sudo systemctl enable --now docker
```

## 4. 部署

把代码传到服务器（`git clone` 你的仓库，或 `rsync`），然后在项目根目录建 `.env`：

```bash
cp deploy/env.example .env
# 编辑 .env，填入 POSTGRES_PASSWORD / RAILS_MASTER_KEY / APP_HOST
```

`.env` 三项说明：

| 变量 | 说明 |
|---|---|
| `POSTGRES_PASSWORD` | 数据库密码，自己生成一个强随机值 |
| `RAILS_MASTER_KEY` | 你本地 `config/master.key` 的内容（解密 `credentials.yml.enc` 用） |
| `APP_HOST` | 你的备案域名，如 `api.yourdomain.com` |

然后启动：

```bash
docker compose -f docker-compose.prod.yml up -d --build
docker compose -f docker-compose.prod.yml logs -f web   # 看启动日志
```

启动成功后可自检（在服务器上）：

```bash
curl -k https://localhost/up          # 应返回 200（health check 不走强制跳转）
curl https://你的域名/up               # 应返回 200
curl -X POST https://你的域名/api/v1/auth/wechat \
  -H 'Content-Type: application/json' \
  -d '{"code":"在开发者工具里 wx.login 拿到的 code"}'
```

## 5. 微信公众平台配置

1. 登录 [微信公众平台](https://mp.weixin.qq.com) → 开发管理 → 开发设置 → **服务器域名**。
2. 在 `request 合法域名` 里填入 `https://你的域名`（只填域名，不带路径、不带端口）。
3. 保存后，小程序端 `wx.request` 就能访问你的 API 了。

## 6. 日常运维

```bash
# 更新代码后
git pull
docker compose -f docker-compose.prod.yml up -d --build

# 查看日志 / 进入 Rails 控制台
docker compose -f docker-compose.prod.yml logs -f web
docker compose -f docker-compose.prod.yml exec web bin/rails console

# 备份数据库
docker compose -f docker-compose.prod.yml exec db pg_dump -U phoenix_list phoenix_list_production > backup.sql
```

## 7. 可选加固

- 在 `config/environments/production.rb` 里取消 `config.hosts` 的注释，只允许你的域名。
- Nginx 的 `server_name` 从 `_` 改成你的正式域名。
- 云厂商安全组只开放 22 / 80 / 443，3000 端口不要对公网开放（compose 里已绑到 127.0.0.1）。
