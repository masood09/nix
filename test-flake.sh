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
    ERRORS=$((ERRORS + 1))
else
    echo "✅ Syntax check passed"
fi
echo ""

# 2. Flake metadata check
echo "2️⃣  Validating flake metadata..."
if ! nix --extra-experimental-features nix-command --extra-experimental-features flakes flake metadata --no-write-lock-file > /dev/null 2>&1; then
    echo "❌ Flake metadata validation failed"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ Flake metadata valid"
fi
echo ""

# 3. Flake show (list outputs)
echo "3️⃣  Verifying flake outputs..."
if ! nix --extra-experimental-features nix-command --extra-experimental-features flakes flake show --no-write-lock-file > /dev/null 2>&1; then
    echo "❌ Flake show failed"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ Flake outputs accessible"
fi
echo ""

# 4. Evaluate all host configurations
echo "4️⃣  Evaluating host configurations..."
HOSTS=$(nix eval --extra-experimental-features nix-command --extra-experimental-features flakes .#nixosConfigurations --apply 'x: builtins.attrNames x' --json 2>/dev/null | jq -r '.[]')
for host in $HOSTS; do
    if nix --extra-experimental-features nix-command --extra-experimental-features flakes eval --impure ".#nixosConfigurations.${host}.config.system.name" > /dev/null 2>&1; then
        echo "✅ ${host} configuration evaluates"
    else
        echo "❌ ${host} configuration evaluation failed"
        ERRORS=$((ERRORS + 1))
    fi
done
echo ""

# 5. SOPS secrets validation (check that *.sops.yaml files are SOPS-encrypted)
# Failures here are fatal: a *.sops.yaml missing its `sops:` block or `ENC[`
# values means plaintext credentials are about to be committed. An unreadable
# file is fatal too — the check could not be performed, which is not a pass.
echo "5️⃣  Validating SOPS secrets..."
SOPS_ERRORS=0
while IFS= read -r -d '' sops_file; do
  if [ ! -r "$sops_file" ]; then
    echo "❌ Cannot read SOPS file: $sops_file"
    SOPS_ERRORS=$((SOPS_ERRORS + 1))
    continue
  fi
  # A properly-encrypted SOPS YAML should contain:
  # - a top-level `sops:` metadata block, and
  # - at least one `ENC[` encrypted value somewhere
  if ! grep -qE '^sops:' "$sops_file" || ! grep -q 'ENC\[' "$sops_file"; then
    echo "❌ Unencrypted or malformed SOPS file: $sops_file"
    SOPS_ERRORS=$((SOPS_ERRORS + 1))
  fi
done < <(
  find . \
    -type f \
    -name "*.sops.yaml" \
    ! -name ".sops.yaml" \
    ! -path "*/.git/*" \
    -print0 2>/dev/null
)
if [ "$SOPS_ERRORS" -eq 0 ]; then
  echo "✅ SOPS secrets look encrypted"
else
  echo "❌ Found $SOPS_ERRORS unencrypted/malformed SOPS file(s)"
  ERRORS=$((ERRORS + SOPS_ERRORS))
fi
echo ""

echo "6️⃣ ️Verifying flake.lock is unchanged..."
if git diff --name-only --exit-code flake.lock > /dev/null; then
  echo "✅ flake.lock unchanged"
else
  echo "❌ flake.lock changed during validation"
  git diff -- flake.lock
  ERRORS=$((ERRORS + 1))
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
