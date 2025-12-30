def filter_verilog_rom(input_file, output_file):
    # The string we are looking for to trigger a deletion
    target_value = "12'b000000000000"

    with open(input_file, 'r') as f_in, open(output_file, 'w') as f_out:
        for line in f_in:
            # Check if the target string is NOT in the line
            if target_value not in line:
                f_out.write(line)
            else:
                # Optional: If you want to keep the 'default' case even if it's zero
                if "default" in line.lower():
                    f_out.write(line)

# Usage
filter_verilog_rom('img_rom.v', 'snake_color_rom_cleaned.v')
print("Filtering complete. Cleaned file saved as 'snake_color_rom_cleaned.v'")