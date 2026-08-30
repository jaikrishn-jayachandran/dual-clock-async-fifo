`timescale 1ns/1ps

// =================================================
// Dual Port BRAM
// =================================================

module dual_port_bram #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 8
) (
    // Power gating
    input  logic                     iso_en,

    // -------------------------------------------------
    // Port A: Write ONLY
    // -------------------------------------------------
    input  logic                     wclk,
    input  logic                     w_en,
    input  logic [ADDR_WIDTH-1:0]     w_addr,
    input  logic [DATA_WIDTH-1:0]     w_data,

    // -------------------------------------------------
    // Port B: Read ONLY
    // -------------------------------------------------
    input  logic                     rclk,
    input  logic                     rrst_n,
    input  logic                     r_en,
    input  logic [ADDR_WIDTH-1:0]     r_addr,

    output logic [DATA_WIDTH-1:0]     r_q_iso
);

    // =================================================
    // Memory
    // =================================================

    logic [DATA_WIDTH-1:0] bram [0:(1 << ADDR_WIDTH)-1];


    // =================================================
    // Synchronous Write Port
    // =================================================

    always_ff @(posedge wclk) begin
        if (w_en) begin
            bram[w_addr] <= w_data;
        end
    end


    // =================================================
    // Synchronous Read Port
    //
    // One clock-cycle read latency:
    //
    //     r_en + r_addr
    //             |
    //             v
    //         BRAM read
    //             |
    //             v
    //          r_q_iso
    //
    // =================================================

    always_ff @(posedge rclk or negedge rrst_n) begin

        if (!rrst_n) begin
            r_q_iso <= '0;
        end

        else if (r_en) begin
            if (iso_en)
                r_q_iso <= '0;
            else
                r_q_iso <= bram[r_addr];
        end

    end

endmodule