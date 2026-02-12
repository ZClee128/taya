#!/bin/bash

# 动态编译混淆代码包装脚本
# 这个脚本会将所有生成的混淆文件编译成一个框架并链接到主项目

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OBFUSCATION_DIR="$PROJECT_DIR/taya"

echo "🔍 扫描混淆文件..."

# 查找所有生成的混淆文件
OBFUSCATION_FILES=$(find "$OBFUSCATION_DIR" -maxdepth 1 \
  \( -name "*Store.swift" -o \
     -name "*Controller.swift" -o \
     -name "*Manager.swift" -o \
     -name "*Service.swift" -o \
     -name "*Helper.swift" -o \
     -name "*Processor.swift" -o \
     -name "*Handler.swift" -o \
     -name "*Parser.swift" -o \
     -name "*Adapter.swift" -o \
     -name "*Mapper.swift" -o \
     -name "*Builder.swift" -o \
     -name "*Factory.swift" -o \
     -name "*Validator.swift" -o \
     -name "*Coordinator.swift" -o \
     -name "*Provider.swift" -o \
     -name "*Repository.swift" \) \
  -type f \
  ! -name "StoreView.swift" \
  ! -name "StoreManager.swift" \
  ! -name "SessionManager.swift" \
  2>/dev/null || true)

if [ -z "$OBFUSCATION_FILES" ]; then
  echo "⚠️  未找到混淆文件，跳过"
  exit 0
fi

# 统计文件数量
FILE_COUNT=$(echo "$OBFUSCATION_FILES" | wc -l | tr -d ' ')
echo "✓ 找到 $FILE_COUNT 个混淆文件"

# 创建包含所有混淆文件的单一Swift文件
COMBINED_FILE="$OBFUSCATION_DIR/ObfuscationBundle.swift"

echo "// Auto-generated obfuscation bundle" > "$COMBINED_FILE"
echo "// Generated at: $(date)" >> "$COMBINED_FILE"
echo "" >> "$COMBINED_FILE"

# 合并所有混淆文件内容
echo "$OBFUSCATION_FILES" | while read -r file; do
  if [ -f "$file" ]; then
    echo "// --- Source: $(basename "$file") ---" >> "$COMBINED_FILE"
    cat "$file" >> "$COMBINED_FILE"
    echo "" >> "$COMBINED_FILE"
  fi
done

echo "✓ 创建合并文件: ObfuscationBundle.swift"
echo "✓ 混淆代码已准备好编译"
