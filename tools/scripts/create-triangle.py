from PIL import Image

width = 320
height = 160

im = Image.new('L', (width, height))
pix_data = list(im.getdata())

wid = width

for y in range(int(height)):
    col = 255
    w = wid / 2.0
    for x in range(int(w)):
        pix_data[y*width+(width/2-1)-x] = col
        pix_data[y*width+(width/2)+x] = col
        w += 1
    wid -= 2
im.putdata(pix_data)
im.save("data/graphics/triangle.png", "PNG")

out_data = bytearray(width*height>>3)
for i in range(width*height>>3):
    bin_val = 0
    for j in range(8):
        bin_val <<= 1
        if pix_data[(i<<3)+j] == 255:
            bin_val |= 1
    out_data[i] = bin_val

with open("data/graphics/triangle.raw", "wb") as raw_file:
    raw_file.write(bytes(out_data))
