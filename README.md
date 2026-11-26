# cloady-agent

PicoClaw（Go，10–20 MB 常驻）跑在 cloady 免费档，通过 Telegram 交互，容器里带 `instabox` CLI。

## 为什么是这套

| 约束（cloady 实测） | 后果 |
|---|---|
| `memory.max` = 536870912（512 MB） | Node 级 agent（实测 344 MB）没有余量，用 Go 单二进制 |
| 没有 systemd，进程 1 = entrypoint | 保活靠容器重启；多进程用 `&` + `exec` 主进程 |
| 探针路径未知，PicoClaw 的 `/` 是 404 | socat 在 8080 对任何路径回 200，真 gateway 只在回环 18790 |
| 无持久卷 | 配置每次启动由环境变量重写 |

## 环境变量（全部在 cloady 的变量表里，不进仓库）

| 变量 | 必需 | 说明 |
|---|---|---|
| `TG_TOKEN` | 是 | @BotFather 给的 bot token |
| `TG_ALLOW_FROM` | 是 | 允许的 Telegram user id。**留空等于对所有人开放**，entrypoint 会拒绝启动 |
| `MODEL_API_KEY` | 是 | 模型网关 key |
| `MODEL_API_BASE` | 否 | 默认 `https://mg.mccnp.top:2053/v1` |
| `MODEL_NAME` | 否 | 默认 `workbuddy-ai/deepseek-v4.1-flash` |

## 权限面

`restrict_to_workspace: false` + `tools.exec.enable_deny_patterns: false` + `allow_remote: true`
= 拿到 bot 的人可以在容器里执行任意命令（容器内是 root）。唯一闸门是 `TG_ALLOW_FROM`。

## 本地构建

```sh
docker build -t cloady-agent .
docker run --rm -e TG_TOKEN=… -e TG_ALLOW_FROM=… -e MODEL_API_KEY=… -p 8080:8080 cloady-agent
```
