import json, sys

def load(p):
    try:
        return json.load(open(p))
    except Exception as e:
        return None

a = load(sys.argv[1]); b = load(sys.argv[2])
print("A =", sys.argv[1]); print("B =", sys.argv[2])
if a is None or b is None:
    print("unreadable:", a is None, b is None)
    sys.exit(0)
print("top-level keys A:", sorted(a.keys()), "B:", sorted(b.keys()))
print("n_layer A:", a.get("n_layer"), "B:", b.get("n_layer"))
ra = {r["name"]: r for r in a["data"]}; rb = {r["name"]: r for r in b["data"]}
for n in sorted(set(ra) | set(rb)):
    x = ra.get(n); y = rb.get(n)
    if x is None or y is None:
        print(f"row {n}: only in {'A' if y is None else 'B'}: {x or y}")
        continue
    for f in sorted(set(x) | set(y)):
        if f == "name":
            continue
        if x.get(f) != y.get(f):
            print(f"row {n} field {f}: A={x.get(f)} B={y.get(f)}")
        else:
            print(f"row {n} field {f}: equal {x.get(f)}")
