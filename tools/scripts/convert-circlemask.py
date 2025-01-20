from PIL import Image

def pack_bits(input):
    out_data = bytearray(4)
    k = 0
    for i in range(len(input) >> 3):
        bin_val = 0
        for j in range(8):
            bin_val <<= 1
            if input[(i << 3) + j] == 255:
                bin_val |= 1
        out_data[k] = bin_val
        k += 1
    out_data[k] = 0
    out_data[k + 1] = 0
    return out_data

with Image.open("data/graphics/circle_mask_2_16x160.png").convert('L') as im:
    pix_data = list(im.getdata())

    w = 16
    h = 160

    out_data = bytearray((w*2)*h>>3)
    for i in range(w*h>>4):
        packed_bits = pack_bits(pix_data[(i<<4):(i<<4)+16])
        out_data[i<<2:(i<<2)+4] = packed_bits

    with open("data/graphics/circle_mask_2_32x160x1.raw", "wb") as raw_file:
        raw_file.write(bytes(out_data))
