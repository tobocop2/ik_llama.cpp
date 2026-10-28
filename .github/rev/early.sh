#!/usr/bin/env bash
# usage: early.sh LABEL BIN MODEL OUTDIR EXTRA...   polls /memory from process start until healthy
set -u
label=$1; bin=$2; model=$3; out=$4; shift 4
d="$out/$label"
mkdir -p "$d"
port=$((8100 + RANDOM % 800))
"$bin" -m "$model" --host 127.0.0.1 --port "$port" "$@" > "$d/log.txt" 2>&1 &
pid=$!
: > "$d/codes.txt"
for i in $(seq 1 6000); do
    code=$(curl -s -m 1 -o "$d/last.body" -w '%{http_code}' "http://127.0.0.1:$port/memory" || true)
    echo "$code" >> "$d/codes.txt"
    if [ "$code" = 200 ]; then break; fi
    if ! kill -0 "$pid" 2>/dev/null; then echo dead >> "$d/codes.txt"; break; fi
    sleep 0.02
done
uniq -c "$d/codes.txt" > "$d/codes.uniq"
kill "$pid" 2>/dev/null || true
wait "$pid" 2>/dev/null || true
echo "early $label:"; cat "$d/codes.uniq"; head -c 300 "$d/last.body"; echo
