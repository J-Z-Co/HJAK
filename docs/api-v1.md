# 小程序 JSON API（v1）

Base path：`/api/v1`。除 `POST /auth/wechat` 外，所有接口都要带请求头：

```
Authorization: Bearer <api_token>
```

## 鉴权

### POST /api/v1/auth/wechat —— 微信登录

请求：

```json
{ "code": "wx.login() 返回的 code", "display_name": "可选", "sex": "可选 male/female", "birth_date": "可选 YYYY-MM-DD" }
```

响应：

```json
{ "token": "<api_token>", "new_user": true, "user": { "id": 1, "display_name": "微信用户", "sex": null, "birth_date": null } }
```

- `new_user` 为 true 时，前端应引导用户补全 `sex` / `birth_date`（调用 `PATCH /me`）。
- AppID / AppSecret 只放后端：`rails credentials:edit` 里加
  `wechat: { appid: wx..., secret: ... }`，或用环境变量 `WECHAT_APPID` / `WECHAT_SECRET`。

## 记录

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/api/v1/measurements/new` | 记录表单（rows + progress + recorded_on + idempotency_key） |
| POST | `/api/v1/measurements` | 批量保存 |
| DELETE | `/api/v1/measurements/:id` | 删除 |

POST body：

```json
{
  "recorded_on": "2026-11-23",
  "idempotency_key": "来自 GET new 的 uuid",
  "measurements": { "weight": { "value": "60" }, "blood_pressure": { "value": "120", "value_secondary": "80" } }
}
```

## 指数

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/api/v1/indices` | 总览（board + brief） |
| GET | `/api/v1/indices/overview` | 仅 board |
| GET | `/api/v1/indices/:key?range=7d\|30d\|365d` | 单项（reading + series + explanation） |

## 我的

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/api/v1/me` | 资料 + 进度 |
| PATCH/PUT | `/api/v1/me` | 更新 `{ display_name, sex, birth_date }` |

## 群组

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/api/v1/groups` | 我的群组列表 |
| POST | `/api/v1/groups` | 建群 `{ name }` |
| POST | `/api/v1/groups/join` | 加入 `{ code }`（代号或分享链接） |
| GET | `/api/v1/groups/:public_id?board=health\|trend\|fresh\|badges` | 群详情 + 榜单 |
| GET | `/api/v1/groups/:public_id/year` | 年度图 |
| POST | `/api/v1/groups/:public_id/nudge` | 提醒 `{ subject_id }` |
| DELETE | `/api/v1/groups/:public_id/membership` | 退出 |
| DELETE | `/api/v1/groups/:public_id/members/:user_id/membership` | 群主移除成员 |
| DELETE | `/api/v1/groups/:public_id` | 群主删群 |
| GET | `/api/v1/groups/:public_id/members/:user_id/indices` | 成员指数总览 |
| GET | `/api/v1/groups/:public_id/members/:user_id/indices/:key` | 成员单项指数 |

## 建议 / 纠错

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/api/v1/suggestions` | 建议列表（含回复） |
| POST | `/api/v1/suggestions` | 提交 `{ body, parent_id? }` |
| POST | `/api/v1/suggestions/:id/vote` | 投票 `{ choice: "reasonable"\|"wrong" }` |
| DELETE | `/api/v1/suggestions/:id` | 删除自己的建议 |
| GET | `/api/v1/corrections` | 指标列表 |
| GET | `/api/v1/corrections/:metric` | 某指标的记录历史 |
| PATCH/PUT | `/api/v1/corrections/:metric/entries/:id` | 改一条记录 |
| DELETE | `/api/v1/corrections/:metric/entries/:id` | 删一条记录 |
