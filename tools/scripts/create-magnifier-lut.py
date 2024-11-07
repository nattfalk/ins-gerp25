import math

def magnifier_lens_effect(size):
    with open("../../data/magnifier-lut.s", "w") as f:
        f.write("\teven\n")
        f.write("; Magnifier effect LUT - Size {}x{}\n".format(size, size))
        f.write("Magnifier_lut:\n")

        width, height = size, size
        center_x, center_y = width / 2, height / 2
        max_radius = math.sqrt(center_x**2 + center_y**2)
        
        for y in range(height):
            for x in range(width):
                dx = x - center_x
                dy = y - center_y
                distance = math.sqrt(dx**2 + dy**2)
                if distance == 0:
                    f.write("\tdc.w\t{},{}\n".format(x, y))
                    continue
                
                r = distance / max_radius
                theta = math.atan2(dy, dx)
                
                new_r = r**2  # Magnifier effect
                new_x = int(center_x + new_r * max_radius * math.cos(theta))
                new_y = int(center_y + new_r * max_radius * math.sin(theta))
                f.write("\tdc.w\t{},{}\n".format(new_x, new_y))

size = 32
magnifier_lens_effect(size)
