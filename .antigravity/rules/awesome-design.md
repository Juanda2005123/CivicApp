# Design System & Component Architecture

> **Authority Reference:** [shadcn/ui (Radix UI + Tailwind CSS)](https://github.com/shadcn-ui/ui)  
> **Role:** Principal Frontend Architect  
> **Status:** Mandatory Rule Set

---

## 1. Token-Based Design System Architecture

Interfaces must not use arbitrary, ad-hoc hex values (`#3b82f6`, `#1e293b`) directly in component classes. All visual styles derive strictly from semantic tokens defined via CSS custom variables.

### 1.1. Core Semantic Token Mapping
All UI components map to standardized semantic tokens:

```css
:root {
  /* Surface tokens */
  --background: 0 0% 100%;
  --foreground: 240 10% 3.9%;
  --card: 0 0% 100%;
  --card-foreground: 240 10% 3.9%;
  --popover: 0 0% 100%;
  --popover-foreground: 240 10% 3.9%;

  /* Action tokens */
  --primary: 240 5.9% 10%;
  --primary-foreground: 0 0% 98%;
  --secondary: 240 4.8% 95.9%;
  --secondary-foreground: 240 5.9% 10%;
  --muted: 240 4.8% 95.9%;
  --muted-foreground: 240 3.8% 46.1%;
  --accent: 240 4.8% 95.9%;
  --accent-foreground: 240 5.9% 10%;
  --destructive: 0 84.2% 60.2%;
  --destructive-foreground: 0 0% 98%;

  /* Structural tokens */
  --border: 240 5.9% 90%;
  --input: 240 5.9% 90%;
  --ring: 240 5.9% 10%;
  --radius: 0.5rem;
}

.dark {
  --background: 240 10% 3.9%;
  --foreground: 0 0% 98%;
  --card: 240 10% 3.9%;
  --card-foreground: 0 0% 98%;
  --popover: 240 10% 3.9%;
  --popover-foreground: 0 0% 98%;
  --primary: 0 0% 98%;
  --primary-foreground: 240 5.9% 10%;
  --secondary: 240 3.7% 15.9%;
  --secondary-foreground: 0 0% 98%;
  --muted: 240 3.7% 15.9%;
  --muted-foreground: 240 5% 64.9%;
  --accent: 240 3.7% 15.9%;
  --accent-foreground: 0 0% 98%;
  --destructive: 0 62.8% 30.6%;
  --destructive-foreground: 0 0% 98%;
  --border: 240 3.7% 15.9%;
  --input: 240 3.7% 15.9%;
  --ring: 240 4.9% 83.9%;
}
```

### 1.2. Neutral Palette Discipline (Slate vs Zinc)
* Select one neutral family for the entire workspace and stick to it:
  * **Zinc (Recommended):** Modern, balanced, true industrial neutrality.
  * **Slate:** Cooler, subtle blue undertone suitable for technical documentation.
* **Strict Prohibition:** Never mix warm (Stone, Neutral) and cool (Slate, Zinc) neutrals within the same surface hierarchy.

---

## 2. Modular Spacing & Layout Rhythm

All layout composition follows strict modular increments derived from the standard 4px Tailwind scale:

| Intent | Classes | Standard Usage |
| :--- | :--- | :--- |
| **Micro-gaps** | `gap-1.5`, `gap-2` (6px - 8px) | Inside buttons, badge icons, metadata clusters |
| **Element spacing** | `gap-3`, `gap-4` (12px - 16px) | Form rows, list items, card internal groups |
| **Card padding** | `p-4` (mobile), `p-6` (desktop) | Standard dashboard cards, modals, popovers |
| **Section spacing** | `space-y-6`, `gap-6` (24px) | Between related card blocks and form sections |
| **Macro layout** | `gap-8`, `py-10` to `py-16` | Grid layouts, page boundaries, view containers |

### Container Constraints
* Avoid unbounded full-width views without maximum container wrappers.
* Content containers must enforce standard widths:
  * Forms & Settings: `max-w-2xl`
  * Dashboard / Content grids: `max-w-7xl mx-auto px-4 sm:px-6 lg:px-8`
  * Prose / Reading views: `max-w-prose` or `max-w-3xl`

---

## 3. Reusable Component Composition Patterns

### 3.1. Compound Component Pattern
Complex UI components must be broken into composable primitive blocks rather than monolithic, multi-prop behemoths.

```tsx
// Good: Composable, flexible, accessible
<Card>
  <CardHeader>
    <CardTitle>Session Monitoring</CardTitle>
    <CardDescription>Real-time telemetry and state distribution.</CardDescription>
  </CardHeader>
  <CardContent className="space-y-4">
    <TelemetryFeed />
  </CardContent>
  <CardFooter className="flex justify-between border-t border-border/40 pt-4">
    <Button variant="outline">Reset</Button>
    <Button>Apply Changes</Button>
  </CardFooter>
</Card>
```

### 3.2. Radix UI Primitives & `asChild` Slotting
* Build interactive primitives (Dialogs, Dropdowns, Tooltips, Tabs, Accordions) on unstyled Radix UI primitives (`@radix-ui/react-*`).
* Utilize the `Slot` / `asChild` pattern to delegate DOM rendering and avoid invalid nested interactive tags (`<button>` inside `<button>` or `<a>`).

### 3.3. Deterministic Class Merging (`cn` Utility)
All components accepting custom classes must resolve collisions deterministically using `clsx` and `tailwind-merge`:
```typescript
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

---

## 4. Architectural Checklist Before Review
- [ ] Direct hex colors are absent from JSX/HTML; styles use semantic CSS tokens (`bg-background`, `text-foreground`, `border-border`).
- [ ] Unified neutral palette (Zinc or Slate) without accidental palette mixing.
- [ ] Spacing adheres strictly to the modular 4px grid (`gap-4`, `p-6`).
- [ ] Components use compound architecture and slot composition (`asChild`).
- [ ] Dynamic classes are unified via the `cn()` utility.
