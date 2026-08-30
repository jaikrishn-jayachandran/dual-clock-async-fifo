# async_fifo (Top-Level Wrapper)

The top entity that instantiates and ties together all sub-blocks, routing power nets, isolation control lines, and external data interfaces.

# dual_port_bram (The Memory Core)

The True Dual-Port RAM storage array (bram.sv) operating across the asynchronous wclk and rclk boundaries, equipped with hardware isolation logic for power gating.

# binary_to_gray (Encoder Block)

Converts standard incrementing binary write/read addresses into Gray code (g = b ^ (b >> 1)) so only a single bit changes at a time.

# gray_to_binary (Decoder / Synchronizer Block)

Passes the Gray-coded pointers through multi-flop synchronizer chains ($\text{FF}_2$) safely across the clock domain wall, then decodes them back to binary for safe address mapping.

# fifo_controller (Status & Flag Generation Block)

Monitors the synchronized pointers in their respective clock domains to compute the full and empty status flags, managing overflow and underflow conditions.
