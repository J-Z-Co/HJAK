# PhoenixList 文档入口

家庭成员健康指标追踪器。协作方式沿用 brandy / cracker：设想 → 蓝图 → 确认决策表 → 分阶段实施。

| 文件 | 职能 |
|------|------|
| [`blueprints/health_tracker_v1.md`](blueprints/health_tracker_v1.md) | 初版产品蓝图（0.4 草案）。主路径是手机竖屏。容器命令在 §9 |
| [`blueprints/post_deploy_v1.md`](blueprints/post_deploy_v1.md) | 成功部署之后（0.3 草案）。重复发布步骤。记住登录和改善建议已在本地落实。Host 白名单暂不做 |
| [`blueprints/ui_redesign_v1.md`](blueprints/ui_redesign_v1.md) | 手机端彩色改版与记录激励（0.1，已合并到 `main`）。视觉系统、各页改动、连续天数与徽章、综合 / 本周 / 徽章三个排行榜。体重仍每天记，超过 20 岁的身高记过一次后不用再更新。§8 列出替换掉的 v1 §6 规则，待拍板 |

应用已在容器内生成。日常开发用 `docker compose exec web bash`，看页面用 `docker compose exec web bin/dev`。
