<div align="center">

<img src="docs/icon.png" alt="Island 应用图标" width="128" height="128">

# Island

**专注灵动岛与 Apple Intelligence 的 MobileGestalt 工具，直接在设备上操作**

<p>
  <a href="https://github.com/LeVraiLunatix/island/releases/latest"><img src="https://img.shields.io/github/v/release/LeVraiLunatix/island?style=flat-square&label=release&color=6E56CF" alt="最新版本"></a>
  <a href="https://github.com/LeVraiLunatix/island/releases"><img src="https://img.shields.io/github/downloads/LeVraiLunatix/island/total?style=flat-square&label=downloads&color=6E56CF" alt="下载量"></a>
  <img src="https://img.shields.io/badge/iOS%20%7C%20iPadOS-27%20beta%201--4-000000?style=flat-square&logo=apple&logoColor=white" alt="支持平台">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Noncommercial-6E56CF?style=flat-square" alt="PolyForm 非商业许可证"></a>
</p>

<a href="https://github.com/LeVraiLunatix/island/releases/latest"><b>下载 IPA</b></a> ·
<a href="#系统要求">系统要求</a> ·
<a href="#安装">安装</a> ·
<a href="README.md">English</a>

</div>

Island 通过 `bad_query` 沙盒扩展漏洞，直接在设备上编辑 `com.apple.MobileGestalt.plist`，然后自动注销 SpringBoard。勾选需要的项目，点「Activer」即可。

> [!WARNING]
> 本项目使用私有 API 沙盒逃逸并修改系统缓存数据，仅在其针对的 iOS/iPadOS 27 beta 版本上有效。错误的取值可能破坏系统功能，严重时需要刷机恢复。请仅在你本人拥有的设备上使用。

> [!IMPORTANT]
> Island 免费、源码公开；未经授权，不得以任何形式出售本 App。

## 功能

**灵动岛** —— 选择机型子类型（iPhone 14 Pro、14 Pro Max、16 Pro、16 Pro Max 或 iPhone Air）并应用。

**Apple Intelligence** —— 在不支持的设备上强制开启美区，必要时进行设备身份仿冒。

**功能预设** —— 开关机铃声、充电限制、轻点唤醒、相机控制、Apple Pencil、操作按钮、车祸检测、息屏显示、壁纸视差、台前调度、iPad 应用兼容性、iPadOS 模式，以及内部/研究相关开关。勾选需要的，点「Activer」。

每次写入前都会自动备份原始 plist，写入后自动注销。

本项目是 [GestaltEdit](https://github.com/frs0n/GestaltEdit) 的分支，改用深色极简界面——保留完整的功能预设，但去掉了手动字段编辑器和备份库界面。

## 系统要求

- 仅支持 iOS / iPadOS 27 beta 1–4（本 App 依赖的 `bad_query` 路径穿越漏洞在 beta 4 之后已被修复）
- 设备已开启开发者模式
- 一种签名安装方式，例如 [iLoader](https://github.com/nab138/iloader)

## 安装

1. 从 [Releases](https://github.com/LeVraiLunatix/island/releases/latest) 下载 `Island.ipa`。
2. 安装 [iLoader](https://iloader.app/)，连接设备并登录 Apple ID（仅用于本地签名）。
3. 导入 IPA 完成签名安装，然后在「设置」→「通用」→「VPN 与设备管理」中信任证书。

## 致谢

- [frs0n/GestaltEdit](https://github.com/frs0n/GestaltEdit) —— 本项目分叉自此
- [Nugget](https://github.com/leminlimez/Nugget) —— 灵动岛的替代开启方式
- [FilzaSlop](https://github.com/0xjohnnydev/FilzaSlop)、[bad_query](https://github.com/forcequitOS/bad_query)、[0xJohnny](https://x.com/0xjohnny) —— 文件访问研究
- [neospring](https://github.com/rooootdev/neospring) —— 注销实现

与 Apple 及上述项目均无隶属关系。

## 许可证

[PolyForm Noncommercial License 1.0.0](LICENSE) —— 非商业用途免费；不得用于商业目的。
