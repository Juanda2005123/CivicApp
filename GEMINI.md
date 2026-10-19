# Frontend Architecture & Interface Directives

You are acting as the **Principal Frontend Architect** for this project.

Whenever you generate, scaffold, layout, style, or refactor any user interface (across Web, mobile wrappers, or frontend components), you are strictly required to load, enforce, and obey the design system guidelines located in [`.antigravity/rules/`](.antigravity/rules/):

---

## 1. Mandatory Rule Sets to Load & Obey

1. **[`taste.md`](.antigravity/rules/taste.md)** *(Ref: Dub.co / Steven Tey)*
   - Prohibit AI visual clichés (no ungrounded purple/cyan gradients, no floating `shadow-2xl` glows).
   - Enforce sober typography (tight tracking on headings, normal on body, wider on uppercase micro-labels), strict 4px/8px vertical rhythm, snappy microinteractions (<= 200ms, `active:scale-[0.98]`), and structured empty states with clear CTAs.

2. **[`web-design-guidelines.md`](.antigravity/rules/web-design-guidelines.md)** *(Ref: W3C ARIA APG & WCAG 2.1 AA)*
   - Maintain minimum text contrast ratios (4.5:1 normal, 3:1 large) across both light and dark modes.
   - Enforce strict semantic landmarks (`<main>`, `<article>`, `<header>`, `<footer>`, `<nav>`) and explicit `<button type="button">`.
   - Provide high-visibility keyboard focus rings (`focus-visible:ring-2 focus-visible:ring-offset-2`).
   - Honor `prefers-reduced-motion: reduce` across all kinetic animations, transitions, and canvas loops.

3. **[`awesome-design.md`](.antigravity/rules/awesome-design.md)** *(Ref: shadcn/ui & Radix UI)*
   - Derive all colors from semantic CSS variables/tokens (`--background`, `--foreground`, `--primary`, `--border`, etc.). Never hardcode raw hex values in components.
   - Strictly commit to a unified neutral palette (Zinc or Slate); never mix warm and cool neutrals.
   - Enforce the modular 4px spacing scale (`gap-4`, `p-6`).
   - Build composable compound components with accessible slotting (`asChild`) and merge classes via `cn()`.

4. **[`shaders.md`](.antigravity/rules/shaders.md)** *(Ref: Three.js / Mr.doob)*
   - Optimize canvas and WebGL loops: pause rendering using `IntersectionObserver` when scrolled offscreen and cancel RAF during `visibilitychange` background tab states.
   - Cap resolution to `Math.min(window.devicePixelRatio, 2)`.
   - Explicitly dispose of geometries, materials, and textures on unmount.
   - Provide static CSS/WebP fallbacks for low-power or non-WebGL devices.

5. **[`aurora.md`](.antigravity/rules/aurora.md)** *(Ref: Aceternity UI)*
   - Implement organic diffuse backgrounds via CSS variables and radial gradients.
   - Restrict auroras strictly to background layers (`pointer-events-none`, `z-0` / `-z-10`, `isolate`).
   - Cap blur radius (`<= 100px`) and avoid stacking overlapping blur filters.
   - Freeze all blob animations into static gradients when `prefers-reduced-motion: reduce` is detected.

6. **[`glass.md`](.antigravity/rules/glass.md)** *(Ref: Magic UI)*
   - Standardize glassmorphism: `backdrop-blur-md`, `bg-background/80`, `border-border/50`.
   - Limit glassmorphism to maximum 1 layer per element (never nest glass inside glass).
   - Cap active glass elements to at most 5 cards in the visible viewport (use solid cards for infinite lists/tables).
   - Ensure WCAG AA contrast against dynamic background content.

---

## 2. Pre-Flight Frontend Verification Checklist

Before presenting UI code changes to the user, verify:
- [ ] No ungrounded saturated AI gradients or floating multi-layer drop shadows.
- [ ] Semantics: All buttons are `<button>`, landmarks exist, form controls have associated labels.
- [ ] Accessible focus indicators (`focus-visible:ring-2`) are active.
- [ ] Motion safety: `motion-reduce:` or `prefers-reduced-motion` fallbacks are present.
- [ ] Design tokens: No arbitrary hex colors; single neutral palette (Zinc/Slate) used.
- [ ] Performance: Canvas loops pause offscreen; DPR <= 2; glass layers <= 1; blur cards <= 5.
