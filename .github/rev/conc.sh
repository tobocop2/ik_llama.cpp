#!/usr/bin/env bash
# usage: conc.sh LABEL BIN MODEL OUTDIR EXTRA...   /memory and /metrics while completions run
set -u
label=$1; bin=$2; model=$3; out=$4; shift 4
d="$out/$label"
mkdir -p "$d/r"
port=$((8100 + RANDOM % 800))
"$bin" -m "$model" --host 127.0.0.1 --port "$port" "$@" > "$d/log.txt" 2>&1 &
pid=$!
for i in $(seq 1 240); do
    code=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$port/health" || true)
    if [ "$code" = 200 ]; then break; fi
    sleep 0.5
done
cpids=""
for j in 1 2 3 4; do
    curl -s -o "$d/r/comp$j.json" -w '%{http_code}\n' -H 'Content-Type: application/json' \
        -d '{"prompt":"Once upon a time","n_predict":200,"temperature":0.8}' "http://127.0.0.1:$port/completion" > "$d/r/comp$j.code" &
    cpids="$cpids $!"
done
sleep 0.3
seq 1 120 | xargs -P 8 -I{} sh -c "curl -s -o $d/r/mem{}.json -w '%{http_code}\n' http://127.0.0.1:$port/memory > $d/r/mem{}.code"
seq 1 60 | xargs -P 8 -I{} sh -c "curl -s -o $d/r/met{}.txt -w '%{http_code}\n' http://127.0.0.1:$port/metrics > $d/r/met{}.code"
wait $cpids 2>/dev/null || true
sleep 1
alive=0; kill -0 "$pid" 2>/dev/null && alive=1
echo "alive=$alive" > "$d/summary.txt"
echo "mem codes: $(cat "$d"/r/mem*.code | sort | uniq -c | tr '\n' ' ')" >> "$d/summary.txt"
echo "met codes: $(cat "$d"/r/met*.code | sort | uniq -c | tr '\n' ' ')" >> "$d/summary.txt"
echo "comp codes: $(cat "$d"/r/comp*.code | sort | uniq -c | tr '\n' ' ')" >> "$d/summary.txt"
echo "distinct memory bodies: $(cat "$d"/r/mem*.json | python3 -c 'import sys,json
s=set()
for l in sys.stdin.read().replace("}{","}\n{").splitlines():
    try:
        j=json.loads(l)
        s.add(json.dumps(j,sort_keys=True))
    except Exception as e:
        s.add("BAD:"+l[:40])
print(len(s))
for x in s: print(x[:300])')" >> "$d/summary.txt"
cat "$d/summary.txt"
kill "$pid" 2>/dev/null || true
wait "$pid" 2>/dev/null || true
