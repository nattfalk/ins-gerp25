from PIL import Image

im = Image.new('L', (640, 64))
pix_data = list(im.getdata())

top_width = 16.0
bottom_width = 32.0
steps = 64.0

step = 1.0
width = top_width
for y in range(int(steps)):
    col = 255
    w = width / 2.0
    for x in range(320):
        pix_data[y*640+319-x] = col
        pix_data[y*640+320+x] = col
        w += 1
        if int(w/width) % 2 == 0:
            col = 255
        else:
            col = 0
    width += (bottom_width-top_width)/steps
im.putdata(pix_data)
im.save("data/graphics/stripes_pattern.png", "PNG")

out_data = bytearray(640*64>>3)
for i in range(640*64>>3):
    bin_val = 0
    for j in range(8):
        bin_val <<= 1
        if pix_data[(i<<3)+j] == 255:
            bin_val |= 1
    out_data[i] = bin_val

with open("data/graphics/stripes_pattern.raw", "wb") as raw_file:
    raw_file.write(bytes(out_data))
