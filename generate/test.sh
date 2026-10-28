#!/usr/bin/env bash
echo "==== VANTAGE TEST $(date -u +%FT%TZ) ===="
echo "--- my egress IP ---"
curl -s -m 10 https://api.ipify.org; echo ""
echo "--- control: nvu.edu.cn IP 59.52.27.241:80 ---"
curl -s -m 15 -o /tmp/nvu.html -w "http:%{http_code} time:%{time_total} size:%{size_download}\n" http://59.52.27.241/ || echo FAIL
head -c 200 /tmp/nvu.html; echo ""
echo "--- control2: www.baidu.com ---"
curl -s -m 15 -o /dev/null -w "http:%{http_code} time:%{time_total}\n" http://www.baidu.com/ || echo FAIL
echo "--- target TCP 80 raw ---"
timeout 20 bash -c "echo > /dev/tcp/120.136.20.60/80" && echo "TCP80 OPEN" || echo "TCP80 blocked/timeout"
echo "--- target curl 80 long timeout ---"
curl -s -m 25 -o /tmp/t80.html -w "http:%{http_code} time:%{time_total} size:%{size_download}\n" http://120.136.20.60/ || echo FAIL80
head -c 200 /tmp/t80.html; echo ""
echo "--- target curl 443 long timeout ---"
curl -sk -m 25 -o /tmp/t443.html -w "https:%{http_code} time:%{time_total} size:%{size_download}\n" https://120.136.20.60/ || echo FAIL443
head -c 200 /tmp/t443.html; echo ""
echo "--- target TCP 443/8080/22 raw ---"
for p in 443 8080 22 3389; do timeout 12 bash -c "echo > /dev/tcp/120.136.20.60/$p" 2>/dev/null && echo "TCP$p OPEN" || echo "TCP$p filtered"; done
echo "==== VANTAGE TEST END ===="
exit 0
