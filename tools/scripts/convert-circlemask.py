from PIL import Image

with Image.open("data/graphics/circle_mask_16x112.png").convert('L') as im:
    pix_data = list(im.getdata())

    w = 16
    h = 112

    out_data = bytearray(w*h>>3)
    for i in range(w*h>>3):
        bin_val = 0
        for j in range(8):
            bin_val <<= 1
            print(pix_data[(i<<3)+j])
            if pix_data[(i<<3)+j] == 255:
                bin_val |= 1
        out_data[i] = bin_val

    with open("data/graphics/circle_mask_16x112x1.raw", "wb") as raw_file:
        raw_file.write(bytes(out_data))
