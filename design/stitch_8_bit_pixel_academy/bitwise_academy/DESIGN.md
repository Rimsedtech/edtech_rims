# Design System Documentation

## 1. Overview & Creative North Star

### The Creative North Star: "Neo-Arcade Editorial"
This design system rejects the "toy-like" aesthetic of standard gamification in favor of a sophisticated, high-end editorial approach to 8-bit nostalgia. We are building a "Digital Arcade Gallery"—an experience that feels like a premium collector’s edition instruction manual brought to life. 

By blending rigid, pixel-perfect geometry with luxurious tonal layering and intentional asymmetry, we move beyond the "template" look. This system treats the 8-bit aesthetic as a high-art constraint, utilizing the `0px` border-radius scale to create a "Chunky Brutalist" layout that is both authoritative and playful. We utilize overlapping containers and dramatic typography scales to ensure the ed-tech experience feels curated, not cluttered.

---

## 2. Colors

The palette is rooted in vibrant, high-contrast gaming archetypes, recontextualized through a professional Material Design framework. 

### The "No-Line" Rule
**Explicit Instruction:** 1px solid borders are strictly prohibited for sectioning. Structural boundaries must be defined solely through background color shifts. For example, a `surface-container-low` section should sit directly against a `surface` background. Use the 2px/4px block-step technique only for decorative "pixel-art" accents or primary interaction affordances, never for simple layout partitioning.

### Surface Hierarchy & Nesting
Instead of a flat grid, treat the UI as stacked physical layers.
*   **Base:** `surface` (#fbf8fb)
*   **Level 1 (Sections):** `surface-container-low` (#f6f3f5)
*   **Level 2 (Cards):** `surface-container-highest` (#e4e2e4)
*   **Level 3 (Interactive):** `primary-container` (#3a4460)

### The "Glass & Gradient" Rule
To elevate the 8-bit look to a "premium" tier, floating elements (such as modals or high-level HUDs) should utilize **Glassmorphism**. Use semi-transparent `surface` colors with a 12px-20px backdrop-blur. 

### Signature Textures
Apply subtle linear gradients (e.g., `primary` #242e48 to `primary-container` #3a4460) on main CTAs and Hero progress bars. This adds "visual soul" and a CRT-phosphor glow that flat colors lack.

---

## 3. Typography

The typography strategy creates a high-contrast tension between the blocky "Press Start 2P" and the condensed, legible "VT323."

*   **Display & Headline (Press Start 2P):** Used for "Hero" moments, level titles, and major rewards. This font is a decorative powerhouse; use it sparingly to maintain its impact. 
*   **Title & Body (VT323):** This is our workhorse. Its tall, condensed nature allows for high-density information without sacrificing the retro character. 
*   **Space Grotesk (Administrative):** Used for micro-labels and complex data where accessibility is paramount.

| Level | Token | Font | Size |
| :--- | :--- | :--- | :--- |
| **Display-LG** | `display-lg` | Press Start 2P | 3.5rem |
| **Headline-MD** | `headline-md` | Press Start 2P | 1.75rem |
| **Body-LG** | `body-lg` | VT323 | 1.125rem |
| **Label-MD** | `label-md` | VT323 | 0.875rem |

---

## 4. Elevation & Depth

### The Layering Principle
Depth is achieved by stacking the `surface-container` tiers. Place a `surface-container-lowest` card on a `surface-container-low` section to create a soft, natural lift.

### Ambient Shadows
For "floating" pixel elements, shadows must be extra-diffused. 
*   **Shadow Color:** A tinted version of `on-surface` (#1b1b1d) at 6% opacity.
*   **Style:** No blur for the 8-bit "hard shadow" (offset 4px/4px), but for "High-End" elevation, use a large 32px blur to create an ambient glow effect that softens the rigid edges of the pixels.

### The "Ghost Border" Fallback
If a border is required for accessibility, use a **Ghost Border**: the `outline-variant` (#c6c6ce) at 15% opacity. Never use 100% opaque, high-contrast borders for layout.

---

## 5. Components

### Buttons (The "Chunky" Standard)
*   **Primary:** Background `secondary` (#3e6a00), text `on-secondary`. 
*   **Visual Style:** 4px "bottom-heavy" shadow using `on-secondary-container` to simulate a physical arcade button press.
*   **Hover:** Shift background to `secondary-fixed` (#b5f56c) and reduce shadow offset to 2px.

### Progress Bars (Health/Mana Bars)
*   **Container:** `surface-container-highest` with a 2px `primary` block border.
*   **Fill:** A gradient from `tertiary` (#64000f) to `on-tertiary-container` (#ff9491).
*   **Visual Polish:** Use a "segmented" block overlay to make the bar look like individual HP pips.

### Card Containers
*   **Style:** Use `surface-container-lowest` with an **inner shadow** (inset 4px 4px 0px) using `surface-dim` to create a "recessed" look, making the content feel like it is slotted into a machine.
*   **Rule:** Forbid divider lines. Use vertical white space or a subtle shift to `surface-container-high` for internal segmentation.

### Input Fields
*   **Style:** Rectangular (`0px` radius) with a 2px solid `primary` border.
*   **State:** When focused, the border shifts to `secondary` (#3e6a00) with a 4px "outer glow" shadow.

### Additional Components: "Level Badges"
*   Small 8-bit pixel-art icons housed in `secondary-container` circles (which are actually octagons or squares to respect the `0px` radius rule).

---

## 6. Do's and Don'ts

### Do
*   **Use Asymmetry:** Place card elements slightly off-grid to evoke the feeling of a dynamic game world.
*   **Layer Surfaces:** Always place lighter containers on darker surfaces to guide the eye toward interactive elements.
*   **Scale Dramatically:** Use `display-lg` typography next to `body-sm` to create an editorial, high-fashion contrast.

### Don't
*   **Don't Use Curves:** The `0px` rounding rule is absolute. Even a 1px radius breaks the Neo-Arcade illusion.
*   **Don't Use Grey Shadows:** Shadows should always be a tinted variant of the background color to maintain tonal depth.
*   **Don't Over-Iconize:** Use 8-bit icons as punctuation, not as a replacement for clear, VT323-driven text labels. Accessibility must come first in ed-tech.