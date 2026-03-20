# Design System Documentation: ApoBasi Experience

## 1. Overview & Creative North Star

### The Creative North Star: "The Guardian’s Compass"
The design system for ApoBasi is built upon the concept of **The Guardian’s Compass**. It transcends basic utility to become an authoritative yet gentle guide for parents. We move away from the "clunky utility" feel often found in tracking apps, opting instead for a **High-End Editorial** aesthetic.

This system breaks the rigid, templated grid through:
*   **Intentional Asymmetry:** Strategic use of whitespace and off-center alignments to guide the eye toward critical safety updates.
*   **Layered Surfaces:** A departure from flat containers toward a physical sense of depth, suggesting a secure, multi-layered environment.
*   **Authoritative Typography:** Using a sophisticated mix of sans-serifs that feel both technical and human.

The goal is to provide a sense of "Calm Security"—where the UI feels as reliable as a luxury timepiece and as intuitive as a handwritten note.

---

## 2. Colors

Our palette is engineered to balance the high-energy "Alert" nature of tracking with a "Trust" baseline.

### The "No-Line" Rule
**Explicit Instruction:** Designers are prohibited from using 1px solid borders to section content. Boundaries must be defined solely through background shifts. For example, a card using `surface-container-highest` should sit on a `surface` background. If an element feels "lost," increase the tonal contrast between layers rather than adding a stroke.

### Surface Hierarchy & Nesting
Treat the UI as a physical stack of premium materials.
*   **Base:** `surface` (#f8f9ff)
*   **De-emphasized zones:** `surface-container-low` (#eff4ff)
*   **Interactive/Primary Cards:** `surface-container-highest` (#d3e4fe)
*   **Floating Elements:** `surface-container-lowest` (#ffffff)

### The "Glass & Gradient" Rule
To elevate beyond the "standard blue app," use **Glassmorphism** for floating action buttons or map overlays. Apply a `surface-tint` with 60% opacity and a 20px backdrop blur. 
*   **Signature Textures:** Main CTAs should not be flat. Use a subtle linear gradient from `primary` (#004ac6) to `primary-container` (#2563eb) at a 135-degree angle to provide "visual soul."

---

## 3. Typography

The typographic system uses a "Dual-Tone" approach to separate data from emotion.

| Level | Token | Font Family | Size | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **Display** | `display-lg` | Manrope | 3.5rem | Hero status (e.g., "Arrived Safely") |
| **Headline** | `headline-md`| Manrope | 1.75rem | Major section headers |
| **Title** | `title-lg` | Inter | 1.375rem | Card titles, name of child |
| **Body** | `body-lg` | Inter | 1rem | Primary parent communication |
| **Label** | `label-md` | Inter | 0.75rem | Status badges and micro-data |

**Editorial Intent:** Manrope provides a geometric, modern warmth for high-level "moments," while Inter handles the high-density tracking data with clinical precision.

---

## 4. Elevation & Depth

### The Layering Principle
Depth is achieved through **Tonal Layering**. Place a `surface-container-lowest` (#ffffff) card atop a `surface-container-low` (#eff4ff) section. This creates a soft, natural lift that mimics fine stationery.

### Ambient Shadows
For elements that truly float (like the "Track Live" button or Map Markers), use **Ambient Shadows**:
*   **Blur:** 24px to 40px.
*   **Opacity:** 4%–8%.
*   **Color:** Use a tinted version of `on-surface` (#0b1c30) rather than pure black to keep the shadows feeling "airy."

### The "Ghost Border" Fallback
If accessibility requires a container boundary, use a **Ghost Border**: the `outline-variant` token at 15% opacity. Never use 100% opaque lines.

---

## 5. Components

### Buttons
*   **Primary:** Gradient fill (`primary` to `primary-container`), `xl` (1.5rem) rounded corners. Use `on-primary` for text.
*   **Secondary:** `surface-container-highest` background, no border, `primary` colored text.
*   **Ghost:** Transparent background, `primary` text, no border.

### Chips (Status Badges)
*   **Safety Status:** Use `tertiary-container` for "On Bus" and `error-container` for "Delay." 
*   **Shape:** `full` (pill) roundedness. 
*   **Detail:** Add a 4px dot of the `on-tertiary-fixed` color next to the text for a "live signal" feel.

### Input Fields
*   **Styling:** `surface-container-lowest` fill. 
*   **Focus:** Instead of a heavy border, use a 2px outer glow of `primary` at 20% opacity.
*   **Corners:** `md` (0.75rem).

### Maps & Tracking
*   **Custom Markers:** Use `primary` for the bus icon with a `white` halo and an Ambient Shadow.
*   **Bottom Sheets:** Use `xl` corner radius for the top edges and a `surface-container-low` drag handle.

### Lists & Cards
*   **The No-Divider Rule:** Forbid 1px dividers between list items. Separate content using `spacing-6` (1.5rem) or by alternating background tones between `surface-container-lowest` and `surface-container-low`.

---

## 6. Do's and Don'ts

### Do
*   **Do** use asymmetrical margins (e.g., more padding on the left than the right) for headline elements to create an editorial feel.
*   **Do** nest containers (Highest on top of Low) to show hierarchy.
*   **Do** use `manrope` for any text that is meant to reassure the parent.

### Don't
*   **Don't** use 1px solid black or grey borders. This instantly "cheapens" the high-end feel.
*   **Don't** use standard drop shadows with high opacity.
*   **Don't** cram information. If a screen feels full, use the Spacing Scale (`10` or `12`) to force breathing room.
*   **Don't** use "Alert Red" (#ff0000). Always use the `error` token (#ba1a1a) for a more professional, sophisticated warning.