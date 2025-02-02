input = "000000fc0000004c00f00000009400cc000000cc0094000000f00050000000fc0000000000f4ffb0000000d0ff6800000098ff3000000050ff0c00000000ff000000ffb4ff080000ff6cff2c0000ff30ff640000ff0cffac0000ff00fff80000ff0800480000ff2c00900000ff6400c80000ffa800f00000002700f30043004a00cf00800067009700b10079005000d1007f000100dc007affb200d20068ff6b00b3004cff3200830028ff0d0045ffdaff0bffbeffb6ff2eff80ff99ff66ff4fff86ffacff2eff80fffbff23ff85004aff2cff960092ff49ffb200cbff7affd500f1ffb6ffd900f30043ffb600cf0081ff99009700b2ff87005000d2ff81000100ddff86ffb200d3ff98ff6b00b4ffb4ff320083ffd7ff0d00460025ff0bffbe0049ff2eff7f0065ff66ff4e0078ffacff2d007ffffbff220079004aff2b00680092ff49004c00cbff79002a00f1ffb6"

def fix_coords():
    table = []
    for i in range(0, len(input), 12):
        group1 = input[i:i+4]
        group2 = input[i+4:i+8]
        group3 = input[i+8:i+12]
        # print(f"dc.w ${group1}, ${group2}, ${group3}")
        table.append(f"dc.w ${group1}, ${group2}, ${group3}")
    return table

# Generate the table
table = fix_coords()

# Print the table
for row in table:
    print(row)