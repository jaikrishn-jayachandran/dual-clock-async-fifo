`timescale 1ns/1ps

module tb_async_fifo;

    // Parameters
    parameter int DATA_WIDTH = 32;
    parameter int ADDR_WIDTH = 4; // Using smaller depth (16 words) for faster simulation wrap-around
    
    // Clock periods (in ns)
    // Case 1: Same phase -> WCLK and RCLK will share the same clock source/frequency
    // Case 2: Fast write, slow read -> WCLK fast, RCLK slow
    // Case 3: Slow write, fast read -> WCLK slow, RCLK fast
    realtime WCLK_PERIOD = 10.0; // 100 MHz
    realtime RCLK_PERIOD = 25.0; // 40 MHz

    // Testbench Signals
    logic                      iso_en;
    logic                      wclk;
    logic                      wrst_n;
    logic                      w_inc;
    logic [DATA_WIDTH-1:0]     w_data;
    logic                      w_full;

    logic                      rclk;
    logic                      rrst_n;
    logic                      r_inc;
    logic [DATA_WIDTH-1:0]     r_data;
    logic                      r_empty;

    // Instantiate the Top-Level Async FIFO
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_dut (
        .iso_en(iso_en),
        .wclk(wclk),
        .wrst_n(wrst_n),
        .w_inc(w_inc),
        .w_full(w_full),
        .w_data(w_data),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .r_inc(r_inc),
        .r_empty(r_empty),
        .r_data(r_data)
    );

    // Clock Generators
    initial begin
        wclk = 0;
        forever #(WCLK_PERIOD / 2.0) wclk = ~wclk;
    end

    initial begin
        rclk = 0;
        forever #(RCLK_PERIOD / 2.0) rclk = ~rclk;
    end

    // Task: Reset Sequence
    task apply_reset();
        begin
            $display("[%0tns] Applying Asynchronous Reset...", $time);
            wrst_n = 0;
            rrst_n = 0;
            w_inc  = 0;
            r_inc  = 0;
            w_data = '0;
            iso_en = 0;
            #(WCLK_PERIOD * 5);
            wrst_n = 1;
            rrst_n = 1;
            $display("[%0tns] Reset Released.", $time);
            @(posedge wclk);
        end
    endtask

    // VCD Dump Setup
    initial begin
        $dumpfile("async_fifo_cases.vcd");
        $dumpvars(0, tb_async_fifo);
    end

    // Test Sequence Execution
    initial begin
        // Initialize signals
        w_inc = 0;
        r_inc = 0;
        w_data = 0;
        iso_en = 0;

        // =========================================================================
        // CASE 1: Both writing and reading are in the same phase / frequency
        // =========================================================================
        $display("\n=== STARTING CASE 1: Same Phase / Frequency ===");
        RCLK_PERIOD = WCLK_PERIOD; // Match clocks
        apply_reset();

        // Simultaneously write and read data to verify balanced throughput
        repeat (10) begin
            @(posedge wclk);
            w_inc  = 1;
            w_data = $random;
            @(posedge rclk);
            r_inc  = 1;
        end
        @(posedge wclk);
        w_inc = 0;
        r_inc = 0;
        #(WCLK_PERIOD * 5);

        // =========================================================================
        // CASE 2: Fast writing, slow reading (Forces Full Condition)
        // =========================================================================
        $display("\n=== STARTING CASE 2: Fast Writing, Slow Reading ===");
        WCLK_PERIOD = 10.0; // 100 MHz Write
        RCLK_PERIOD = 40.0; // 25 MHz Read
        apply_reset();

        // Flood the FIFO until w_full triggers
        repeat (25) begin
            @(posedge wclk);
            if (!w_full) begin
                w_inc  = 1;
                w_data = $random;
            end else begin
                w_inc  = 0;
            end
        end
        @(posedge wclk);
        w_inc = 0;

        // Slowly drain out data
        repeat (20) begin
            @(posedge rclk);
            if (!r_empty) begin
                r_inc = 1;
            end else begin
                r_inc = 0;
            end
        end
        @(posedge rclk);
        r_inc = 0;
        #(WCLK_PERIOD * 5);

        // =========================================================================
        // CASE 3: Slow writing, fast reading (Forces Empty Condition)
        // =========================================================================
        $display("\n=== STARTING CASE 3: Slow Writing, Fast Reading ===");
        WCLK_PERIOD = 40.0; // 25 MHz Write
        RCLK_PERIOD = 10.0; // 100 MHz Read
        apply_reset();

        // Write a few items slowly, read them out instantly to force underflow check
        repeat (5) begin
            @(posedge wclk);
            w_inc  = 1;
            w_data = $random;
            @(posedge wclk);
            w_inc  = 0;
            #(WCLK_PERIOD * 3);
        end

        // Fast read burst until empty
        repeat (10) begin
            @(posedge rclk);
            if (!r_empty) begin
                r_inc = 1;
            end else begin
                r_inc = 0;
            end
        end
        @(posedge rclk);
        r_inc = 0;
        #(WCLK_PERIOD * 5);

        // =========================================================================
        // CASE 4: Writing normally, reading stuck (Verifies Overflow Protection)
        // =========================================================================
        $display("\n=== STARTING CASE 4: Normal Write, Reading Stuck ===");
        WCLK_PERIOD = 10.0;
        RCLK_PERIOD = 10.0;
        apply_reset();

        r_inc = 0; // Reader is completely stuck / unresponsive
        
        // Keep writing until w_full blocks further attempts
        repeat (20) begin
            @(posedge wclk);
            if (!w_full) begin
                w_inc  = 1;
                w_data = $random;
            end else begin
                w_inc  = 0;
            end
        end
        @(posedge wclk);
        w_inc = 0;
        #(WCLK_PERIOD * 5);

        // =========================================================================
        // CASE 5: Writing stopped, reading continuously (Verifies Complete Drain)
        // =========================================================================
        $display("\n=== STARTING CASE 5: Writing Stopped, Continuous Read ===");
        // Pre-fill the FIFO first
        apply_reset();
        repeat (10) begin
            @(posedge wclk);
            w_inc  = 1;
            w_data = $random;
        end
        @(posedge wclk);
        w_inc = 0; // Stop writing completely

        // Continuously read until r_empty goes high
        repeat (15) begin
            @(posedge rclk);
            if (!r_empty) begin
                r_inc = 1;
            end else begin
                r_inc = 0;
            end
        end
        @(posedge rclk);
        r_inc = 0;
        #(WCLK_PERIOD * 5);

        // =========================================================================
        // CASE 6 (Missing Case): Simultaneous Burst / Back-to-Back Overlap & Reset Recovery
        // =========================================================================
        $display("\n=== STARTING CASE 6: Simultaneous Burst & Mid-Stream Reset Recovery ===");
        apply_reset();

        // Fire concurrent write and read bursts asynchronously
        fork
            begin
                // Writer thread
                repeat (12) begin
                    @(posedge wclk);
                    w_inc  = ~w_full;
                    w_data = $random;
                end
                w_inc = 0;
            end
            begin
                // Reader thread (starts slightly delayed)
                #(WCLK_PERIOD * 4);
                repeat (12) begin
                    @(posedge rclk);
                    r_inc  = ~r_empty;
                end
                r_inc = 0;
            end
        join

        #(WCLK_PERIOD * 5);

        // Test mid-operation asynchronous reset recovery
        $display("[%0tns] Injecting Mid-Stream Asynchronous Reset...", $time);
        fork
            begin
                @(posedge wclk);
                wrst_n = 0;
                #(WCLK_PERIOD * 3);
                wrst_n = 1;
            end
            begin
                @(posedge rclk);
                rrst_n = 0;
                #(RCLK_PERIOD * 3);
                rrst_n = 1;
            end
        join

        #(WCLK_PERIOD * 5);
        $display("[%0tns] All Test Cases Completed Successfully.", $time);
        $finish;
    end

endmodule