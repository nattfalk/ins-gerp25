x1 = 0
y1 = 0

x2 = 19*16
y2 = 15*16

a_step = 16
b_step = -16

with open("data/image_reveal_pattern.s", "w") as f:
    f.write("\teven\n")
    f.write("Logo_RevealPattern:\n")
    for j in range(4):
        for i in range(20):
            f.write("\tdc.w\t{},{},0\n".format(x1, y1))
            f.write("\tdc.w\t{},{},0\n".format(x2, y2))
            x1 += a_step
            x2 += b_step
        x1 -= a_step
        x2 -= b_step
        a_step *= -1
        y1 += 16
        b_step *= -1
        y2 -= 16

    a_step = 16
    b_step = -16
    for j in range(10):
        for i in range(8):
            f.write("\tdc.w\t{},{},0\n".format(x1, y1))
            f.write("\tdc.w\t{},{},0\n".format(x2, y2))
            y1 += a_step
            y2 += b_step
        y1 -= a_step
        y2 -= b_step
        a_step *= -1
        x1 += 32
        b_step *= -1
        x2 -= 32
