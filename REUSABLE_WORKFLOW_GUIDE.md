# 如何在多个项目中复用iOS构建Workflow

## 📋 方案概述

使用GitHub Actions的**可复用workflow**功能，一次定义，多处使用。

## 🏗️ 架构

```
.github/workflows/
├── reusable-ios-build.yml    # 可复用workflow（核心逻辑）
└── build-and-upload.yml       # 调用者workflow（项目特定配置）
```

**优势：**
- ✅ 核心逻辑集中管理
- ✅ 多项目只需修改配置
- ✅ 统一更新混淆策略
- ✅ 减少代码重复

---

## 🚀 使用方法

### 方案1：同一仓库内的其他项目

如果你有多个iOS项目在同一个仓库的不同目录：

1. **保留可复用workflow**
   ```
   .github/workflows/reusable-ios-build.yml
   ```

2. **为每个项目创建调用者workflow**
   ```yaml
   # .github/workflows/build-project-a.yml
   name: Build Project A
   
   on:
     workflow_dispatch:
   
   jobs:
     build:
       uses: ./.github/workflows/reusable-ios-build.yml
       with:
         workspace_name: "ProjectA.xcworkspace"
         scheme_name: "ProjectA"
         bundle_id: "com.company.projecta"
         provisioning_profile_name: "ProjectA"
       secrets: inherit  # 继承所有secrets
   ```

### 方案2：不同仓库的项目

如果你的iOS项目在不同的Git仓库：

**选项A：创建中心workflow仓库**

1. **创建一个专门的workflow仓库**
   ```
   workflows-repo/
   └── .github/workflows/
       └── ios-build.yml  # 可复用workflow
   ```

2. **在其他项目中调用**
   ```yaml
   # 项目B的 .github/workflows/build.yml
   jobs:
     build:
       uses: your-org/workflows-repo/.github/workflows/ios-build.yml@main
       with:
         workspace_name: "ProjectB.xcworkspace"
         # ... 其他配置
       secrets:
         BUILD_CERTIFICATE_BASE64: ${{ secrets.BUILD_CERTIFICATE_BASE64 }}
         # ... 其他secrets
   ```

**选项B：复制可复用workflow到每个项目**

如果不想创建中心仓库，可以将`reusable-ios-build.yml`复制到每个项目。

---

## 📝 新项目配置示例

假设你有一个新项目叫"MyApp"：

### 第1步：复制文件到新项目

```bash
# 进入新项目目录
cd /path/to/MyApp

# 创建workflows目录
mkdir -p .github/workflows

# 复制可复用workflow
cp /path/to/taya/.github/workflows/reusable-ios-build.yml .github/workflows/

# 复制混淆脚本
mkdir -p scripts
cp /path/to/taya/scripts/advanced_obfuscate.py scripts/
```

### 第2步：创建调用者workflow

创建 `.github/workflows/build-and-upload.yml`：

```yaml
name: Build MyApp

on:
  workflow_dispatch:
    inputs:
      upload_to_appstore:
        description: '是否上传到App Store'
        type: choice
        options: ['true', 'false']
        default: 'true'

jobs:
  build:
    uses: ./.github/workflows/reusable-ios-build.yml
    with:
      # 👇 只需修改这些配置
      workspace_name: "MyApp.xcworkspace"
      scheme_name: "MyApp"
      bundle_id: "com.mycompany.myapp"
      provisioning_profile_name: "MyApp"
      configuration: "Release"
      upload_to_appstore: ${{ github.event.inputs.upload_to_appstore == 'true' }}
    secrets:
      BUILD_CERTIFICATE_BASE64: ${{ secrets.BUILD_CERTIFICATE_BASE64 }}
      P12_PASSWORD: ${{ secrets.P12_PASSWORD }}
      BUILD_PROVISION_PROFILE_BASE64: ${{ secrets.BUILD_PROVISION_PROFILE_BASE64 }}
      KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
      TEAM_ID: ${{ secrets.TEAM_ID }}
      APPLE_ID: ${{ secrets.APPLE_ID }}
      APP_SPECIFIC_PASSWORD: ${{ secrets.APP_SPECIFIC_PASSWORD }}
```

### 第3步：配置Secrets

在GitHub项目的Settings → Secrets中添加相同的secrets（每个项目需要自己的证书）。

### 第4步：添加ObfuscationBundle.swift到Xcode

按照`XCODE_INTEGRATION.md`的说明操作。

---

## 🔧 可自定义参数

可复用workflow支持以下参数：

| 参数 | 说明 | 必需 | 默认值 |
|-----|------|------|--------|
| `workspace_name` | Workspace文件名 | ✅ | - |
| `scheme_name` | Scheme名称 | ✅ | - |
| `bundle_id` | Bundle ID | ✅ | - |
| `provisioning_profile_name` | Profile名称 | ✅ | - |
| `configuration` | 构建配置 | ❌ | Release |
| `xcode_version` | Xcode版本 | ❌ | latest-stable |
| `upload_to_appstore` | 是否上传 | ❌ | true |
| `obfuscation_script_path` | 混淆脚本路径 | ❌ | scripts/advanced_obfuscate.py |

---

## 📂 文件结构示例

### 单一项目
```
MyApp/
├── .github/workflows/
│   ├── reusable-ios-build.yml     # 可复用workflow
│   └── build-and-upload.yml       # 调用者（配置）
├── scripts/
│   └── advanced_obfuscate.py      # 混淆脚本
└── MyApp/
    └── ObfuscationBundle.swift    # 由脚本生成
```

### 多项目（同一仓库）
```
monorepo/
├── .github/workflows/
│   ├── reusable-ios-build.yml     # 共享的可复用workflow
│   ├── build-app-a.yml            # App A配置
│   ├── build-app-b.yml            # App B配置
│   └── build-app-c.yml            # App C配置
├── AppA/
│   ├── scripts/advanced_obfuscate.py
│   └── AppA/ObfuscationBundle.swift
├── AppB/
│   ├── scripts/advanced_obfuscate.py
│   └── AppB/ObfuscationBundle.swift
└── AppC/
    ├── scripts/advanced_obfuscate.py
    └── AppC/ObfuscationBundle.swift
```

---

## 🎯 快速开始清单

新项目使用此workflow的步骤：

- [ ] 复制`reusable-ios-build.yml`到新项目
- [ ] 复制`advanced_obfuscate.py`到新项目的`scripts/`
- [ ] 创建`build-and-upload.yml`，填入项目特定配置
- [ ] 在GitHub Settings添加所需的Secrets
- [ ] 运行`python3 scripts/advanced_obfuscate.py`生成初始bundle
- [ ] 将`ObfuscationBundle.swift`添加到Xcode项目
- [ ] 测试workflow：Actions → Build and Upload → Run workflow

---

## 💡 维护建议

### 更新混淆策略
如果需要增强混淆逻辑：
1. 修改`advanced_obfuscate.py`
2. 所有项目下次构建时自动使用新逻辑

### 更新构建流程
如果需要修改构建步骤：
1. 只修改`reusable-ios-build.yml`
2. 所有使用它的项目立即生效

### 版本控制
可以给可复用workflow打tag：
```yaml
uses: your-org/workflows/.github/workflows/ios-build.yml@v1.0.0
```

---

## ❓ FAQ

**Q: 可以跨组织使用可复用workflow吗？**  
A: 可以，但需要workflow所在仓库是public，或者配置适当的访问权限。

**Q: Secrets需要在每个项目配置吗？**  
A: 是的，每个项目的证书和Profile都不同，需要单独配置。

**Q: 可以覆盖可复用workflow的某些步骤吗？**  
A: 不能直接覆盖，但可以通过输入参数来控制行为（如`obfuscation_script_path`）。

**Q: 出错如何调试？**  
A: 查看GitHub Actions的运行日志，每个步骤都有详细输出。

---

## 🎉 总结

通过这个可复用workflow：
- ✅ 新项目只需25行配置文件
- ✅ 核心逻辑集中维护
- ✅ 自动包含混淆功能
- ✅ 统一的构建标准

开始使用吧！🚀
