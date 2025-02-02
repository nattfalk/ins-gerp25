import random

def generate_table(rows=48):
    table = []
    for _ in range(rows):
        x = random.randint(0, 319)
        y = random.randint(0, 95)
        vx = random.randint(-15, 15)
        vy = random.randint(-15, 15)
        table.append(f"dc.w {x*16},{y*16},{vx},{vy},0,0")
    return table

# Generate the table
table = generate_table()

# Print the table
for row in table:
    print(row)