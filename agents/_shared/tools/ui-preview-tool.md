# UI Preview Tool Reference

**Used by:** game-uiux agent
**Description:** UI Preview server for visual design work

---

## Server Configuration

- **Endpoint:** http://localhost:8085
- **Screenshot Dir:** /tmp/ui-preview

---

## Workflow

1. **VERIFY:** GET /api/status (if fails, offer: `cd tools/ui-preview && docker compose up -d`)
2. **LOAD:** style guide + asset catalog
3. **DESIGN:** Plan positions, map assets
4. **WRITE:** tools/ui-preview/project/layouts/{name}.json (include resolution field, also update current.json)
5. **SCREENSHOT:** GET /api/screenshot?layout={name}&resolution=1920x1080
6. **VERIFY:** Read /tmp/ui-preview/screenshot.png
7. **ITERATE:** Adjust and re-screenshot until satisfied
8. **EXPORT:** Save final to docs/design/specs/{name}-layout.json

---

## API Reference

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/status` | GET | Check server (ALWAYS first) |
| `/api/screenshot?layout={name}&resolution={WxH}` | GET | Capture screenshot |
| `/api/layouts` | GET | List layouts |
| `/api/layout/{name}` | GET | Load layout |
| `/api/layout/{name}` | POST | Save layout |
| `/preview-ui?layout={name}` | GET | Interactive UI for human collaboration |

---

## Human Collaboration

When working with human:
1. Tell them: open http://localhost:8085/preview-ui?layout={name}
2. Make layout JSON changes - human sees auto-refresh (2s)
3. Human clicks "Capture for Agent" → saves to /tmp/ui-preview/screenshot.png
4. Human says "captured" → READ screenshot to see what they see

---

## Element Types

- **panel:** color, corner_radius
- **label:** text, font_size, color, align
- **button:** text, color
- **rect:** color
- **container:** children array

---

## Standards

### Accessibility
- Contrast 4.5:1
- Touch targets 44x44px minimum
- Focus indicators required
- No color-only states

### Paths
- Layouts: `tools/ui-preview/project/layouts/{name}.json`
- Specs: `docs/design/specs/{name}-spec.md`
- Screenshots: `docs/design/mockups/{name}-{res}.png`
- Flows: `docs/design/flows/{name}-flow.md`

### Resolutions
- 1920x1080 (desktop)
- 1280x720 (tablet)
- 720x1280 (mobile)

---

## Tool Restrictions

**Allowed:** UI Preview Tool, local filesystem, asset catalog, NAS (/mnt/nas/WGStudios/DevAssets)

**Prohibited:** External cloud services, third-party SaaS, external image APIs
