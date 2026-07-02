import os
from PIL import Image, ImageDraw

def make_logo_transparent(input_path, output_path):
    img = Image.open(input_path).convert("RGBA")
    width, height = img.size
    
    # Collect starting points along all 4 edges of the image
    starts = []
    # Top and bottom edges
    for x in range(width):
        starts.append((x, 0))
        starts.append((x, height - 1))
    # Left and right edges
    for y in range(height):
        starts.append((0, y))
        starts.append((width - 1, y))
        
    # Perform boundary-guided flood fill for white/light-grey pixels
    for x, y in starts:
        r, g, b, a = img.getpixel((x, y))
        if a == 0:
            continue
        # Target light background pixels (R > 200, G > 200, B > 200)
        if r > 180 and g > 180 and b > 180:
            # Use threshold of 60 to capture all slight shadows/gradients in the white outer region
            ImageDraw.floodfill(img, (x, y), (0, 0, 0, 0), thresh=60)
            
    # Save the resulting transparent PNG
    img.save(output_path, "PNG")
    print(f"Successfully transparentized {input_path} and saved to {output_path}")

if __name__ == "__main__":
    input_img = "/Users/rimsedtech/Development/gamify/app/logo/logo_transparent.png"
    output_img = "/Users/rimsedtech/Development/gamify/app/logo/logo.png"
    make_logo_transparent(input_img, output_img)
    
    # Also save a copy as logo_transparent.png itself so both are updated
    make_logo_transparent(input_img, input_img)
