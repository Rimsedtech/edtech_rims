from PIL import Image, ImageChops

def make_transparent(input_path, output_path):
    img = Image.open(input_path).convert("RGBA")
    
    # Simple thresholding or flood fill. 
    # Flood fill is better to avoid eating into the logo.
    
    # We'll use a mask based on color distance from white (255,255,255)
    # or just use floodfill.
    
    # Fill from (0,0) with transparency
    # ImageDraw.floodfill doesn't support alpha well in some versions, 
    # so we'll do it manually or use a mask.
    
    bg = Image.new("RGBA", img.size, (255, 255, 255, 255))
    diff = ImageChops.difference(img, bg)
    # Convert diff to grayscale and threshold it
    mask = diff.convert("L").point(lambda x: 255 if x > 10 else 0)
    
    img.putalpha(mask)
    img.save(output_path, "PNG")

if __name__ == "__main__":
    make_transparent("/Users/rimsedtech/.gemini/antigravity/brain/28877bda-0906-4b70-9600-208ad922302c/rims_logo_white_bg_1776797842360.png", "logo/logo_final.png")
