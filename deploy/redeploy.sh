#!/usr/bin/env bash
#
# 生产重新部署脚本（在服务器上运行）。
# 用法：./deploy/redeploy.sh <子命令>   或   ./deploy/redeploy.sh --help
set -euo pipefail

# 无论从哪里执行，都回到项目根目录
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."

COMPOSE=(docker compose -f docker-compose.prod.yml)

log() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

usage() {
  cat <<'EOF'
用法：./deploy/redeploy.sh <子命令>

子命令（可省略，默认 full）：
  build          改代码后：git pull + 重建镜像 + 启动 + 清旧镜像（最常用）
  restart-nginx  只改 deploy/nginx.conf 或证书：重启 nginx
  env            只改根目录 .env：重建容器读取新环境变量
  clean          清理：悬空镜像 + 构建缓存 + 已停止容器
  status         查看容器状态与磁盘占用
  logs           跟踪 web 日志
  check          健康检查 https://hjak.cn/up
  full           build + clean（默认）

示例：
  ./deploy/redeploy.sh              # 等于 full
  ./deploy/redeploy.sh build
  ./deploy/redeploy.sh restart-nginx
  ./deploy/redeploy.sh clean
EOF
}

cmd_build() {
  log "拉取最新代码"
  git pull
  log "重建并启动（含数据库迁移）"
  "${COMPOSE[@]}" up -d --build
  log "清理旧镜像"
  docker image prune -f
  "${COMPOSE[@]}" ps
}

cmd_restart_nginx() {
  log "重启 nginx"
  "${COMPOSE[@]}" restart nginx
}

cmd_env() {
  log "重建容器以读取新 .env"
  "${COMPOSE[@]}" up -d
  "${COMPOSE[@]}" ps
}

cmd_clean() {
  log "清理悬空镜像"
  docker image prune -f
  log "清理构建缓存"
  docker builder prune -f
  log "清理已停止容器"
  docker container prune -f
  log "当前磁盘占用"
  docker system df
}

cmd_status() {
  "${COMPOSE[@]}" ps
  echo
  docker system df
}

cmd_logs() {
  "${COMPOSE[@]}" logs -f --tail=100 web
}

cmd_check() {
  log "健康检查 https://hjak.cn/up"
  curl -k --resolve hjak.cn:443:127.0.0.1 https://hjak.cn/up -w '\nHTTP %{http_code}\n'
}

case "${1:-full}" in
  build)          cmd_build ;;
  restart-nginx)  cmd_restart_nginx ;;
  env)            cmd_env ;;
  clean)          cmd_clean ;;
  status)         cmd_status ;;
  logs)           cmd_logs ;;
  check)          cmd_check ;;
  full)           cmd_build && cmd_clean ;;
  -h|--help|help) usage ;;
  *)              echo "未知子命令：$1" >&2; usage; exit 1 ;;
esac
