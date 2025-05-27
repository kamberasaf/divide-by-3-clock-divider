/*******************************************************************************
 * File: top.sv
 * Description: Divide-by-3 clock divider with 50% duty cycle
 * Author: Asaf Kamber
 * Date: 27/05/2025
 * 
 * This module implements a frequency divider that:
 * - Divides input clock frequency by 3
 * - Maintains 50% duty cycle on the output
 * - Uses dual counter architecture for phase offset
 * 
 * Architecture:
 * - Two identical mod-3 counters
 * - Counter 1: Triggered on positive clock edges  
 * - Counter 2: Triggered on negative clock edges (180° phase shift)
 * - Output: OR of both counter outputs
 * 
 * Hardware Resources:
 * - 4 flip-flops total (2 bits per counter for 3 states)
 * - Combinational logic for next-state calculation
 * - Single OR gate for output generation
 * 
 * Timing:
 * - Input frequency: f_in
 * - Output frequency: f_in/3
 * - Output duty cycle: ~50%
 *******************************************************************************/

`timescale 1ns / 1ps

module dev_3 (
    input  logic clk,   // Input clock
    input  logic rst,   // Reset (active high)
    output logic y      // Divided clock output (f_clk/3, 50% duty cycle)
);

    //=========================================================================
    // PARAMETERS AND CONSTANTS
    //=========================================================================
    
    // State encoding for mod-3 counters
    localparam logic [1:0] S0 = 2'b00;  // State 0
    localparam logic [1:0] S1 = 2'b01;  // State 1  
    localparam logic [1:0] S2 = 2'b10;  // State 2 (output state)
    
    //=========================================================================
    // INTERNAL SIGNAL DECLARATIONS
    //=========================================================================
    
    // Counter 1: Positive edge triggered
    logic [1:0] current_state_1;   
    logic [1:0] next_state_1;     
    logic       out_1;            // Counter 1 output 
    
    // Counter 2: Negative edge triggered  
    logic [1:0] current_state_2;   
    logic [1:0] next_state_2;     
    logic       out_2;            // Counter 2 output
    
    //=========================================================================
    // SEQUENTIAL LOGIC - STATE REGISTERS
    //=========================================================================
    
    /**
     * Counter 1: Positive edge triggered mod-3 counter
     * State sequence: S0 -> S1 -> S2 -> S0 -> ...
     * Outputs '1' when in state S2
     */
    always_ff @(posedge clk) begin
        if (rst) 
            current_state_1 <= S0;  // Reset to initial state
        else
            current_state_1 <= next_state_1;
    end
    
    /**
     * Counter 2: Negative edge triggered mod-3 counter  
     * State sequence: S1 -> S2 -> S0 -> S1 -> ... (starts offset)
     * Outputs '1' when in state S2
     * Note: Starts at S1 to create 180° phase offset with Counter 1
     */
    always_ff @(negedge clk) begin
        if (rst)
            current_state_2 <= S1;  // Reset to S1 for phase offset
        else
            current_state_2 <= next_state_2;
    end
    
    //=========================================================================
    // COMBINATIONAL LOGIC - NEXT STATE AND OUTPUT GENERATION
    //=========================================================================
    
    /**
     * Next state logic and output generation for both counters
     * Both counters implement identical mod-3 state machines:
     * S0 -> S1 -> S2 -> S0 (repeat)
     * Output is high only during S2 state
     */
    always_comb begin
        // Default assignments (prevents latches)
        out_1 = 1'b0;
        out_2 = 1'b0;
        
        // Counter 1: Next state logic and output
        case (current_state_1)
            S0: begin
                next_state_1 = S1;
                out_1 = 1'b0;
            end
            S1: begin
                next_state_1 = S2;
                out_1 = 1'b0;
            end
            S2: begin
                next_state_1 = S0;
                out_1 = 1'b1;    // Output high in S2
            end
            default: begin
                next_state_1 = S0;  // Safe default
                out_1 = 1'b0;
            end
        endcase
        
        // Counter 2: Next state logic and output (identical to Counter 1)
        case (current_state_2)
            S0: begin
                next_state_2 = S1;
                out_2 = 1'b0;
            end
            S1: begin
                next_state_2 = S2;
                out_2 = 1'b0;
            end
            S2: begin
                next_state_2 = S0;
                out_2 = 1'b1;    // Output high in S2
            end
            default: begin
                next_state_2 = S0;  // Safe default
                out_2 = 1'b0;
            end
        endcase
    end
    
    //=========================================================================
    // OUTPUT LOGIC
    //=========================================================================
    
    /**
     * Final output generation
     * OR the outputs of both counters to create 50% duty cycle
     * When one counter is low, the other provides the high output
     */
    assign y = out_1 | out_2;

endmodule