from PIL import Image

def inspect_corners(input_path):
    img = Image.open(input_path).convert("RGBA")
    print(f"Top-left (0,0): {img.getpixel((0, 0))}")
    print(f"Top-left+1 (1,0): {img.getpixel((1, 0))}")
    print(f"Top-left+2 (2,0): {img.getpixel((2, 0))}")
    print(f"Top-left+3 (3,0): {img.getpixel((3, 0))}")

if __name__ == "__main__":
    inspect_corners("logo/logo.png")
