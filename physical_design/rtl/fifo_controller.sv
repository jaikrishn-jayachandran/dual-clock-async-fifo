`timescale 1ns/1ps


// =================================================
// Asynchronous FIFO module
// =================================================

module fifo_controller #(
    parameter ADDR_WIDTH = 8
) (

    // Write domain signals
    input logic wclk,
    input logic wrst_n,
    input logic w_inc,
    output logic w_full,
    output logic [ADDR_WIDTH-1:0] w_addr,
    output logic [ADDR_WIDTH:0] w_ptr_gray,
    input logic [ADDR_WIDTH:0] r_ptr_sync_gray,

    // Read domain signals
    input logic rclk,
    input logic rrst_n,
    input logic r_inc,
    output logic r_empty,
    output logic [ADDR_WIDTH-1:0] r_addr,
    output logic [ADDR_WIDTH:0] r_ptr_gray,
    input logic [ADDR_WIDTH:0] w_ptr_sync_gray
);

    logic [ADDR_WIDTH:0] w_bin_counter;
    logic [ADDR_WIDTH:0] r_bin_counter;

    logic [ADDR_WIDTH:0] w_bin_next;
    logic [ADDR_WIDTH:0] r_bin_next;

    logic [ADDR_WIDTH:0] r_ptr_sync_bin;
    logic [ADDR_WIDTH:0] w_ptr_sync_bin;

    // Write domain logic

    assign w_addr = w_bin_counter[ADDR_WIDTH-1:0]; // Making the memory bits the lower bits of the counter
    assign w_bin_next = w_bin_counter + (w_inc & ~w_full); // Increment if write is requested and the FIFO is not full

    always_ff @(posedge wclk or negedge wrst_n)begin
        if(!wrst_n)begin
            w_bin_counter <= 0;
        end else begin
            w_bin_counter <= w_bin_next;
        end
    end

    // Convert local next binary pointer to gray code for export
    binary_to_gray #(.PTR_WIDTH(ADDR_WIDTH+1)
    ) u_w_b2g (
        .binary_in(w_bin_next),
        .gray_out(w_ptr_gray)
    );

    // Convert gray code to binary for export
    gray_to_binary #(.PTR_WIDTH(ADDR_WIDTH+1)
    ) u_w_g2b (
        .gray_in(r_ptr_sync_gray),
        .binary_out(r_ptr_sync_bin)
    );

    logic w_full_val;
    assign w_full_val = (w_bin_next == {~r_ptr_sync_bin[ADDR_WIDTH], r_ptr_sync_bin[ADDR_WIDTH-1:0]});
    
    always_ff @(posedge wclk or negedge wrst_n)begin
        if(!wrst_n)begin
            w_full <= 1'b0;
        end else begin
            w_full <= w_full_val;
        end
    end


    // Read domain logic

    assign r_addr = r_bin_counter[ADDR_WIDTH-1:0]; // Making the memory bits the lower bits of the counter
    assign r_bin_next = r_bin_counter + (r_inc & ~r_empty);

    always_ff @(posedge rclk or negedge rrst_n)begin
        if(!rrst_n)begin
            r_bin_counter <= 0;
        end else begin
            r_bin_counter <= r_bin_next;
        end
    end

    binary_to_gray #(.PTR_WIDTH(ADDR_WIDTH+1)) u_r_b2g (
        .binary_in(r_bin_next),
        .gray_out(r_ptr_gray)
    );

    gray_to_binary #(.PTR_WIDTH(ADDR_WIDTH+1)) u_r_g2b (
        .gray_in(w_ptr_sync_gray),
        .binary_out(w_ptr_sync_bin)
    );

    logic r_empty_val;
    assign r_empty_val = (r_bin_next == w_ptr_sync_bin);

    always_ff @(posedge rclk or negedge rrst_n)begin
        if(!rrst_n)begin
            r_empty <= 1'b1;
        end else begin
            r_empty <= r_empty_val;
        end
    end

endmodule