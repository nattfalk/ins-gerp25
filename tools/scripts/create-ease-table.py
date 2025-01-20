def ease_out(current_step, total_steps, max_value, offset):
    current_step /= total_steps
    return int(-max_value * current_step*(current_step-2) + offset)

def ease_in(current_step, total_steps, max_value, offset):
    current_step /= total_steps
    return int(max_value*current_step*current_step + offset)

total_steps = 64
# print('left to right:')
for i in range(0, total_steps):
    if i % 8 == 0:
        print('')
        print('\tdc.w\t', end='')
    print(f'{ease_in(i, total_steps, 32, 0)}', end='')
    if i % 8 != 7 and i != total_steps - 1:
        print(',', end=' ')
# print()
# print()
# print('right to left:')
for i in range(0, total_steps):
    if i % 8 == 0:
        print('')
        print('\tdc.w\t', end='')
    print(f'{32 + ease_out(i, total_steps, 33, 0)}', end='')
    if i % 8 != 7 and i != total_steps - 1:
        print(',', end=' ')
