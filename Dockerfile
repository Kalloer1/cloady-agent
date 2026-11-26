# cloady-agent — PicoClaw (Telegram) + instabox CLI on cloady free tier
#
# 设计约束（实测，见 README）：
#   * 容器 512 MB 内存硬墙 —— Node 级 agent 会 OOM，这里用 Go 单二进制
#   * 没有 systemd —— 进程 1 就是 entrypoint，靠容器重启策略保活
#   * 端口沿用 3080（原 dsh 的端口）由 socat 应答：cloady 的就绪探针很可能打 /，
#     而 PicoClaw 的 / 是 404。沿用同一端口也让 ds.mccnp.top 的域名映射不用改。
#     PicoClaw 自己的 gateway 只监听 127.0.0.1:18790，不对外
FROM debian:bookworm-slim

ARG PICOCLAW_VERSION=v0.3.1

ENV DEBIAN_FRONTEND=noninteractive \
    PICOCLAW_HOME=/data/picoclaw \
    INSTABOX_NO_UPDATE_CHECK=1

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl tar socat procps tzdata git jq \
 && rm -rf /var/lib/apt/lists/*

# PicoClaw: 从 GitHub Release 拿预编译二进制，不在 0.25 核上跑 Go 编译
RUN set -eux; \
    curl -fsSL --retry 3 -o /tmp/pc.tgz \
      "https://github.com/sipeed/picoclaw/releases/download/${PICOCLAW_VERSION}/picoclaw_Linux_x86_64.tar.gz"; \
    tar -xzf /tmp/pc.tgz -C /tmp picoclaw; \
    install -m 0755 /tmp/picoclaw /usr/local/bin/picoclaw; \
    rm -rf /tmp/pc.tgz /tmp/picoclaw; \
    picoclaw --version 2>&1 | head -1 || true

# instabox CLI（静态 Go 二进制，装到 /usr/local/bin/instabox）
RUN curl -fsSL --retry 3 https://api.instabox.sh/install.sh | sh

COPY entrypoint.sh /entrypoint.sh
RUN chmod 0755 /entrypoint.sh && mkdir -p /data/picoclaw

EXPOSE 3080
ENTRYPOINT ["/entrypoint.sh"]
