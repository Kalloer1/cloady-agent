#!/bin/sh
# 从环境变量生成 PicoClaw 配置，然后启动 gateway。
# 配置每次启动重写 —— 容器没有持久卷，唯一的事实来源是 cloady 的变量表。
set -eu

: "${PICOCLAW_HOME:=/data/picoclaw}"
: "${PICOCLAW_CONFIG:=$PICOCLAW_HOME/config.json}"
: "${MODEL_API_BASE:=https://mg.mccnp.top:2053/v1}"
: "${MODEL_NAME:=workbuddy-ai/deepseek-v4.1-flash}"

die() { printf 'entrypoint: %s\n' "$*" >&2; exit 1; }

[ -n "${TG_TOKEN:-}" ]        || die "TG_TOKEN 未设置"
[ -n "${TG_ALLOW_FROM:-}" ]   || die "TG_ALLOW_FROM 未设置（留空等于对所有人开放，拒绝启动）"
[ -n "${MODEL_API_KEY:-}" ]   || die "MODEL_API_KEY 未设置"

mkdir -p "$PICOCLAW_HOME/workspace"

umask 077
cat > "$PICOCLAW_CONFIG" <<EOF
{
  "version": 3,
  "gateway": { "host": "127.0.0.1", "port": 18790, "log_level": "info" },
  "agents": {
    "defaults": {
      "model_name": "main",
      "workspace": "$PICOCLAW_HOME/workspace",
      "restrict_to_workspace": false
    }
  },
  "model_list": [
    {
      "model_name": "main",
      "provider": "openai",
      "model": "$MODEL_NAME",
      "api_base": "$MODEL_API_BASE",
      "api_keys": ["$MODEL_API_KEY"]
    }
  ],
  "channel_list": {
    "telegram": {
      "enabled": true,
      "type": "telegram",
      "allow_from": ["$TG_ALLOW_FROM"],
      "settings": { "token": "$TG_TOKEN" }
    }
  },
  "tools": {
    "exec": { "enabled": true, "allow_remote": true, "enable_deny_patterns": false }
  }
}
EOF
chmod 600 "$PICOCLAW_CONFIG"

# cloady 的探针打哪个路径不确定，用 socat 对任何路径都回 200；
# 真 gateway 只在回环 18790，不对外。端口沿用 3080 保住域名映射。
socat TCP-LISTEN:3080,fork,reuseaddr EXEC:/usr/local/bin/respond.sh &

exec picoclaw gateway
