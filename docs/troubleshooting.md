# Troubleshooting

## It keeps asking for Screen Recording permission, but the toggle is already on

macOS stores the permission for a specific code signature. If the app was rebuilt with a different signature (for example an ad-hoc build), the old grant no longer matches. The toggle still shows as on, but it doesn't apply to the new build.

1. Reset the stale grant (this affects only TextSnap):
   ```bash
   tccutil reset ScreenCapture com.andreponce.TextSnap
   ```
2. Reinstall, which signs with the stable local certificate:
   ```bash
   ./scripts/install.sh
   ```
3. Press **⌘⇧2**, allow access when macOS asks, then quit and reopen TextSnap.

To check that the installed app uses the stable certificate:

```bash
codesign -d -r- /Applications/TextSnap.app
# designated => identifier "com.andreponce.TextSnap" and certificate leaf = H"…"
```

If it shows `cdhash H"…"` instead, the app was signed ad-hoc. Run `./scripts/setup-signing.sh`, then `./scripts/install.sh`.

## The icon flashes ⚠ and nothing is copied

- **No text found.** Vision recognized nothing in the selection. Select a bigger area or zoom in: very small text (under ~8 px tall) is hard to read.
- **Permission not active yet.** Without permission the capture contains only the wallpaper. Follow the section above.

## ⌘⇧2 does nothing

- Open the TextSnap menu. If it says **"⌘⇧2 está en uso por otra app"**, another app claimed the shortcut first. Quit that app (or change its shortcut), then reopen TextSnap.
- Check that TextSnap is running: `pgrep -lx TextSnap`. If it isn't, run `open /Applications/TextSnap.app`.
- In the meantime, **Capturar texto** in the menu does the same thing as the shortcut.

## It doesn't start at login

- Open the menu and check that **Abrir al iniciar sesión** has a checkmark.
- A dash (–) instead of a checkmark means macOS is waiting for your approval. Click the item to open **System Settings › General › Login Items & Extensions**, then allow TextSnap.

## The build fails

TextSnap needs **macOS 15+** and **Xcode 26 / Swift 6.2** or later (it uses `@concurrent` and the Swift Vision API).

```bash
swift --version             # Apple Swift version 6.2 or later
xcode-select -p             # should point inside Xcode.app
sudo xcode-select -s /Applications/Xcode.app   # if it points to CommandLineTools
```

## Reading the logs

TextSnap logs through `os.Logger` under its bundle identifier. In zsh, `log` is a shell builtin, so call the system tool by its full path:

```bash
/usr/bin/log stream --style compact --predicate 'subsystem == "com.andreponce.TextSnap"'
```

Leave that running, press **⌘⇧2**, and any capture errors show up as they happen.

## Starting from scratch

```bash
./scripts/uninstall.sh                             # app, permission, preferences
./scripts/uninstall.sh --remove-signing-identity   # also the local certificate
./scripts/install.sh
```
