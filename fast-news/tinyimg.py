from PIL import Image

def tinyimg(img):
    img = img.convert('RGB')
    img = img.resize((2,2), Image.ANTIALIAS)
    return {"size": [2,2], "pixels": map(list, img.getdata())}
