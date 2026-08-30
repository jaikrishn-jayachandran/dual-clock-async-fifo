# =====================================================================
# Clock Definitions
# =====================================================================
# Write clock: 100 MHz (10ns period)
create_clock -name wclk -period 10.0 [get_ports wclk]

# Read clock: 40 MHz (25ns period) - supports slow reading cases
create_clock -name rclk -period 25.0 [get_ports rclk]

# Treat write and read clocks as completely asynchronous
set_clock_groups -asynchronous \
    -group {wclk} \
    -group {rclk}

# =====================================================================
# Input / Output Delays & Drive Strengths
# =====================================================================
# Set input delays relative to respective clocks (assume 2ns board delay)
set_input_delay 2.0 -clock wclk [get_ports {wrst_n w_inc w_data[*]}]
set_input_delay 2.0 -clock rclk [get_ports {rrst_n r_inc iso_en}]

# Set output delays relative to respective clocks
set_output_delay 2.0 -clock wclk [get_ports w_full]
set_output_delay 2.0 -clock rclk [get_ports {r_empty r_data[*]}]

# Drive constraints and load capacitances for standard cells
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_8 [all_inputs]
set_load 5.0 [all_outputs]