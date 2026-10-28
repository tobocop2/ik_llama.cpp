import sys

S = "examples/server/server.cpp"
L = "src/llama.cpp"
C = "examples/server/server-context.cpp"
G = "common/common.cpp"

ARMS = {
    "gate": (S, "        if (!params.endpoint_memory) {", "        if (false) {"),
    "model": (L, "        res.add_model_buffer(model.bufs[i]);", "        (void) i;"),
    "context": (L, "        res.find(ggml_backend_buffer_get_type(ctx->kv_self.bufs[i])).context += ggml_backend_buffer_get_size(ctx->kv_self.bufs[i]);", "        (void) i;"),
    "output": (L, "        res.find(ggml_backend_buffer_get_type(ctx->buf_output)).context += ggml_backend_buffer_get_size(ctx->buf_output);", "        (void) 0;"),
    "compute": (L, "                res.find(buft).compute += size;", "                (void) buft;"),
    "mmproj": (L, "            res.find(mmproj[i].buft).mmproj += mmproj[i].size;", "            (void) i;"),
    "gauges": (S, "        prometheus << render_memory_metrics(data.at(\"memory\"));", "        (void) data;"),
    "gauges_gated": (S, "        prometheus << render_memory_metrics(data.at(\"memory\"));", "        if (params.endpoint_memory) prometheus << render_memory_metrics(data.at(\"memory\"));"),
    "gauge_double": (S, "<< entry.at(keys[k]).dump() <<", "<< entry.at(keys[k]).get<double>() <<"),
    "help_dupe": (S, "                described = true;\n", ""),
    "total_free": (C, "            entry[\"total\"] = rows[i].total;\n            entry[\"free\"]  = rows[i].free;", "            (void) i;"),
    "host_total": (C, "        if (rows[i].is_device) {", "        if (true) {"),
    "dedup": (L, "        for (size_t i = 0; i < seen.size(); ++i) {\n            if (seen[i] == buf) {\n                return;\n            }\n        }\n", ""),
    "n_layer": (C, "res.data[\"n_layer\"] = llama_n_layer(model);", "res.data[\"n_layer\"] = 0;"),
    "env": (G, "    get_env(\"LLAMA_ARG_ENDPOINT_MEMORY\",  params.endpoint_memory);\n", ""),
    "mmproj_always": (C, "        if (mctx) {\n            entry[\"mmproj\"] = rows[i].mmproj;", "        if (true) {\n            entry[\"mmproj\"] = rows[i].mmproj;"),
    "host_row": (L, "        return rows[i_host];\n", "        return rows[0];\n"),
    "metrics_task": (C, "        if (task.metrics_memory) {", "        if (false) {"),
}

path, old, new = ARMS[sys.argv[1]]
src = open(path).read()
assert src.count(old) == 1, (sys.argv[1], src.count(old))
open(path, "w").write(src.replace(old, new))
print("applied", sys.argv[1])
