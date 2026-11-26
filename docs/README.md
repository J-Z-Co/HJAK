# 梅珊知安 文档入口

家庭成员健康指标追踪器。协作方式沿用 brandy / cracker：设想 → 蓝图 → 确认决策表 → 分阶段实施。

| 文件 | 职能 |
|------|------|
| [`blueprints/health_tracker_v1.md`](blueprints/health_tracker_v1.md) | 初版产品蓝图（0.4 草案）。主路径是手机竖屏。§13 主屏幕清单已打开，全名「合家安康」、短名「合家康」。生产环境只登记一个服务工作线程。容器命令在 §9 |
| [`blueprints/post_deploy_v1.md`](blueprints/post_deploy_v1.md) | 成功部署之后（0.3 草案）。重复发布步骤。记住登录和改善建议已在本地落实。Host 白名单暂不做 |
| [`blueprints/ui_redesign_v1.md`](blueprints/ui_redesign_v1.md) | 手机端彩色改版与记录激励（0.1，已合并到 `main`）。视觉系统、各页改动、连续天数与徽章、综合 / 本周 / 徽章三个排行榜。体重仍每天记，超过 20 岁的身高记过一次后不用再更新。§8 列出替换掉的 v1 §6 规则，待拍板 |
| [`blueprints/group_boards_v1.md`](blueprints/group_boards_v1.md) | 群组榜单（0.2 草案）。现状、本周改善、时效内项数、徽章第四榜，以及近一年动态图。一周从北京时间周一 00:00 起 |
| [`blueprints/client_cache_v1.md`](blueprints/client_cache_v1.md) | 页面缓存与加载回弹（0.2 草案）。样式长缓存；指数和群组按用户缓存 6 小时，先显示再核对 |
| [`blueprints/group_nudge_v1.md`](blueprints/group_nudge_v1.md) | 群组催催（0.2 草案）。每天一次，表情 😜，图标留到对方新保存一条测量。系统推送后做 |
| [`blueprints/remaining_work_v1.md`](blueprints/remaining_work_v1.md) | 工作规划（0.1，已确认）。榜单、年图、催催、回弹、缓存按此落实。推送不做 |
| [`blueprints/experience_v1.md`](blueprints/experience_v1.md) | 用户体验优化（0.4 草案）。数据库留在新加坡。容器区域改为 `sin1`。生产页用同域统计脚本 |

应用已在容器内生成。日常开发用 `docker compose exec web bash`，看页面用 `docker compose exec web bin/dev`。
