#!/usr/bin/env bash
#
# 检查 lib/presentation/ 和 lib/divination_systems/ 下
# 是否存在无注释的硬编码 Color(0xFFXXXXXX) 字面量。
#
# 允许：同行或上方 1 行内有 // 注释的 Color 字面量（域色/语义色）
# 禁止：新增的无注释 Color 字面量
#
# 运行方式：bash tool/audit_hardcoded_colors.sh
# 退出码：有未注释硬编码返回 1，否则 0

set -euo pipefail

TARGETS=(
  "lib/presentation"
  "lib/divination_systems"
)

VIOLATIONS=0

for dir in "${TARGETS[@]}"; do
  [[ ! -d "$dir" ]] && continue

  # 找所有 Color(0xXXXXXXXX) 行（8 位 hex，即 ARGB）
  while IFS= read -r line; do
    file=$(echo "$line" | cut -d: -f1)
    lineno=$(echo "$line" | cut -d: -f2)

    # 跳过 antique/ 目录——设计系统组件自身引用 AppColors，
    # 不应有 0x 字面量，但保险跳过避免误报
    if [[ "$file" == *"/widgets/antique/"* ]]; then
      continue
    fi

    # 提取该行内容 + 上一行内容
    current_line=$(sed -n "${lineno}p" "$file")
    prev_line=""
    if (( lineno > 1 )); then
      prev_line=$(sed -n "$((lineno - 1))p" "$file")
    fi

    # 若当前行或上一行含 // 注释则放行
    if [[ "$current_line" == *"//"* ]] || [[ "$prev_line" == *"//"* ]]; then
      continue
    fi

    echo "ERROR: unannotated hardcoded color at $file:$lineno"
    echo "    $current_line"
    VIOLATIONS=$((VIOLATIONS + 1))
  done < <(grep -rn -E 'Color\(0x[0-9A-Fa-f]{8}\)' "$dir" 2>/dev/null || true)
done

if (( VIOLATIONS > 0 )); then
  echo ""
  echo "Found $VIOLATIONS unannotated hardcoded Color literal(s)."
  echo "Use AppColors.* tokens, or add a // comment explaining why this domain-specific color is retained inline."
  exit 1
fi

echo "OK: no unannotated hardcoded Color literals."
exit 0
