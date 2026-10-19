# Aurora & Organic Diffuse Background Guidelines

> **Authority Reference:** [Aceternity UI (Aceternity)](https://github.com/aceternity-ui/aceternity-ui)  
> **Role:** Principal Frontend Architect  
> **Status:** Mandatory Rule Set

---

## 1. Organic Diffuse Backgrounds via Tailwind & CSS Variables

Aurora backgrounds add subtle organic luminescence to high-craft interfaces when constrained properly. They must never overpower content or destabilize frame rates.

### 1.1. Semantic Variable Configuration
All color stops must be managed through CSS variables to ensure seamless dark mode transitions and theme cohesion:

```css
:root {
  --aurora-color-1: rgba(59, 130, 246, 0.08); /* subtle blue */
  --aurora-color-2: rgba(147, 51, 234, 0.06); /* subtle purple */
  --aurora-color-3: rgba(16, 185, 129, 0.05); /* subtle emerald */
  --aurora-color-4: rgba(244, 63, 94, 0.04);  /* subtle rose */
}

.dark {
  --aurora-color-1: rgba(59, 130, 246, 0.14);
  --aurora-color-2: rgba(147, 51, 234, 0.12);
  --aurora-color-3: rgba(16, 185, 129, 0.10);
  --aurora-color-4: rgba(244, 63, 94, 0.08);
}
```

### 1.2. DOM Construction Pattern
Aurora layers must be wrapped in a self-contained stacking context:

```html
<div class="relative min-h-screen w-full overflow-hidden bg-background">
  <!-- Aurora Background Container -->
  <div 
    aria-hidden="true" 
    class="pointer-events-none absolute inset-0 -z-10 overflow-hidden isolate"
  >
    <div 
      class="aurora-blob absolute -top-[30%] -left-[10%] h-[500px] w-[500px] rounded-full blur-[80px] will-change-transform"
      style="background: radial-gradient(circle, var(--aurora-color-1) 0%, transparent 70%);"
    ></div>
    <div 
      class="aurora-blob absolute top-[10%] -right-[15%] h-[600px] w-[600px] rounded-full blur-[100px] will-change-transform"
      style="background: radial-gradient(circle, var(--aurora-color-2) 0%, transparent 70%);"
    ></div>
  </div>

  <!-- Primary Interactive Content -->
  <main class="relative z-10">
    <!-- UI elements have undisturbed pointer interactions -->
  </main>
</div>
```

---

## 2. Layering & Non-Blocking DOM Hierarchy

Aurora elements are purely decorative and must never intercept touch or click events.

* **Mandatory Layering Classes:**
  * Must declare `pointer-events-none`.
  * Must be placed behind content using `-z-10` or `z-0` (with content container explicitly set to `relative z-10`).
  * Must use `overflow-hidden` on the parent boundary to prevent accidental horizontal scrollbar triggers.
  * Must enforce `isolate` on the background container so CSS filter blend modes do not affect the root composite plane.

---

## 3. Repaint & Blur Performance Optimization

High-radius CSS blurs (`filter: blur(100px)`) force excessive rasterization repaints if animated incorrectly.

### 3.1. Blur Ceilings
* **Maximum Blur Radius:** Do not exceed `100px` (`blur-[100px]`). Recommended range: `60px` to `80px`.
* **Prohibited:** Stacking multiple overlapping elements each with separate high CSS `blur()` values on the same coordinate. Merge gradients into a single multi-stop radial gradient instead.

### 3.2. Hardware Acceleration Discipline
* Animate **only** composite-only properties: `transform` (translation, rotation) and `opacity`.
* **Prohibited:** Animating `filter`, `blur`, `width`, `height`, or `background-position` directly in `@keyframes`.
* Apply `will-change: transform` only to the active animated blob elements.

---

## 4. Reduced Motion & Static Fallbacks

Dynamic continuous fluid motion can induce nausea.

* **Mandatory Motion-Reduce Check:**
  When `prefers-reduced-motion: reduce` is detected:
  1. Freeze all keyframe rotations and translations (`animation: none !important`).
  2. Fall back to a single stationary, soft radial gradient or subtle static CSS mesh:
  ```css
  @media (prefers-reduced-motion: reduce) {
    .aurora-blob {
      animation: none !important;
      transform: none !important;
    }
  }
  ```

---

## 5. Architectural Checklist Before Review
- [ ] Aurora container strictly applies `pointer-events-none` and `z-0` / `-z-10`.
- [ ] Color stops use CSS custom variables (`var(--aurora-...)`) with light/dark parity.
- [ ] Blur radius is clamped (`<= 100px`) and never nested.
- [ ] Keyframe animations mutate exclusively `transform` or `opacity`.
- [ ] Motion is completely paused when `prefers-reduced-motion: reduce` is enabled.
