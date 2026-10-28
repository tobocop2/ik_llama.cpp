#!/usr/bin/env bash
# usage: probe.sh LABEL BIN MODEL OUTDIR EXTRA...
set -u
label=$1; bin=$2; model=$3; out=$4; shift 4
d="$out/$label"
mkdir -p "$d"
port=$((8100 + RANDOM % 800))
"$bin" -m "$model" --host 127.0.0.1 --port "$port" "$@" > "$d/log.txt" 2>&1 &
pid=$!
ready=0
for i in $(seq 1 240); do
    code=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$port/health" || true)
    if [ "$code" = 200 ]; then ready=1; break; fi
    if ! kill -0 "$pid" 2>/dev/null; then break; fi
    sleep 0.5
done
echo "$ready" > "$d/ready"
echo "$*" > "$d/args"
if [ "$ready" = 1 ]; then
    curl -s -o "$d/memory.json" -w '%{http_code}' "http://127.0.0.1:$port/memory" > "$d/memory.code" || true
    curl -s -o "$d/metrics.txt" -w '%{http_code}' "http://127.0.0.1:$port/metrics" > "$d/metrics.code" || true
    curl -s -o "$d/props.json" "http://127.0.0.1:$port/props" || true
fi
kill "$pid" 2>/dev/null || true
wait "$pid" 2>/dev/null || true
echo "probe $label ready=$ready memory=$(cat "$d/memory.code" 2>/dev/null) metrics=$(cat "$d/metrics.code" 2>/dev/null)"
