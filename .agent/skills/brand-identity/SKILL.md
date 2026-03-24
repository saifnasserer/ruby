---
name: brand-identity
description: Provides the single source of truth for brand guidelines, design tokens, technology choices, and voice/tone. Use this skill whenever generating UI components, styling applications, writing copy, or creating user-facing assets to ensure brand consistency.
---

# Brand Identity & Guidelines

**Brand Name:** Laapak

This skill defines the core constraints for visual design and technical implementation for the brand. You must adhere to these guidelines strictly to maintain consistency.

## Reference Documentation

Depending on the task you are performing, consult the specific resource files below. Do not guess brand elements; always read the corresponding file.

### For Visual Design & UI Styling

If you need exact colors, fonts, border radii, or spacing values, read:

👉 **[`resources/design-tokens.json`](resources/design-tokens.json)**

### For Coding & Component Implementation

If you are generating code, choosing libraries, or structuring UI components, read the technical constraints here:

👉 **[`resources/tech-stack.md`](resources/tech-stack.md)**

### For Copywriting & Content Generation

👉 **[`resources/voice-tone.md`](resources/voice-tone.md)**

---

## 💎 Finance-Grade Design System
The "Finance-Grade" style is the **primary global design system** for the entire Laapak application. It conveys trust, premium quality, and a modern financial aesthetic across all screens.

### Code Constraints:
- **Pill Design:** Use `rounded-full` for all buttons, inputs, and small interactive elements.
- **Organic Curves:** Use `rounded-[3rem]` for all main container cards, modals, and section wrappers.
- **Elevation 0:** Always use `shadow-none`.Depth is created via color and borders, not shadows.
- **Glassmorphism:** Use `bg-white/60`, `backdrop-blur-sm`, and `border-black/5` for containers.
- **Typography:** `font-black` for headers (tracking-tighter), `tracking-widest` for uppercase labels.
- **Interaction:** Use `transition-all` with `active:scale-[0.98]` and `group-hover:scale-[1.02]`.
- **Z-Index Strategy:** Explicitly layer overlapping menus using logic (e.g., `z-50` for top section, `z-10` for bottom).
