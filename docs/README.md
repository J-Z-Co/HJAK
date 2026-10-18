# PhoenixList 文档入口

家庭成员健康指标追踪器。协作方式沿用 brandy / cracker：设想 → 蓝图 → 确认决策表 → 分阶段实施。

| 文件 | 职能 |
|------|------|
| [`blueprints/health_tracker_v1.md`](blueprints/health_tracker_v1.md) | 初版产品蓝图（0.4 草案）。主路径是手机竖屏。容器命令在 §9 |

应用已在容器内生成。日常开发用 `docker compose exec web bash`，看页面用 `docker compose exec web bin/dev`。
