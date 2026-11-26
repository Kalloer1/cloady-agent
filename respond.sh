#!/bin/sh
# 就绪探针应答器：cloady 打哪个路径不确定（/ 或 /health），一律回 200。
# 单独成文件是因为 socat 的 SYSTEM: 会把 \r\n 当自己的转义处理，写进命令行会散架。
printf 'HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 3\r\nConnection: close\r\n\r\nok\n'
