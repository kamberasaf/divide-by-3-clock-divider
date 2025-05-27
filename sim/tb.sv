/*******************************************************************************
 * File: tb.sv
 * Description: Testbench for divide-by-3 clock divider with 50% duty cycle
 * Author: Asaf Kamber
 * Date: 27/05/2025
 * 
 * This testbench verifies:
 * 1. Frequency division (100MHz -> 33.33MHz)
 * 2. 50% duty cycle output
 * 
 * Tests performed:
 * - Frequency measurement over configurable sample time
 * - Duty cycle measurement over multiple periods
 *******************************************************************************/

`timescale 1ns / 1ps

module tb();
    
    //=========================================================================
    // PARAMETERS AND CONSTANTS
    //=========================================================================
    
    // Clock and timing parameters
    localparam int CLK_PERIOD = 10;                      // 10ns period (100MHz)
    localparam real CLK_FREQ = 1000.0/CLK_PERIOD;       // Input frequency in MHz
    localparam real EXPECTED_OUTPUT_FREQ = CLK_FREQ/3.0; // Expected output: 33.33 MHz
    localparam real EXPECTED_DUTY_CYCLE = 50.0;          // Expected duty cycle: 50%
    localparam int RST_TIME = 30;                        // Reset duration in ns
    
    // Test configuration parameters
    localparam real ERROR_TOL = 5.0;                     // Tolerance: 5%
    localparam int SAMPLE_TIME_NS = 500;                 // Frequency test sample time
    localparam int NUM_PERIODS = 10;                     // Number of periods for duty cycle test
    
    //=========================================================================
    // SIGNAL DECLARATIONS
    //=========================================================================
    
    logic clk;       // Input clock (100MHz)
    logic rst;       // Reset signal (active high)
    logic clk_dev_3; // Output from DUT (33.33MHz, 50% duty cycle)
    
    //=========================================================================
    // CLOCK AND RESET GENERATION
    //=========================================================================
    
    // Generate 100MHz clock
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Generate reset pulse
    initial begin
        rst = 1;                    // Assert reset
        #RST_TIME;                  // Hold for RST_TIME
        @(posedge clk);            // Synchronize release to clock
        rst = 0;                   // Release reset
    end
    
    //=========================================================================
    // DEVICE UNDER TEST (DUT) INSTANTIATION
    //=========================================================================
    
    dev_3 DUT(
        .clk(clk),
        .rst(rst),
        .y(clk_dev_3)
    );
    
    //=========================================================================
    // MAIN TEST SEQUENCE
    //=========================================================================
    
    initial begin
        $display("=====================================");
        $display("Divide-by-3 Clock Divider Test Suite");
        $display("=====================================");
        $display("Input Frequency:  %.1f MHz", CLK_FREQ);
        $display("Expected Output:  %.2f MHz", EXPECTED_OUTPUT_FREQ);
        $display("Expected Duty Cycle: %.1f%%", EXPECTED_DUTY_CYCLE);
        $display("=====================================");
        
        // Wait for reset deassertion and circuit stabilization
        wait(!rst);
        @(posedge clk);
        repeat(20) @(posedge clk);  // Allow circuit to stabilize
        
        // Execute test suite
        freq_test(clk_dev_3, EXPECTED_OUTPUT_FREQ, ERROR_TOL, SAMPLE_TIME_NS);
        duty_cycle_test(clk_dev_3, EXPECTED_DUTY_CYCLE, ERROR_TOL, NUM_PERIODS);
        
        // Test completion
        $display("=====================================");
        $display("ALL TESTS COMPLETED SUCCESSFULLY!");
        $display("=====================================");
        
        #100;    // Small delay before finishing
        $finish;
    end
    
    //=========================================================================
    // UTILITY FUNCTIONS
    //=========================================================================
    
    /**
     * Absolute value function for real numbers
     * @param value: Input value
     * @return: Absolute value of input
     */
    function real abs(input real value);
        return (value >= 0) ? value : -value;
    endfunction
    
    //=========================================================================
    // TEST TASKS
    //=========================================================================
    
    /**
     * Frequency Test Task
     * Measures the frequency of the output signal over a specified time period
     * 
     * @param checked_signal: Signal to measure (passed by reference)
     * @param expected_freq: Expected frequency in MHz
     * @param tolerance_percent: Acceptable error percentage (default: 5%)
     * @param sample_time_ns: Measurement duration in ns (default: 500ns)
     */
    task automatic freq_test(
        ref logic checked_signal,
        input real expected_freq,
        input real tolerance_percent = 5.0,
        input real sample_time_ns = 500.0  
    );
        // Local variables
        int edge_count = 0;
        int start_time, end_time;
        real measured_freq_mhz, error_percent;
        logic prev_signal;
        
        $display("-----------------------------------------");
        $display("FREQUENCY TEST");
        $display("-----------------------------------------");
        
        start_time = $time;
        prev_signal = checked_signal;
        
        // Count rising edges over the sample period
        fork
            begin
                #sample_time_ns;  // Wait for sample time to complete
            end
            begin
                forever begin
                    @(checked_signal);  // Wait for any edge
                    if (checked_signal && !prev_signal) // Rising edge detected
                        edge_count = edge_count + 1;
                    prev_signal = checked_signal;
                end 
            end
        join_any
        disable fork;
        
        end_time = $time;
        
        // Calculate measured frequency
        measured_freq_mhz = (edge_count / sample_time_ns) * 1000.0;
        error_percent = abs((measured_freq_mhz - expected_freq) / expected_freq) * 100;
        
        // Display results
        $display("Sample Time:     %.0f ns", sample_time_ns);
        $display("Edges Counted:   %0d", edge_count);
        $display("Expected Freq:   %.2f MHz", expected_freq);
        $display("Measured Freq:   %.2f MHz", measured_freq_mhz);
        $display("Error:           %.2f%%", error_percent);
        
        // Check if test passes
        if (error_percent <= tolerance_percent) begin
            $display("Result:          PASS");
        end else begin
            $display("Result:          FAIL - Error %.2f%% exceeds tolerance %.2f%%", 
                   error_percent, tolerance_percent);
        end
        
        $display("-----------------------------------------");
    endtask
    
    /**
     * Duty Cycle Test Task
     * Measures the duty cycle of the output signal over multiple periods
     * 
     * @param checked_signal: Signal to measure (passed by reference)
     * @param expected_duty_cycle: Expected duty cycle percentage (default: 50%)
     * @param tolerance_percent: Acceptable error percentage (default: 5%)
     * @param num_periods: Number of periods to measure (default: 10)
     */
    task automatic duty_cycle_test(
        ref logic checked_signal,
        input real expected_duty_cycle = 50.0,
        input real tolerance_percent = 5.0,
        input int num_periods = 10
    );
        // Local variables
        int total_high_time = 0;
        int total_period_time = 0;
        int period_start, high_end, period_end;
        int high_time, period_time;
        real measured_duty_cycle, error_percent;
        
        $display("DUTY CYCLE TEST");
        $display("-----------------------------------------");
        $display("Measuring over %0d periods...", num_periods);
        
        // Measure duty cycle over specified number of periods
        for (int i = 0; i < num_periods; i++) begin            
            // Wait for rising edge (start of period)
            @(posedge checked_signal);
            period_start = $time;
            
            // Wait for falling edge (end of high time)
            @(negedge checked_signal);
            high_end = $time;
            high_time = high_end - period_start;
                     
            // Wait for next rising edge (end of period)
            @(posedge checked_signal);
            period_end = $time;
            period_time = period_end - period_start;
            
            // Accumulate measurements
            total_high_time += high_time;
            total_period_time += period_time;
        end
        
        // Calculate average duty cycle
        measured_duty_cycle = (real(total_high_time) / real(total_period_time)) * 100.0;
        error_percent = abs((measured_duty_cycle - expected_duty_cycle) / expected_duty_cycle) * 100.0;
        
        // Display results
        $display("Periods Measured:    %0d", num_periods);
        $display("Total High Time:     %0d ns", total_high_time);
        $display("Total Period Time:   %0d ns", total_period_time);
        $display("Expected Duty Cycle: %.1f%%", expected_duty_cycle);
        $display("Measured Duty Cycle: %.2f%%", measured_duty_cycle);
        $display("Error:               %.2f%%", error_percent);
        
        // Check if test passes
        if (error_percent <= tolerance_percent) begin
            $display("Result:              PASS");
        end else begin
            $display("Result:              FAIL - Error %.2f%% exceeds tolerance %.2f%%", 
                   error_percent, tolerance_percent);
        end
        
        $display("-----------------------------------------");
    endtask

endmodule

