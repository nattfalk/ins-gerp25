import random

def generate_table(rows=32):
    table = []
    row_values = []
    for i in range(rows):
        a = random.randint(0, 15)
        b = random.randint(0, 15)
        row_values.append(f"${a:01X}{b:01X}")
        if (i + 1) % 8 == 0:
            table.append("dc.w " + ",".join(row_values))
            row_values = []
    if row_values:
        table.append("dc.w " + ",".join(row_values))
    return table

# Generate the table
table = generate_table()

# Print the table
for row in table:
    print(row)