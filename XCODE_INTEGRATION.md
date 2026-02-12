# 如何将 ObfuscationBundle.swift 添加到 Xcode 项目

## 📌 重要说明

**ObfuscationBundle.swift** 是一个包含所有混淆代码的单一文件。它会在每次CI构建时被重新生成，内容完全不同，但文件名保持不变。

## 🎯 操作步骤

### 方法1：通过 Xcode 添加（推荐）

1. **打开 Xcode 项目**
   ```bash
   open taya.xcworkspace
   ```

2. **在 Project Navigator 中右键点击 `taya` 文件夹**
   - 选择 "Add Files to 'taya'..."

3. **选择 ObfuscationBundle.swift 文件**
   - 导航到: `/Users/lizhicong/Desktop/海外/Taya/源码/taya/taya/ObfuscationBundle.swift`
   - ✅ **勾选** "Copy items if needed" (不要勾选，因为文件已经在项目目录中)
   - ✅ **勾选** "Add to targets" → 选择 `taya`
   - 点击 "Add"

4. **验证文件已添加**
   - 在 Project Navigator 中应该能看到 `ObfuscationBundle.swift`
   - 点击文件，在右侧 File Inspector 中检查 "Target Membership" 是否勾选了 `taya`

### 方法2：手动修改 project.pbxproj（高级）

如果你熟悉Xcode项目文件格式，可以直接修改，但**不推荐**，容易出错。

---

## ✅ 验证是否生效

### 本地构建测试

```bash
# 清理项目
xcodebuild -workspace taya.xcworkspace -scheme taya clean

# 构建（不签名）
xcodebuild -workspace taya.xcworkspace \
  -scheme taya \
  -configuration Release \
  build \
  CODE_SIGNING_ALLOWED=NO
```

**预期结果：**
```
✓ Build succeeded
```

如果看到编译错误提到 `ObfuscationBundle.swift` 中的类，说明文件已成功包含在构建中。

---

## 🔄 CI/CD 中的工作流程

一旦你将 `ObfuscationBundle.swift` 添加到 Xcode 项目：

1. **GitHub Actions** 运行混淆脚本
   ```bash
   python3 scripts/advanced_obfuscate.py
   ```

2. **脚本覆盖** `ObfuscationBundle.swift` 文件内容
   - 文件名不变
   - 内容完全不同（12-20个随机类）

3. **Xcode 构建** 使用新内容编译
   - 因为文件已在项目中，Xcode 自动检测内容变化
   - 编译新的混淆代码

4. **结果：** 每次构建的二进制签名都不同 ✓

---

## 📝 .gitignore 配置

**重要：** `ObfuscationBundle.swift` 应该被添加到 `.gitignore`，不要提交到仓库！

已经在 `.gitignore` 中配置：
```gitignore
# Generated obfuscation files
taya/ObfuscationBundle.swift
```

但是 **Xcode 项目引用** 应该提交到仓库：
- ✅ 提交 `taya.xcodeproj/project.pbxproj`（包含文件引用）
- ❌ 不提交 `taya/ObfuscationBundle.swift`（实际文件内容）

这样：
- 本地开发时，文件不存在也不影响（Xcode会显示黄色警告但可以忽略）
- CI构建时，脚本会生成新文件，然后正常编译

---

## 🚨 常见问题

### Q1: ObfuscationBundle.swift 在 Xcode 中显示红色/找不到文件
**A:** 正常现象！在本地开发时，这个文件不应该存在。只有在CI构建时才会生成。你可以：
- 运行一次 `python3 scripts/advanced_obfuscate.py` 生成文件用于测试
- 或者忽略这个警告

### Q2: 构建时报错找不到 ObfuscationBundle.swift
**A:** 这说明文件没有被添加到 Xcode 项目的编译目标中。按照上面的步骤重新添加。

### Q3: 每次本地pull代码后，ObfuscationBundle.swift都消失
**A:** 正常！因为它在 `.gitignore` 中。如果需要本地测试，运行混淆脚本重新生成。

### Q4: CI构建失败，提示 ObfuscationBundle.swift 相关错误
**A:** 检查：
1. GitHub Actions workflow 中是否有运行 `python3 scripts/advanced_obfuscate.py`
2. 检查CI日志，确认 "ObfuscationBundle.swift 生成成功"
3. 确认文件已正确添加到 Xcode 项目

---

## 🎯 完整检查清单

在提交代码前，确保：

- [ ] `ObfuscationBundle.swift` 已添加到 Xcode 项目（但不在 git 中）
- [ ] `.gitignore` 包含 `taya/ObfuscationBundle.swift`
- [ ] `taya.xcodeproj/project.pbxproj` 包含对 `ObfuscationBundle.swift` 的引用
- [ ] GitHub Actions workflow 包含混淆生成步骤
- [ ] 本地测试构建成功

---

## 📞 需要帮助？

如果遇到问题：
1. 运行 `python3 scripts/advanced_obfuscate.py` 查看生成过程
2. 检查 Xcode 的 Build Phases → Compile Sources 中是否包含 `ObfuscationBundle.swift`
3. 查看CI构建日志中的混淆生成步骤
