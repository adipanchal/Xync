<p align="center">
  <img src="xync/Assets.xcassets/AppIcon.appiconset/mac_128.png" alt="Xync Logo" width="128">
</p>

<div align="center">

# Xync

**Mirror, control, and manage your Android devices wirelessly from your Mac.**

Powered by the incredible [scrcpy](https://github.com/Genymobile/scrcpy), Xync provides a beautiful, native macOS interface for managing your Android devices without touching a terminal.
</div>

## Wireless Devices
<img src="assets/previews/wireless-devices-preview.png" alt="Xync App Preview" width="800">

## Wired Devices
<img src="assets/previews/wired-devices-preview.png" alt="Xync App Preview" width="800">

## Samsung DeX
<div>
  Maynot work on every samsung devices try at your own luck!
</div>
<img src="assets/previews/samsung-dex-preview.png" alt="Xync App Preview" width="800">

## File Explorer (Beta)
<img src="assets/previews/file-explorer-preview.png" alt="Xync App Preview" width="800">

## Features
- **Wireless Mirroring**: Connect and mirror your phone over Wi-Fi with zero cable clutter. Built-in Connection Wizard makes TCP/IP setup a breeze.
- **Wired Mirroring**: Low-latency, high-performance USB mirroring for gaming or intensive tasks.
- **Samsung DeX Support**: Launch a dedicated DeX desktop environment instead of a phone mirror (requires supported Samsung device).
- **Camera Passthrough**: Use your Android phone's high-quality rear or front camera directly on your Mac.
- **Device Management**: Forget, disconnect, or connect saved devices easily with a click.
- **Native macOS UI**: Built entirely in Swift/SwiftUI with macOS design paradigms (translucency, SF Symbols, native window handling).
- **File Explorer**: Browse your Android device files directly from your Mac.

## Prerequisites

Xync uses the open-source engines `scrcpy` and `adb` under the hood. 

The **first time you open Xync**, a built-in Setup Wizard will automatically download and configure everything you need! You don't need to touch a terminal or install anything manually.

### Android Device Setup
1. Open **Settings** on your Android phone.
2. Go to **About Phone** and tap **Build Number** 7 times to enable Developer Mode.
3. Go back to Settings -> **Developer Options**.
4. Enable **USB Debugging**.
5. Connect your phone to your Mac via USB and accept the "Allow USB Debugging" prompt on your phone's screen.

### Wireless Connection Setup & Tips
To connect wirelessly, **both your Mac and Android device must be on the exact same Wi-Fi network.**

**Pro-Tip: Set a Static IP for 1-Click Connections**
By default, routers change your phone's IP address every few days, meaning you'd have to plug your USB back in to run the Connection Wizard again. To fix this and connect instantly forever:
1. Go to your Android's **Wi-Fi Settings**.
2. Tap the gear icon next to your current Wi-Fi network and look for **IP settings**.
3. Change it from **DHCP** to **Static**.
4. Use the Connection Wizard in Xync to connect one last time. From now on, you can connect from the "Saved Devices" list anytime without cables!

## Installation

1. Go to the [Releases](https://github.com/adipanchal/xync/releases) page.
2. Download the latest `Xync.dmg`.
3. Drag the **Xync** application into your `Applications` folder.

*(Note: Because this is an indie app, macOS Gatekeeper may block the first launch. Simply **Right-click** the Xync app, and choose **Open**, then click "Open" on the warning dialog to bypass this once.)*

---

**Made by [Aditya Panchal](https://github.com/adipanchal)**

*Copyright © 2026 Aditya Panchal. All rights reserved.*
