# 2.5D Character Customization & 360° Rotation Implementation Guide

## 📌 Overview
This document outlines the architecture and implementation steps for adding an interactive, 360-degree rotatable character to the RIMS Gamified Dashboard using a **2.5D Layered Sprite** approach. 

By using pre-rendered 2D frames instead of a real 3D engine, we maintain the "Neo-Arcade" 8-bit aesthetic, ensure maximum app performance, and make layering cosmetics incredibly easy.

---

## 🎨 1. Asset Requirements (For Designers)

To fake a 360-degree rotation, you do not need 3D models. Instead, you need **sprite sheets** (or individual PNGs) for every item from 8 different directional angles.

### Angle Convention (8-Directional)
1. **0** - South (Facing camera)
2. **1** - South-East
3. **2** - East
4. **3** - North-East
5. **4** - North (Facing away)
6. **5** - North-West
7. **6** - West
8. **7** - South-West

### Required Assets Structure
All assets must have a transparent background and be exactly the same canvas size (e.g., 256x256) so they align perfectly when stacked on top of each other.

*   **Base Character**: `base_body_0.png` to `base_body_7.png`
*   **Cosmetics (Hats, Armor, Weapons)**: e.g., `gold_crown_0.png` to `gold_crown_7.png`

> **Note**: If you want a smooth rotation, you can use 16 frames instead of 8, but it doubles the asset workload.

---

## 🔥 2. Firebase Setup & Schema Changes

### A. Storage Rules & Structure
Upload all frames to Firebase Storage. Instead of uploading 8 separate images per item, it's highly recommended to upload a **Sprite Sheet** (1 long image containing all 8 frames) to reduce HTTP requests.
*   Path: `gs://edtech-3f6fe.appspot.com/cosmetics/{category}/{item_id}.png`

### B. Firestore `skins` (Cosmetics) Collection Update
Currently, the store assumes a skin is a single 2D image. You will need to add "categories".

```json
// Collection: cosmetics
// Document: crown_01
{
  "id": "crown_01",
  "name": "Golden Crown",
  "category": "head", // 'head', 'body', 'weapon', 'pet'
  "price": 500,
  "spriteSheetUrl": "https://firebase.storage/.../crown_01.png",
  "frames": 8
}
```

### C. Firestore `users` Collection Update
Add a new map to the user profile to track what they currently have equipped.

```json
// Collection: users
// Document: {userId}
{
  "displayName": "Student",
  "xp": 1200,
  "equippedCosmetics": {
    "head": "crown_01",
    "body": "starter_shirt",
    "weapon": null
  }
}
```

---

## 💻 3. Flutter Implementation Plan

### Step 1: The Sprite Renderer Widget
You will need a custom widget that takes an image and a `frameIndex` (0 to 7) and only paints that specific portion of the sprite sheet. Flutter's `CustomPainter` or a package like `flame` (using `SpriteAnimationWidget`) is perfect for this.

### Step 2: The Layering Logic (`Stack` Widget)
The character is built by stacking these renderers on top of each other. The order matters!

```dart
Stack(
  children: [
    // Bottom Layer: Body
    SpriteFrameRenderer(url: baseBodyUrl, frame: currentAngle),
    
    // Middle Layer: Armor/Clothes
    if (equipped.body != null)
      SpriteFrameRenderer(url: equipped.bodyUrl, frame: currentAngle),
      
    // Top Layer: Hat/Crown
    if (equipped.head != null)
      SpriteFrameRenderer(url: equipped.headUrl, frame: currentAngle),
  ],
)
```

### Step 3: The Rotation Logic (`GestureDetector`)
To rotate the character, you listen to horizontal dragging. As the user drags left or right, you increment or decrement the `currentAngle` index.

```dart
int currentAngle = 0; // Starts facing South

GestureDetector(
  onPanUpdate: (details) {
    // Calculate drag distance
    // If dragged right enough -> currentAngle = (currentAngle + 1) % 8
    // If dragged left enough -> currentAngle = (currentAngle - 1) % 8
    // setState to update the Stack
  },
  child: CharacterStackWidget(),
)
```

### Step 4: UI Integration
On the "Customize" screen, place the 360-character widget taking up the top 50% of the screen. Below it, render a tabbed interface (Hats, Outfits, Weapons) pulling from the `cosmetics` Firestore collection. When a user taps a cosmetic, immediately update their `equippedCosmetics` state so the preview updates instantly.

---

## 🚀 4. Performance Checklist
1. **Pre-caching**: When the app boots, use `precacheImage()` on the user's currently equipped sprite sheets so the character appears instantly.
2. **Sprite Sheets over Individual PNGs**: Always use sprite sheets. Downloading one 2048x256 image is much faster than downloading eight 256x256 images.
3. **Z-Ordering Challenges**: Sometimes a weapon needs to be rendered *behind* the player when facing North, but *in front* of the player when facing South. You may need to dynamically sort the `Stack` children based on the `currentAngle`.
