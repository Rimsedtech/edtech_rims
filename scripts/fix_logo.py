from PIL import Image, ImageDraw

def remove_checkerboard(input_path, output_path):
    img = Image.open(input_path).convert("RGBA")
    width, height = img.size
    
    # Sample checkerboard colors from the corners
    c1 = img.getpixel((0, 0))
    c2 = img.getpixel((1, 0))
    
    # Create a mask for flood fill starting from corners
    # We'll use a copy to find the background area
    mask = Image.new("L", (width, height), 0)
    
    # Combine the two checkerboard colors into a simplified mask
    # This assumes the logo doesn't have these exact colors or we use flood fill
    # Actually, let's just do a flood fill of "similar to c1 or c2"
    
    data = img.getdata()
    new_data = []
    
    # Simple strategy: if color matches c1 or c2 exactly, make it transparent
    # This might eat into the logo if it has those colors, but let's try.
    # To be safer, we can use flood fill logic.
    
    for item in data:
        if (item[0], item[1], item[2]) == (c1[0], c1[1], c1[2]) or \
           (item[0], item[1], item[2]) == (c2[0], c2[1], c2[2]):
            new_data.append((0, 0, 0, 0))
        else:
            new_data.append(item)
            
    img.putdata(new_data)
    img.save(output_path, "PNG")

if __name__ == "__main__":
    remove_checkerboard("logo/logo.png", "logo/logo_transparent.png")
