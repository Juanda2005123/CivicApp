# Shaders, Canvas & WebGL Performance Standards

> **Authority Reference:** [Three.js (Mr.doob)](https://github.com/mrdoob/three.js)  
> **Role:** Principal Frontend Architect  
> **Status:** Mandatory Rule Set

---

## 1. Canvas, GLSL & Three.js Architecture

Canvas rendering brings heavy computational requirements to client hardware. When integrating Three.js, raw WebGL, or custom GLSL shaders, maintain strict lifecycle discipline.

### 1.1. Lifecycle & Resource Disposal
Never let geometries, textures, or materials leak in memory across re-renders or view navigations.
* **Mandatory Cleanup Routine:**
  ```javascript
  function disposeThreeScene(renderer, scene) {
    scene.traverse((object) => {
      if (!object.isMesh) return;
      if (object.geometry) {
        object.geometry.dispose();
      }
      if (object.material) {
        if (Array.isArray(object.material)) {
          object.material.forEach((mat) => cleanMaterial(mat));
        } else {
          cleanMaterial(object.material);
        }
      }
    });
    renderer.dispose();
    renderer.forceContextLoss();
  }

  function cleanMaterial(material) {
    material.dispose();
    for (const key of Object.keys(material)) {
      const value = material[key];
      if (value && typeof value === 'object' && 'minFilter' in value) {
        value.dispose(); // Texture disposal
      }
    }
  }
  ```

### 1.2. GLSL Precision & Mobile Compatibility
* Explicitly declare floating-point precision at the top of fragment shaders:
  ```glsl
  #ifdef GL_ES
  precision mediump float;
  #endif
  ```
  * Use `mediump` as standard. Only use `highp` if mathematical artifacts occur in matrix calculations, as `highp` drastically degrades mobile GPU performance.
* Minimize branching (`if/else`) inside fragment shaders. Use `step()`, `smoothstep()`, and `mix()` for mathematical conditional interpolation.

---

## 2. Render Cycle Optimization (Loop Pausing)

Unconstrained `requestAnimationFrame` loops draining battery while scrolled out of the viewport or on background tabs are strictly prohibited.

### 2.1. IntersectionObserver Integration
Always bind the animation loop to an `IntersectionObserver`:
```javascript
let isVisible = true;
let animationFrameId = null;

const observer = new IntersectionObserver(([entry]) => {
  isVisible = entry.isIntersecting;
  if (isVisible) {
    if (!animationFrameId) renderLoop();
  } else {
    if (animationFrameId) {
      cancelAnimationFrame(animationFrameId);
      animationFrameId = null;
    }
  }
}, { threshold: 0.05 });

observer.observe(canvasElement);

// Tab visibility listener
document.addEventListener('visibilitychange', () => {
  if (document.hidden && animationFrameId) {
    cancelAnimationFrame(animationFrameId);
    animationFrameId = null;
  } else if (!document.hidden && isVisible && !animationFrameId) {
    renderLoop();
  }
});
```

### 2.2. Demand-Driven Rendering
If the scene contains no continuous background flow and only reacts to user interaction (e.g. 3D card tilt, model rotation on drag):
* **Do NOT run an active RAF loop.**
* Call `renderer.render(scene, camera)` exclusively inside event listeners (pointermove, wheel, resize).

---

## 3. Resolution & Pixel Ratio Caps

High-DPI displays (Retina, 3x mobile displays) will render 9x pixels on unconstrained canvasses, leading to immediate thermal throttling and dropped frames.

* **Mandatory DPR Cap (Maximum 2.0):**
  ```javascript
  const dpr = Math.min(window.devicePixelRatio || 1, 2.0);
  renderer.setPixelRatio(dpr);
  renderer.setSize(containerWidth, containerHeight, false);
  ```
* For mobile devices or mid-tier hardware, cap DPR at `1.5` or `1.0`.

---

## 4. Hardware Detection & Static Fallbacks

Never assume WebGL2 or high-power discrete GPU availability.

### 4.1. WebGL Support Verification
Verify WebGL context before initializing the engine:
```javascript
function isWebGLAvailable() {
  try {
    const canvas = document.createElement('canvas');
    return !!(window.WebGLRenderingContext && 
      (canvas.getContext('webgl') || canvas.getContext('experimental-webgl')));
  } catch (e) {
    return false;
  }
}
```

### 4.2. Low-Power & Battery Fallback
* When WebGL fails or low-power mode is active:
  * Mount a static, pre-rendered WebP / SVG / CSS gradient fallback.
  * Provide `aria-hidden="true"` to prevent canvas artifacts from cluttering screen readers.
  * Render an accessible DOM explanation if the canvas represents data visualization.

---

## 5. Architectural Checklist Before Review
- [ ] Explicit memory cleanup (`dispose()` for geometries, materials, textures) on unmount.
- [ ] Animation loop suspends via `IntersectionObserver` when scrolled offscreen.
- [ ] Animation loop suspends when browser tab is inactive (`visibilitychange`).
- [ ] Pixel ratio is strictly clamped: `Math.min(window.devicePixelRatio, 2)`.
- [ ] Static CSS/image fallback is provided for non-WebGL environments.
