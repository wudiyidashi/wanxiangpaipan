# Qimen card background provenance

- Asset: `qimen_background.png`
- Generated: 2026-07-28
- Tool: local `codex-image` CLI
- Mode: `generate`, Images API transport
- Model: `gpt-image-2`
- Source images: none
- Output: PNG, 1024 x 1536, SHA-256
  `610B2A284B27D79E85A3C239E1A0976302E6D5B5900EB0777943219C705D7C7D`

Prompt:

> Warm daylight overhead photograph of a traditional Chinese Qimen Dunjia
> nine-palace divination board laid on pale rice paper, with a clearly visible
> three-by-three Luo Shu grid, compass ring, carved wooden tokens and restrained
> jade green plus vermilion accents. Place the most recognizable board details
> toward the center-right and lower half so an app card title remains legible at
> upper left. Quiet refined real material texture, crisp inspectable details,
> balanced neutral colors, full-frame composition suitable for a mobile
> application card background. No readable text, no letters, no logo, no
> watermark, no people, no dark vignette, no blur, no gradient, no fantasy glow.

The API returned a portrait image despite the requested square size. The image
is kept at its native aspect ratio and consumed with `BoxFit.cover`; it is not
stretched or re-encoded, preserving the API output bytes and recorded SHA-256.
The asset is newly model-generated for this project and does not incorporate an
external source image.
