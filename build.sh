#!/usr/bin/env bash
set -euo pipefail

VERSION=$(cat VERSION)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

OUT="dist/mod2vid"
mkdir -p dist

cat > "$OUT" <<EOF
#!/usr/bin/env bash
# Version: $VERSION
# Built:   $TIMESTAMP
set -euo pipefail

EOF

for f in src/globals.sh src/env.sh src/title_templates.sh src/terminal.sh \
         src/media.sh src/cli.sh; do
  echo "# --- $f ---" >> "$OUT"
  sed "s/__VERSION__/$VERSION/g" "$f" >> "$OUT"
  echo >> "$OUT"
done
echo "# --- src/main.sh ---" >> "$OUT"
sed '/^source /d' src/main.sh >> "$OUT"
echo >> "$OUT"

chmod +x "$OUT"
echo "Built $OUT (version $VERSION)"

# Syntax check
if ! bash -n "$OUT"; then
  echo "ERR: Syntax check failed"
  exit 1
fi

# Smoke test: --help should not fail
if ! "$OUT" --help >/dev/null 2>&1; then
  echo "ERR: Smoke test failed (mod2vid --help)"
  exit 1
fi

echo "Syntax OK, smoke test passed"

