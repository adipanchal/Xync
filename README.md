# Xync 📱💻

**Mirror, control, and manage your Android devices wirelessly from your Mac.**
Powered by the incredible [scrcpy](https://github.com/Genymobile/scrcpy), Xync provides a beautiful, native macOS interface for managing your Android devices without touching a terminal.

![Xync Logo](xync/Assets.xcassets/AppIcon.appiconset/mac_512.png)

## ✨ Features
- **Wireless Mirroring**: Connect and mirror your phone over Wi-Fi with zero cable clutter. Built-in Connection Wizard makes TCP/IP setup a breeze.
- **Wired Mirroring**: Low-latency, high-performance USB mirroring for gaming or intensive tasks.
- **Samsung DeX Support**: Launch a dedicated DeX desktop environment instead of a phone mirror (requires supported Samsung device).
- **Camera Passthrough**: Use your Android phone's high-quality rear or front camera directly on your Mac.
- **Device Management**: Forget, disconnect, or connect saved devices easily with a click.
- **Native macOS UI**: Built entirely in Swift/SwiftUI with macOS design paradigms (translucency, SF Symbols, native window handling).

## 🚀 Prerequisites

Xync uses the open-source engines `scrcpy` and `adb` under the hood. 

The **first time you open Xync**, a built-in Setup Wizard will automatically download and configure everything you need! You don't need to touch a terminal or install anything manually.

### Android Device Setup
1. Open **Settings** on your Android phone.
2. Go to **About Phone** and tap **Build Number** 7 times to enable Developer Mode.
3. Go back to Settings -> **Developer Options**.
4. Enable **USB Debugging**.
5. Connect your phone to your Mac via USB and accept the "Allow USB Debugging" prompt on your phone's screen.

## 📦 Installation (Free Download)

1. Go to the [Releases](https://github.com/adipanchal/xync/releases) page.
2. Download the latest `Xync.app.zip` or `Xync.dmg`.
3. Drag the **Xync** application into your `Applications` folder.

*(Note: Because this is an indie app, macOS Gatekeeper may block the first launch. Simply **Right-click** the Xync app, and choose **Open**, then click "Open" on the warning dialog to bypass this once.)*

## 🛠️ Building From Source

If you prefer to compile Xync yourself:

1. Clone this repository:
   ```bash
   git clone https://github.com/adipanchal/xync.git
   cd xync
   ```
2. Open `xync.xcodeproj` in Xcode 15+.
3. Select your Mac as the destination.
4. Press **Cmd + R** to build and run.

### Creating a Release Version (.dmg Installer)
To generate a `.dmg` file to share with the world:
1. In Xcode, change your build target to **Any Mac (Apple Silicon, Intel)**.
2. From the Top Menu, choose **Product -> Archive**.
3. Once archived, click **Distribute App** -> **Custom** -> **Copy App**.
4. Save the `Xync.app` bundle into your `xync` project folder (right next to `create_dmg.sh`).
5. Open your terminal, navigate to the `xync` folder, and run:
   ```bash
   ./create_dmg.sh
   ```
   *(This will automatically download the `create-dmg` tool if you don't have it, and build a beautiful macOS drag-and-drop installer called `Xync.dmg`)*
6. Upload `Xync.dmg` to your GitHub Releases!

---

**Made with ❤️ by [Aditya Panchal (@adipanchal)](https://github.com/adipanchal)**

*Copyright © 2026 Aditya Panchal. All rights reserved.*
