# Implement Guidance

Generate Godot implementation guidance from a layout design.

## Requirements Gathering

1. Which design? (layout JSON path or spec file path)
2. Target Godot version? (default: 4.x)
3. Script language? (GDScript or C#, default: GDScript)
4. Include state management scaffolding? (yes/no)
5. Generate as separate .tscn or embed guidance? (default: embed)

## Output Format

Generate these sections:

### Scene Structure
```
ScreenName (Control)
├── Background (TextureRect)
├── CenterContainer
│   └── VBoxContainer [separation: 16]
│       ├── TitleLabel (Label)
│       └── ButtonPrimary (TextureButton)
└── VersionLabel (Label) [anchors: bottom-right]
```

### Node Properties
- Position, Size from layout JSON
- Anchors, Margins calculated from position + resolution
- Theme overrides

### Theme Resources (.tres format)

### Signal Connections (GDScript)

### State Management (if requested)

### Asset Path Mapping Table

## Output Location

`docs/design/guidance/{screen-name}-guidance.md`
