# Placeholder Status

Track placeholder vs final art in the design pipeline.

## Registry Location

`docs/design/asset-registry.yaml`

## Requirements Gathering

1. Scope: All screens, specific screen, or blocking-release only
2. Output format: summary dashboard, detailed report, or both
3. Want to update any entries?

## Processing Steps

1. Load and parse asset registry
2. Calculate metrics:
   - Count by status (wireframe, placeholder, final, n/a)
   - Completion %: (final + n/a) / total * 100
   - Identify blocking_release items
3. Cross-reference with layout files in `tools/ui-preview/project/layouts/`
4. Generate status report

## Output Format

```markdown
## UI Asset Pipeline Status

**Overall Progress:** X% (Y/Z assets final)

### Summary by Status
| Status | Count | Percent |

### By Screen
| Screen | UI Status | Final | Placeholder | Wireframe | Layout JSON |

### Blocking Release
Items that must become 'final' before release

### Next Actions
Priority items based on blocking_release
```

## Registry Updates

- Add asset: Edit registry, add to screen's assets list
- Update status: Change status field
- Mark final: Set status to 'final', add final_path
