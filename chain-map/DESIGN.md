# Chain Map Design System

This document defines the visual direction for Chain Map and how Liquid Glass
is applied in the interface. The goal is a modern, calm UI that keeps map
content legible while making chain control status immediately understandable.

## Visual principles
- Clarity first: the map remains the primary surface.
- Depth with restraint: glass layers should add hierarchy, not noise.
- Trust through legibility: emphasize data freshness and source attribution.
- Calm urgency: warnings are clear, never alarmist or chaotic.

## Layout
- Full-bleed map as the base layer.
- Glass overlays for primary controls (search, filters, status chips).
- Bottom sheet or compact panel for details and road segments.
- Keep critical map content visible; overlays should float and avoid wide bars.

## Liquid Glass usage
- Use `UIVisualEffectView` with `UIGlassEffect` for primary overlays.
- Keep glass surfaces modest in count to protect performance.
- Rounded corners are required on glass surfaces.
- Favor soft tints that pick up nearby colors without overpowering them.

### Suggested component shapes
- Status chips: small rounded pills with subtle glass tint.
- Floating panel: large rounded rectangle, medium glass tint.
- Buttons: glass-backed with clear labels and a focused hit area.

## Color and status
Use semantic colors for status and keep the map neutral:
- Clear: green
- Restrictions: amber/orange
- Closed: red
- Unknown/stale: gray

Avoid bright, saturated backgrounds behind text; use a glass tint and outline to
keep contrast strong.

## Typography
- Use SF Pro for all text (system default).
- Status and location labels should be short and scannable.
- Use dynamic type; avoid truncation in critical status labels.

## Motion
- Animate overlay entrances with a gentle scale + fade.
- Use subtle material changes on touch (glass becomes slightly more opaque).
- Avoid large, bouncy motion that distracts from map context.

## Accessibility
- Ensure sufficient contrast between text and glass surfaces.
- Support dynamic type and VoiceOver labels for all status indicators.
- Provide clear focus rings for keyboard and pointer interactions when relevant.
