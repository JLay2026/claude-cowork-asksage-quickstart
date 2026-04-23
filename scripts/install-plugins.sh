#!/usr/bin/env bash
# Bulk-install all 11 Anthropic knowledge-work plugins via the Claude Code CLI.
# Requires: Claude Code installed and on PATH. https://claude.com/product/claude-code

set -euo pipefail

MARKETPLACE="anthropics/knowledge-work-plugins"
PLUGINS=(
  "cowork-plugin-management"
  "productivity"
  "enterprise-search"
  "sales"
  "customer-support"
  "product-management"
  "marketing"
  "legal"
  "finance"
  "data"
  "bio-research"
)

if ! command -v claude >/dev/null 2>&1; then
  echo "ERROR: 'claude' CLI not found on PATH." >&2
  echo "Install Claude Code first: https://claude.com/product/claude-code" >&2
  exit 1
fi

echo "==> Adding marketplace: ${MARKETPLACE}"
claude plugin marketplace add "${MARKETPLACE}" || true

echo ""
echo "==> Installing ${#PLUGINS[@]} plugins"
installed=()
failed=()
for plugin in "${PLUGINS[@]}"; do
  echo ""
  echo "--- ${plugin} ---"
  if claude plugin install "${plugin}@knowledge-work-plugins"; then
    installed+=("${plugin}")
  else
    failed+=("${plugin}")
  fi
done

echo ""
echo "==================================================="
echo "Installed (${#installed[@]}): ${installed[*]:-none}"
if (( ${#failed[@]} > 0 )); then
  echo "Failed (${#failed[@]}): ${failed[*]}"
  echo "Retry a failed plugin manually with:"
  echo "  claude plugin install <name>@knowledge-work-plugins"
  exit 1
fi
echo "All plugins installed. Open Cowork and type / to see new slash commands."
