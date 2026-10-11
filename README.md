# TextSnap

App nativa de barra de menú para macOS: **⌘⇧2** → seleccionas una zona (igual que ⌘⇧4) → el texto queda en el portapapeles como **Markdown**, conservando títulos, viñetas, listas numeradas, anidación y saltos de línea.

## Instalar

```bash
./scripts/setup-signing.sh   # una sola vez: certificado local para firmar
./scripts/install.sh         # compila, firma, copia a /Applications y abre
```

La primera captura pide permiso de **Grabación de pantalla**. Concédelo y vuelve a abrir TextSnap.
"Abrir al iniciar sesión" se activa solo la primera vez; se puede cambiar desde el menú.

## Uso

- **⌘⇧2**: selecciona región. **Espacio** cambia a modo ventana, **Esc** cancela.
- Menú ⟶ *Copiar como*: Markdown (por defecto) o Texto plano.
- Icono ✓ + sonido = copiado. Icono ⚠ = no se encontró texto.

## Arquitectura

```
Sources/
  TextSnapCore/          Lógica pura, sin AppKit ni Vision (100% testeable)
    Model/               TextLine (entrada OCR), Document/Block (estructura), OutputFormat
    Layout/              RowAssembler → LayoutAnalyzer (títulos, párrafos, listas, anidación)
    Rendering/           MarkdownRenderer, PlainTextRenderer
  TextSnap/              Shell de macOS
    App/                 main, AppDelegate (composition root), CaptureCoordinator (pipeline)
    Capture/             screencapture -i (UI nativa), permiso de pantalla
    Recognition/         Vision RecognizeTextRequest
    System/              Hotkey Carbon, login item (SMAppService), portapapeles, preferencias
    UI/                  Menú de la barra
```

Flujo: `GlobalHotKey → CaptureCoordinator → ScreenCapturing → TextRecognizing → TextFormatter → PasteboardWriter`.
Captura y OCR van detrás de protocolos, así el pipeline se puede probar o cambiar sin tocar el resto.

### Rendimiento

- En reposo: 0% CPU. El hotkey Carbon no hace polling ni necesita permiso de Accesibilidad.
- Sin ventanas, sin Dock, sin timers. El trabajo pesado (decodificar imagen, OCR) corre fuera del hilo principal.
- El análisis de layout es una sola pasada lineal; todos los umbrales son relativos a la altura del texto, así funciona igual en Retina o capturas pequeñas.

## Tests

```bash
swift test
```

## Notas

- macOS asocia el permiso de Grabación de pantalla a la firma de la app. Una firma ad-hoc cambia en cada build y el permiso se pierde aunque el interruptor siga encendido; por eso `setup-signing.sh` crea un certificado autofirmado estable. Para usar otro: `CODESIGN_IDENTITY="Apple Development: ..." ./scripts/install.sh`.
- Si el permiso quedó atascado: `tccutil reset ScreenCapture com.andreponce.TextSnap` y vuelve a concederlo.
- El OCR no distingue negritas/cursivas, así que no se emiten `**...**`.
