#!/usr/bin/env bash
# Comprehensive flake validation script
# Runs fast validation tests without building derivations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

ERRORS=0

echo "🧪 Running comprehensive flake validation tests..."
echo ""

# 1. Quick syntax check
echo "1️⃣  Checking Nix syntax..."
if ! nix-instantiate --parse flake.nix > /dev/null 2>&1; then
    echo "❌ Syntax check failed"
    ((ERRORS++))
else
    echo "✅ Syntax check passed"
fi
echo ""

# 2. Flake metadata check
echo "2️⃣  Validating flake metadata..."
if ! nix flake metadata --no-write-lock-file > /dev/null 2>&1; then
    echo "❌ Flake metadata validation failed"
    ((ERRORS++))
else
    echo "✅ Flake metadata valid"
fi
echo ""

# 3. Flake show (list outputs)
echo "3️⃣  Verifying flake outputs..."
if ! nix flake show --no-write-lock-file > /dev/null 2>&1; then
    echo "❌ Flake show failed"
    ((ERRORS++))
else
    echo "✅ Flake outputs accessible"
fi
echo ""

# 5. Evaluate all host configurations
echo "4️⃣  Evaluating host configurations..."
HOSTS=$(nix eval .#nixosConfigurations --apply 'x: builtins.attrNames x' --json 2>/dev/null | jq -r '.[]')
for host in $HOSTS; do
    if nix eval --impure ".#nixosConfigurations.${host}.config.system.name" > /dev/null 2>&1; then
        echo "✅ ${host} configuration evaluates"
    else
        echo "❌ ${host} configuration evaluation failed"
        ((ERRORS++))
    fi
done
echo ""

echo "5️⃣  Verifying flake.lock is unchanged..."
if git diff --name-only --exit-code flake.lock > /dev/null; then
  echo "✅ flake.lock unchanged"
else
  echo "❌ flake.lock changed during validation"
  git diff -- flake.lock
  ((ERRORS++))
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ERRORS -eq 0 ]; then
    echo "✅ All validation tests passed!"
    exit 0
else
    echo "❌ Validation failed with $ERRORS error(s)"
    exit 1
fi
