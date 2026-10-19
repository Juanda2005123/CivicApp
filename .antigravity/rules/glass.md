# Glassmorphism & Translucency Performance Standards

> **Authority Reference:** [Magic UI (Magic UI Design)](https://github.com/magicuidesign/magicui)  
> **Role:** Principal Frontend Architect  
> **Status:** Mandatory Rule Set

---

## 1. Standardized Tailwind Glass Tokens

Backdrop filtering produces sophisticated glassmorphism effects, but requires strict optical balancing to prevent unreadable text or washed-out backgrounds.

### 1.1. Core Glassmorphic Formula
Every frosted glass element must adhere to the standardized three-token composite:

```html
<div class="rounded-xl border border-border/50 bg-background/80 backdrop-blur-md shadow-sm">
  <!-- Content -->
</div>
```

* **Backdrop Blur Token:** `backdrop-blur-md` (12px blur) or `backdrop-blur-sm` (4px blur). Avoid `backdrop-blur-2xl` or `backdrop-blur-3xl` which trigger excessive GPU compositor passes.
* **Translucent Surface Fill:**
  * Light theme: `bg-white/80` or `bg-background/80`.
  * Dark theme: `bg-neutral-950/80` or `bg-background/80`.
  * Never drop below `70%` alpha opacity on containers holding small text to ensure WCAG 2.1 AA text contrast compliance against variable backgrounds.
* **Border Definition:**
  * Must feature a subtle contrasting border (`border border-border/50` or `border-white/10 dark:border-white/5`).
  * Optional interior highlight reflection: `shadow-[inset_0_1px_0_0_rgba(255,255,255,0.1)]`.

---

## 2. Critical Performance Constraints

`backdrop-filter` is one of the most GPU-intensive CSS operations. The browser must capture pixels behind the element, apply an expensive Gaussian blur kernel, and composite it on every frame during scrolling.

### 2.1. Maximum 1 Layer of Glassmorphism per Element
* **Strict Prohibition:** Never nest a glass element inside another glass element.
  * *Bad:* A `backdrop-blur-md` card placed inside a `backdrop-blur-lg` sidebar or modal.
  * *Good:* If the parent container is glass, internal children must use solid or flat transparent fills (`bg-muted/50`, `bg-card`).

### 2.2. Viewport Density Cap (Maximum 5 Active Blur Cards)
* In any visible viewport, there must be **no more than 5 elements** with active `backdrop-filter` running simultaneously.
* **Virtualization & Grid Lists:**
  * In long data tables, feed cards, or infinite lists, **do not** apply `backdrop-blur-*` to repeated row/card items.
  * Use solid semantic surfaces (`bg-card border border-border`) for repeated items, reserving glassmorphism strictly for fixed headers, floating navigation bars, or high-priority modals.

---

## 3. Graceful Fallbacks & Browser Support

Backdrop filters can fail or stutter on older devices, power-saving profiles, or non-supporting browsers.

### 3.1. Progressive Enhancement via `@supports`
Provide a solid fallback when `backdrop-filter` is unsupported:

```css
.glass-panel {
  /* Solid fallback for older engines */
  background-color: hsl(var(--background));
  border: 1px solid hsl(var(--border));
}

@supports (backdrop-filter: blur(1px)) or (-webkit-backdrop-filter: blur(1px)) {
  .glass-panel {
    background-color: hsl(var(--background) / 0.8);
    backdrop-filter: blur(12px);
    -webkit-backdrop-filter: blur(12px);
    border: 1px solid hsl(var(--border) / 0.5);
  }
}
```

### 3.2. Contrast Safety Over Dynamic Media
If a glass card sits on top of a dynamic canvas, video, or high-contrast image, verify readability:
* When in doubt, add an underlying subtle gradient scrim (`bg-gradient-to-b from-background/90 via-background/70 to-background/90`) before applying the glass blur.

---

## 4. Architectural Checklist Before Review
- [ ] Uses the standardized formula: `backdrop-blur-md`, `bg-background/80`, `border-border/50`.
- [ ] No nested glass elements (strictly 1 layer of backdrop filter per branch).
- [ ] Maximum 5 glass cards visible simultaneously in the viewport.
- [ ] Long scrollable lists and data grids use solid cards instead of glass.
- [ ] Legibility and WCAG AA contrast are maintained regardless of what moves behind the glass.
