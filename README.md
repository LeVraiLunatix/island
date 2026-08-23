<div align="center">

<img src="docs/icon.png" alt="Island app icon" width="128" height="128">

# Island

**A MobileGestalt utility focused on Dynamic Island and Apple Intelligence, on-device**

<p>
  <a href="https://github.com/LeVraiLunatix/island/releases/latest"><img src="https://img.shields.io/github/v/release/LeVraiLunatix/island?style=flat-square&label=release&color=6E56CF" alt="Latest release"></a>
  <a href="https://github.com/LeVraiLunatix/island/releases"><img src="https://img.shields.io/github/downloads/LeVraiLunatix/island/total?style=flat-square&label=downloads&color=6E56CF" alt="Downloads"></a>
  <img src="https://img.shields.io/badge/iOS%20%7C%20iPadOS-27%20beta%201--4-000000?style=flat-square&logo=apple&logoColor=white" alt="Platform">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Noncommercial-6E56CF?style=flat-square" alt="PolyForm Noncommercial License"></a>
</p>

<a href="https://github.com/LeVraiLunatix/island/releases/latest"><b>Download IPA</b></a> ·
<a href="#requirements">Requirements</a> ·
<a href="#install">Install</a> ·
<a href="README.zh-CN.md">简体中文</a>

</div>

Island edits `com.apple.MobileGestalt.plist` on-device using the `bad_query` sandbox-extension exploit, then respring's SpringBoard. Pick what you want, tap Activer.

> [!WARNING]
> This app uses a private-API sandbox escape and modifies system cache data. It only works on the exact iOS/iPadOS 27 beta builds it targets, and writing bad values can break system features or require restoring the device. Use only on devices you own.

> [!IMPORTANT]
> Island is free and its source is public. Without authorization, you may not sell it.

## What it does

**Dynamic Island** — pick a subtype (iPhone 14 Pro, 14 Pro Max, 16 Pro, 16 Pro Max, or iPhone Air) and apply it.

**Apple Intelligence** — force-enable the US region on unsupported hardware, with device identity spoofing when required.

**Capability presets** — boot chime, charge limit, tap to wake, Camera Control, Apple Pencil, Action Button, Collision SOS, Always-On Display, wallpaper parallax, Stage Manager, iPad app compatibility, iPadOS mode, and internal/research flags. Tick what you want, tap Activer.

**Wallpaper library** — browse the [Cowabunga](https://cowabun.ga/wallpapers) `.tendies` wallpaper catalog in-app and hand a pick off to [Pocket Poster](https://cowabun.ga) for installation. Island only fetches the catalog and opens the `pocketposter://` URL scheme — it does not write wallpaper data itself.

Island backs up the original plist before every write, then respring's automatically.

This is a fork of [GestaltEdit](https://github.com/frs0n/GestaltEdit) restyled around a dark, minimal UI — it keeps the full tweak catalog but drops the manual field editor and backup-library screens.

## Requirements

- iOS / iPadOS 27 beta 1–4 only (the `bad_query` path traversal this app relies on was patched after beta 4)
- Developer Mode enabled
- A signing tool such as [iLoader](https://github.com/nab138/iloader)

## Install

1. Download `Island.ipa` from [Releases](https://github.com/LeVraiLunatix/island/releases/latest).
2. Install [iLoader](https://iloader.app/), connect your device, and sign in with your Apple ID (used only for local signing).
3. Import the IPA to sign and install it, then trust the certificate under Settings → General → VPN & Device Management.

## Credits

- [frs0n/GestaltEdit](https://github.com/frs0n/GestaltEdit) — the app this project is forked from
- [Nugget](https://github.com/leminlimez/Nugget) — the alternate Dynamic Island enable method
- [FilzaSlop](https://github.com/0xjohnnydev/FilzaSlop), [bad_query](https://github.com/forcequitOS/bad_query), [0xJohnny](https://x.com/0xjohnny) — file access research
- [neospring](https://github.com/rooootdev/neospring) — respring implementation
- [Cowabunga](https://cowabun.ga) and the [nugget-wallpapers](https://github.com/SerStars/nugget-wallpapers) catalog — wallpaper library and Pocket Poster install handoff

Not affiliated with Apple or the projects above.

## License

[PolyForm Noncommercial License 1.0.0](LICENSE) — free for noncommercial use; commercial use is not permitted.
