# TextSnap

A native macOS menu bar app that copies **the text in any part of your screen**, keeping its structure.

Press **⌘⇧2**, drag over a region (same as ⌘⇧4), and the text lands on your clipboard as Markdown, with headings, bullets, numbered and nested lists, and line breaks preserved.

**Example.** Capturing a slide that has a title and eight bullet points gives you (excerpt):

```markdown
# R/W Capacity Modes - On-Demand

- Read/writes automatically scale up/down with your workloads
- No capacity planning needed (WCU / RCU)
- You're charged for reads/writes that you use in terms of RRU and WRU
- 2.5x more expensive than provisioned capacity (use with care)
```

- Runs entirely on your Mac: OCR uses Apple's Vision framework, and nothing leaves the device.
- Zero CPU while idle, no Dock icon, starts automatically at login.

---

## Requirements

| | Minimum | Check with |
| --- | --- | --- |
| macOS | 15 Sequoia | `sw_vers -productVersion` |
| Xcode | 26 (Swift 6.2) | `swift --version` |

Xcode has to be the active developer directory. If `xcode-select -p` prints a `CommandLineTools` path, run:

```bash
sudo xcode-select -s /Applications/Xcode.app
```

## Install

### 1. Get the code

```bash
git clone https://github.com/andrepg-dev/textsnap.git
cd textsnap
```

### 2. Build and install

```bash
./scripts/install.sh
```

This single command:

1. Creates a local code signing certificate named **TextSnap Local Signing** in your login keychain (only the first time; see [why](#why-a-signing-certificate)).
2. Builds the app in release mode and signs it.
3. Copies it to `/Applications` (or `~/Applications` if `/Applications` isn't writable).
4. Launches it. A viewfinder icon appears in the menu bar.

### 3. Grant Screen Recording permission (first run only)

1. Press **⌘⇧2**. macOS asks for permission to record the screen.
2. Open **System Settings › Privacy & Security › Screen & System Audio Recording** and turn on **TextSnap**.
3. Quit and reopen TextSnap (macOS applies the permission only after a restart). Either accept macOS's **Quit & Reopen** button, or run:
   ```bash
   pkill -x TextSnap; open /Applications/TextSnap.app
   ```

### 4. Done

Launch at login turns on automatically the first time the app runs, so TextSnap will be in your menu bar every time you log in.

## Use

| Action | How |
| --- | --- |
| Capture text | **⌘⇧2**, then drag over the text |
| Capture a whole window | **⌘⇧2**, then **Space**, then click the window |
| Cancel | **Esc** |
| Paste | **⌘V** anywhere |

Feedback in the menu bar:

- **Spinner**: the region was captured and the text is being read (usually under a second).
- **✓** and a short *Tink* sound: the text was copied.
- **⚠** and a *Basso* sound: no text was found (see [troubleshooting](docs/troubleshooting.md#the-icon-flashes--and-nothing-is-copied)).

## Configure

Click the menu bar icon (the menu is in Spanish):

| Menu item | What it does |
| --- | --- |
| **Capturar texto ⌘⇧2** | Starts a capture, same as the shortcut |
| **Copiar como › Markdown** | *Default.* `# Heading`, `- bullet`, `1. item`, nested lists indented 4 spaces |
| **Copiar como › Texto plano** | No Markdown syntax: headings as plain lines, `•` bullets |
| **Abrir al iniciar sesión** | Toggles launch at login. A dash (–) means macOS is waiting for your approval in Login Items |
| **Salir de TextSnap** | Quits the app (⌘Q while the menu is open) |

Settings are saved automatically. To reset them:

```bash
defaults delete com.andreponce.TextSnap
```

## Update

```bash
git pull
./scripts/install.sh
```

The signing certificate stays the same between builds, so you won't be asked for Screen Recording permission again.

## Uninstall

```bash
./scripts/uninstall.sh                             # removes app, permission and settings
./scripts/uninstall.sh --remove-signing-identity   # also deletes the local certificate
```

## Why a signing certificate?

macOS stores the Screen Recording permission for the app's **code signature**. Without a developer certificate, a build gets an *ad-hoc* signature that changes on every rebuild, so macOS treats each build as a new app. The permission toggle stays on, but the app gets asked again every time. A self-signed certificate keeps the signature identical across builds.

The certificate is valid only for code signing, lives only in your login keychain, and isn't trusted for anything else. To sign with your own Apple Development certificate instead:

```bash
CODESIGN_IDENTITY="Apple Development: Your Name (TEAMID)" ./scripts/install.sh
```

## Development

```bash
swift build          # debug build
swift test           # layout and rendering tests
./scripts/build.sh   # release .app in build/, without installing
```

```
Sources/
  TextSnapCore/   Pure layout logic: OCR lines → headings, paragraphs, lists → Markdown
  TextSnap/       macOS app: hotkey, capture, Vision OCR, clipboard, menu bar, login item
Tests/            Unit tests for TextSnapCore (Swift Testing)
scripts/          install, build, uninstall, signing setup
docs/             Architecture and troubleshooting
```

Read [docs/architecture.md](docs/architecture.md) for the design, the capture pipeline and how the layout is rebuilt.

## Known limitations

- Bold and italic aren't detected (OCR doesn't report font weight), so no `**…**` is emitted.
- Typographic characters may come back simplified, for example an en dash `–` becomes `-`.
- Tables come out as rows of text with their spacing preserved, not as Markdown tables.

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md): permission prompts that keep coming back, a shortcut that doesn't respond, login item approval, build errors and how to read the logs.
