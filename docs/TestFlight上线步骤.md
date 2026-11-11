# TestFlight 上线步骤（已有 p12，不需要侧载签名）

有 p12 的情况下，最省事的路线是：**Codemagic 用你的证书签名 → 直接上传 TestFlight → 手机装 TestFlight 后安装**。
不用数据线、不用每周重签、不用电脑开着续签。

---

## 开始前先确认两个东西

| 要确认 | 怎么判断 |
|---|---|
| **证书类型是 Apple Distribution** | developer.apple.com → Certificates, Identifiers & Profiles → Certificates，看那张证书标题是不是 **Apple Distribution**（老版本叫 iPhone Distribution）。如果只有 **Apple Development**，那只能装到自己电脑连着的那台设备，上不了 TestFlight |
| **有 App Store 类型的描述文件** | 同一个页面 → Profiles，类型写 **App Store**、绑定的 App ID 是 `com.personal.savingsTracker`。没有就点 + 新建一个，选证书时勾上你那张 p12 对应的证书 |

另外需要 **付费开发者账号的 App Store Connect 权限**（能进去看到「我的 App」就算有）。

---

## 第 1 步：App Store Connect 建 App 记录（5 分钟）

上传二进制之前，App Store Connect 里必须先存在这个 App，否则上传会被拒。

1. 打开 https://appstoreconnect.apple.com → **我的 App** → 左上角 **+** → **新建 App**
2. 填写：
   - 平台：**iOS**
   - 名称：`存款管家`（这个名字在 App Store 里全球唯一，被占用就加个后缀，不影响自用）
   - 主要语言：简体中文
   - **套装 ID**：选 `com.personal.savingsTracker`
     - 下拉里没有这个选项，说明 developer 后台还没建这个 App ID，先去 Identifiers 建一个
   - SKU：`savings-tracker`（随便填，不对外显示）
   - 用户访问权限：完全访问
3. 点创建。**不用**填截图、隐私政策、分类这些（内部测试用不到，等要提交审核时再说）

---

## 第 2 步：生成 App Store Connect API Key（3 分钟，只做一次）

Codemagic 靠这个 Key 上传，不用你的账号密码。

1. 还是 appstoreconnect.apple.com → **用户和访问** → **集成（Integrations）** → **App Store Connect API**
2. 点 **+** 生成新 Key：
   - 名称：`savings_key`（记住这个名字，等下要填进 `codemagic.yaml`）
   - 权限：选 **App 管理员（App Manager）**
3. 生成后点 **下载 API Key**，得到一个 `.p8` 文件 —— **这个文件只能下载一次**，丢了要重建
4. 把表格上方那两串抄下来：
   - **Issuer ID**（一串 UUID，全团队共用）
   - **Key ID**（这个 Key 自己的 10 位编号）

---

## 第 3 步：把证书交给 Codemagic（3 分钟）

1. 打开 https://codemagic.io → 你的 app → 左侧 **Settings** → **Code signing identities**
2. **iOS certificates** 里上传 `.p12`，输入导出时设的密码
3. **iOS provisioning profiles** 里上传第 1 步准备好的 `.mobileprovision`
   - 注意：描述文件必须包含你上传的那张 p12 对应的证书，否则签名会失败

---

## 第 4 步：把 API Key 交给 Codemagic（2 分钟）

1. Codemagic → 右上角头像 → **Teams** → 你的团队 → **Integrations** → **Developer Portal** 点 **Connect**
2. 填：
   - **App Store Connect API key name**：`savings_key`（要和 `codemagic.yaml` 里一致）
   - **Issuer ID**：第 2 步抄的那串
   - **Key ID**：第 2 步抄的那串
   - **API key**：上传第 2 步下的 `.p8`
3. Save

> 这个集成同时管「签名」和「上传」两件事，配好一次以后不用再动。

---

## 第 5 步：改 yaml 里的占位名

仓库里的 `codemagic.yaml` 里有一行占位：

```yaml
    integrations:
      app_store_connect: REPLACE_WITH_YOUR_KEY_NAME
```

把 `REPLACE_WITH_YOUR_KEY_NAME` 换成你在第 4 步起的名字（比如 `savings_key`），然后推上去：

```powershell
cd C:\Users\Admin1\Doubao\chats\2026-11-10\new-chat-7\savings_tracker
git add -A
git commit -m "配置 TestFlight 签名"
git push
```

> 这个 key 名字不是敏感信息，直接写在仓库里没问题（真实密钥在 Codemagic 后台，不在仓库里）。

---

## 第 6 步：跑构建（约 10 分钟）

1. Codemagic 里打开你的 app，workflow 选 **`ios-testflight`**
2. Start new build
3. 日志走到 `Publishing` 那行说明签名和上传都过了
4. 上传后 Apple 要处理几分钟到二十分钟，这期间 TestFlight 里会显示「正在处理」

这一步产物除了上传 TestFlight，也会留一个 `build/ios/ipa/*.ipa` 在 Artifacts 里，可以备用。

---

## 第 7 步：手机上装（3 分钟）

1. App Store Connect → 你的 App → **TestFlight** → 左侧 **内部测试（Internal Testing）**
2. 点 **+** 添加测试员：直接选你自己（内部测试员不需要 Apple 审核，最多 100 人）
3. iPhone 上从 App Store 装 **TestFlight**，用同一个 Apple ID 登录
4. TestFlight 里会出现「存款管家」→ 点 **安装**

装好后第一次打开 App，去设置页把目标金额、目标日期、提醒时间填好。

---

## 关于有效期（重要）

- TestFlight 构建 **90 天过期**，到期 App 会提示无法打开。到期前在 Codemagic 里再点一次构建就行，**数据不受影响**（覆盖安装，不清数据）
- 比免费侧载好在：不用数据线、不用电脑常开续签、不用每周重签
- 想一劳永逸只有上架 App Store（要过审核），自用没必要

---

## 常见卡点

| 现象 | 原因 / 处理 |
|---|---|
| 上传后一直「Missing Compliance」 | 出口合规问卷没答。已在 `ios/Runner/Info.plist` 里加了 `ITSAppUsesNonExemptEncryption = false`，重新构建一次即可 |
| `No profiles for 'com.personal.savingsTracker' were found` | Codemagic 里没上传描述文件，或描述文件和 p12 不配对 |
| `Invalid Signature / codesign failed` | p12 是 Development 证书，不是 Distribution；或描述文件是 Development 类型 |
| 上传报 `The bundle identifier is already in use` | App Store Connect 里这个 Bundle ID 已被别的团队占用 |
| 构建成功但 TestFlight 不显示 | 等 Apple 处理；或检查第 1 步的 App 记录 Bundle ID 是否完全一致（大小写也要一致） |
| `ITMS-90062` / 版本号重复 | 已用时间戳自动生成 build number，一般不会撞；若仍报，删掉旧构建再传 |

---

## 之后想加主屏幕小组件

你有付费账号，这条路是通的。还差一步：**用 Xcode 创建 Widget 扩展 target**（租 1 小时云 Mac，15 分钟）。
建好之后 `ios-testflight` 这个 workflow 会自动把小组件一起编译、一起签名、一起传 TestFlight。
步骤见 [小组件配置步骤.md](小组件配置步骤.md)。
