from PIL import Image

def inspect_alpha(input_path):
    img = Image.open(input_path).convert("RGBA")
    data = img.getdata()
    alphas = [pixel[3] for pixel in list(data)[:100]]
    print(f"First 100 alpha values: {alphas}")

if __name__ == "__main__":
    inspect_alpha("logo/logo.png")
