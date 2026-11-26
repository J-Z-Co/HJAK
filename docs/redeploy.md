# 重新部署标准流程（腾讯云轻量服务器）

> 目标：区分「只需重启」和「需要重建镜像」，并及时清理无用的镜像/容器，节省存储与算力。
> 本流程针对生产文件 `docker-compose.prod.yml`。

## 一、先判断：这次改动属于哪一类？

登录服务器后，先看这次拉下来改了什么：

```bash
cd ~/HJAK
git pull
git log --oneline -5          # 最近提交
git diff HEAD~1 --stat        # 最近一次改动涉及哪些文件
```

再对照下表选择操作：

| 改动内容 | 是否重建镜像 | 操作 |
|---|---|---|
| Rails 应用代码（`app/`、`config/`、`db/`、`lib/`、`bin/` 等） | ✅ 需要 | 见「A」 |
| `Gemfile` / `Gemfile.lock` / `Dockerfile.prod` | ✅ 需要（较慢，会重跑 bundle install） | 见「A」 |
| `deploy/nginx.conf` | ❌ 不需要 | 见「B」 |
| `deploy/certs/` 证书 | ❌ 不需要 | 见「B」 |
| 根目录 `.env` | ❌ 不需要 | 见「C」 |
| `miniprogram/`（小程序前端） | 不涉及服务器 | 无需操作 |

**原因**：生产镜像在 `Dockerfile.prod` 里 `COPY . .` 把应用代码打进镜像，所以改代码必须重建；而 nginx 配置与证书是 bind mount（挂在容器外），重启 nginx 即生效；`.env` 由 compose 在启动时注入，`up -d` 会重建容器读取新值。

## 二、三种标准操作

### A. 只改代码 → 重建镜像（最常用）

```bash
cd ~/HJAK
git pull
docker compose -f docker-compose.prod.yml up -d --build
docker image prune -f                                    # 清掉旧镜像（悬空 <none>）
docker compose -f docker-compose.prod.yml logs -f web    # 看启动日志
```

> 数据库迁移由 web 容器的入口脚本自动执行（`rails db:prepare`），无需单独跑迁移。

### B. 只改 nginx 配置 / 证书 → 重启（不重建）

```bash
cd ~/HJAK
git pull                    # 或手动替换 deploy/nginx.conf、deploy/certs/
docker compose -f docker-compose.prod.yml restart nginx
```

> 想零停机，可改用 `docker compose -f docker-compose.prod.yml exec nginx nginx -s reload`。

### C. 只改 `.env` → 重建容器（不重建镜像）

```bash
cd ~/HJAK
vi .env
docker compose -f docker-compose.prod.yml up -d
```

## 三、清理规则：什么时候清、清什么

| 时机 | 命令 | 清理对象 | 安全性 |
|---|---|---|---|
| 每次 `--build` 之后 | `docker image prune -f` | 旧的悬空镜像 `<none>` | ✅ 安全 |
| 磁盘紧张 / 定期（每周） | `docker builder prune -f` | 构建缓存 | ✅ 安全 |
| 偶尔 | `docker container prune -f` | 已停止的容器 | ✅ 先确认无需要保留的 |
| 查看占用 | `docker system df` | — | 只读 |

### 🚫 永远不要执行

- `docker compose down -v` —— `-v` 会删除 `db_data` / `storage_data`，等于删库 + 删上传文件
- `docker volume rm db_data storage_data`
- `docker system prune -a --volumes` —— `-a` 激进、`--volumes` 删卷

> 数据安全边界：**镜像和容器随便删都能重建；`db_data` 和 `storage_data` 两个命名卷是唯一不可再生的数据，绝不能碰。**

## 四、一条命令走完大多数日常更新

```bash
cd ~/HJAK && git pull && \
docker compose -f docker-compose.prod.yml up -d --build && \
docker image prune -f && \
docker compose -f docker-compose.prod.yml ps
```

## 五、自检

```bash
# 服务器上（server_name 已设为 hjak.cn，用域名自检）
curl -k --resolve hjak.cn:443:127.0.0.1 https://hjak.cn/up   # 应返回 200
```
