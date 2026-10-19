# Web Design & Accessibility Guidelines (WCAG 2.1 AA)

> **Authority Reference:** [W3C WAI-ARIA Authoring Practices Guide (APG)](https://github.com/w3c/aria-practices) & WCAG 2.1 Standard  
> **Role:** Principal Frontend Architect  
> **Status:** Mandatory Rule Set

---

## 1. WCAG 2.1 AA Contrast & Visual Standards

### 1.1. Minimum Contrast Ratios (Criterion 1.4.3 & 1.4.11)
* **Body & Normal Text (< 18pt / 24px or < 14pt / 18.5px bold):**
  * Minimum contrast ratio of **4.5:1** against the immediate background.
  * Light mode: Text must not be lighter than `text-neutral-600` (on white `#FFFFFF`).
  * Dark mode: Text must not be darker than `text-neutral-400` (on `#09090b` / `#000000`).
* **Large Text (>= 18pt / 24px or >= 14pt / 18.5px bold):**
  * Minimum contrast ratio of **3.0:1**.
* **UI Components & Graphical Objects:**
  * Active controls, input borders, and toggle indicators must maintain at least **3.0:1** contrast against adjacent backgrounds.
* **Non-Reliance on Color Alone (Criterion 1.4.1):**
  * Status messages (success, warning, error) must pair color with explicit text labels, semantic icons (with `aria-hidden="true"`), or distinct structural shapes.

---

## 2. Strict Semantic HTML & ARIA Architecture

Never replace native browser semantics with generic `<div>` or `<span>` elements when a standard element exists.

### 2.1. Document Landmark Structure
All layouts must provide a clear hierarchical landmark tree:
```html
<header>          <!-- Global banner / navigation header -->
  <nav aria-label="Main Navigation"> ... </nav>
</header>
<main id="main-content"> <!-- Single primary document landmark -->
  <article>       <!-- Self-contained syndicatable/reusable content -->
    <header> ... </header>
    <section aria-labelledby="section-title"> ... </section>
  </article>
</main>
<aside aria-label="Supplementary Information"> ... </aside>
<footer> ... </footer>
```

### 2.2. Interactive Controls: Buttons vs Links
* **Buttons:** Use `<button type="button">` or `<button type="submit">` for actions that trigger state changes, open dialogs, or submit forms.
  * **Prohibited:** `<div onClick={...}>` or `<a href="#" onClick={...}>`.
  * **Icon-Only Buttons:** Must always provide an accessible name via `aria-label` or visually hidden screen reader text:
    ```html
    <button type="button" aria-label="Close dialog" class="...">
      <XMarkIcon aria-hidden="true" class="w-4 h-4" />
      <span class="sr-only">Close dialog</span>
    </button>
    ```
* **Links:** Use `<a href="...">` exclusively for navigations that change URLs or document fragments. External links opening in a new tab must declare `target="_blank" rel="noopener noreferrer"` and notify screen readers (`<span class="sr-only">opens in a new tab</span>`).

### 2.3. Form Field Semantics
* Form controls must be explicitly associated with `<label>` elements via `htmlFor`/`for` and `id`.
* Helper and error descriptions must link via `aria-describedby`:
  ```html
  <label for="user-email" class="text-sm font-medium">Email address</label>
  <input
    id="user-email"
    name="email"
    type="email"
    aria-invalid={hasError ? "true" : "false"}
    aria-describedby={hasError ? "email-error" : "email-hint"}
    class="..."
  />
  <p id="email-hint" class="text-xs text-neutral-500">We will never share your email.</p>
  {hasError && <p id="email-error" role="alert" class="text-xs text-red-600">{errorMessage}</p>}
  ```

---

## 3. Accessible Focus Indicators

Custom styling must never destroy keyboard accessibility. Removing the default focus ring without an explicit, visible replacement is strictly prohibited.

* **Mandatory Focus Utility Pattern:**
  ```css
  /* Tailwind standard focus ring */
  focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-neutral-900 focus-visible:ring-offset-2 dark:focus-visible:ring-neutral-100 dark:focus-visible:ring-offset-neutral-950
  ```
* **Interaction Rules:**
  * Use `:focus-visible` rather than `:focus` to suppress focus rings on mouse/pointer clicks while preserving crisp visibility during keyboard (Tab / Shift+Tab) traversal.
  * Maintain at least 2px offset (`ring-offset-2`) or contrasting border so the ring is visible against both component and background surfaces.
  * Custom modals, draw menus, and popovers must implement focus trapping and restore focus to the triggering element upon closure.

---

## 4. Motion & Vestibular Safety (`prefers-reduced-motion`)

Fast movement, parallax scrolling, and looping animations trigger severe vestibular disorientation in sensitive users.

### 4.1. Universal Media Query Requirement
Every animation, transition, and canvas effect must honor `prefers-reduced-motion: reduce`.

### 4.2. Implementation Patterns
* **Tailwind Motion Variant:**
  Wrap all non-essential kinetic motion in `motion-safe:` or provide non-animated fallbacks with `motion-reduce:`:
  ```html
  <!-- Animated on motion-safe, static fade or stationary on motion-reduce -->
  <div class="transition-all motion-safe:duration-300 motion-safe:scale-100 motion-reduce:transition-none">
    Content
  </div>
  ```
* **CSS Implementation:**
  ```css
  @media (prefers-reduced-motion: reduce) {
    *, ::before, ::after {
      animation-duration: 0.01ms !important;
      animation-iteration-count: 1 !important;
      transition-duration: 0.01ms !important;
      scroll-behavior: auto !important;
    }
  }
  ```
* **Shaders & Canvas:**
  Background canvases must detect reduced motion settings in JavaScript:
  ```javascript
  const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (prefersReducedMotion) {
    // Render static initial frame, cancel requestAnimationFrame loop
    renderer.render(scene, camera);
  } else {
    startAnimationLoop();
  }
  ```

---

## 5. Architectural Checklist Before Review
- [ ] Text contrast meets minimum 4.5:1 (normal) or 3:1 (large) across both light and dark themes.
- [ ] Valid semantic landmarks (`<main>`, `<article>`, `<header>`, `<footer>`, `<nav>`) are used.
- [ ] All interactive non-link controls are `<button type="button">` or `<button type="submit">`.
- [ ] Focus states are distinctly defined using `focus-visible:ring-2`.
- [ ] All animations and canvas loops are completely deactivated or simplified when `prefers-reduced-motion` is active.
