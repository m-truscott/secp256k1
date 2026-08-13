#!/bin/bash
# Runs secp256k1 benchmarks and outputs artemis_results.json in the project root

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BENCH="$SCRIPT_DIR/build/bin/bench"

if [ ! -x "$BENCH" ]; then
    echo "Error: bench binary not found at $BENCH" >&2
    echo "Run: cmake -B build --preset dev-mode && cmake --build build" >&2
    exit 1
fi

OUTPUT="$SCRIPT_DIR/artemis_results.json"

# Run bench in raw mode (one line per iteration per benchmark),
# then pivot into one JSON object per iteration.
SECP256K1_BENCH_RAW=1 "$BENCH" 2>&1 | awk -F',' '
{
    name = $1
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", name)
    val = $2
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
    if (name == "" || val+0 == 0) next

    if (!(name in count)) {
        keys[nkeys++] = name
    }
    idx = count[name]++
    data[name, idx] = val
}
END {
    # All benchmarks have the same count of iterations
    n = count[keys[0]]
    printf "[\n"
    for (i = 0; i < n; i++) {
        printf "  {"
        for (k = 0; k < nkeys; k++) {
            if (k > 0) printf ", "
            printf "\"%s\": %s", keys[k], data[keys[k], i]
        }
        printf "}"
        if (i < n - 1) printf ","
        printf "\n"
    }
    printf "]\n"
}
' > "$OUTPUT"

echo "Results written to $OUTPUT"
