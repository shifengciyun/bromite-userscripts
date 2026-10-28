#!/usr/bin/env bash
# recon relay — runs on GitHub Actions ubuntu runner
T="120.136.20.60"
OUT=/tmp/recon
mkdir -p $OUT
echo "==== RECON RELAY START $(date -u +%FT%TZ) target=$T ===="

echo "==== [1] TCP FULL PORT SCAN ===="
command -v nmap >/dev/null || sudo apt-get install -y -qq nmap >/dev/null 2>&1
sudo nmap -Pn -sT -p- --min-rate 1500 --open -T4 $T -oN $OUT/nmap_full.txt >/dev/null 2>&1
grep -E "^[0-9]+/.*open" $OUT/nmap_full.txt || cat $OUT/nmap_full.txt | tail -30

echo "==== [2] NMAP SERVICE DETECTION ON OPEN PORTS ===="
PORTS=$(grep -E "^[0-9]+/.*(open)" $OUT/nmap_full.txt | cut -d/ -f1 | paste -sd,)
echo "open ports: $PORTS"
[ -n "$PORTS" ] && sudo nmap -Pn -sT -sV -T4 -p "$PORTS" $T 2>/dev/null | sed -n '/PORT/,$p'

echo "==== [3] HTTP PROBE ALL OPEN PORTS ===="
for P in $(echo $PORTS | tr ',' ' '); do
  for SCH in http https; do
    HDR=$(curl -k -s -m 10 -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36" -D - "$SCH://$T:$P/" -o $OUT/body_${SCH}_$P.html --max-time 10 2>/dev/null | head -30)
    CODE=$(echo "$HDR" | head -1 | grep -oE "[0-9]{3}")
    if [ -n "$CODE" ]; then
      echo "--- $SCH://$T:$P/ HTTP $CODE ---"
      echo "$HDR"
      SZ=$(wc -c < $OUT/body_${SCH}_$P.html)
      echo "[body $SZ bytes] first 2500:"
      head -c 2500 $OUT/body_${SCH}_$P.html
      echo ""
    fi
  done
done

echo "==== [4] TITLE / FRAMEWORK QUICK ID ===="
for f in $OUT/body_http_*.html $OUT/body_https_*.html; do
  [ -f "$f" ] || continue
  echo "--- $f ---"
  grep -oE "<title>[^<]*</title>" $f | head -2
  grep -oE "(generator|powered)[^>]{0,80}" $f -i | head -3
  grep -oE "src=\"[^\"]+\.js[^\"]*\"|href=\"[^\"]+\.js[^\"]*\"" $f | head -20
done

echo "==== [5] ROBOTS / COMMON PATHS (port 80/8080 only) ===="
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
for BASE in "http://$T" "http://$T:8080" "https://$T"; do
  for PATH_ in /robots.txt /favicon.ico /index.php /login /api/ /swagger-ui.html /v2/api-docs /actuator/health /.env /.git/HEAD /admin/ /console/; do
    R=$(curl -k -s -m 6 -A "$UA" -o /tmp/pb.bin -w "%{http_code}:%{size_download}" "$BASE$PATH_" 2>/dev/null)
    C=${R%%:*}; S=${R##*:}
    if [ -n "$C" ] && [ "$C" != "000" ] && [ "$C" != "404" ]; then
      echo "$BASE$PATH_ -> $C ($S bytes)"
      if [ "$C" = "200" ] && [ "$S" -lt 20000 ]; then head -c 800 /tmp/pb.bin; echo ""; fi
    fi
  done
done

echo "==== RECON RELAY END $(date -u +%FT%TZ) ===="
exit 0
