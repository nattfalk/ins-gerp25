import random

for i in range(32>>3):
    print("\tdc.w\t", end="")
    for j in range(8):
        print("{},{}".format(int(random.random()*12)-6, int(random.random()*12)-6), end="")
        if j != 7:
            print(", ", end="")
    print()
