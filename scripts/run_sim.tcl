#******************************************************************************
# File: run_sim.tcl
# Description: Automated simulation script for divide-by-3 clock divider
# Author: Asaf Kamber
# Usage: source scripts/run_sim.tcl
#
# This script automates the complete simulation flow including:
# - Project setup
# - Source file compilation  
# - Simulation execution
# - Waveform configuration
# - Results analysis
#******************************************************************************

# Script configuration
set project_name "divide_by_3_sim"
set project_dir "."
set sim_time "2000000ns"

# File paths (relative to project root)
set design_files {
    "src/top.sv"
}

set sim_files {
    "sim/tb.sv"  
}

puts "=========================================="
puts "Divide-by-3 Clock Divider Simulation"
puts "=========================================="
puts "Project: $project_name"
puts "Simulation Time: $sim_time" 
puts "=========================================="

# Create project if it doesn't exist
if {![file exists $project_dir/$project_name]} {
    puts "Creating new project: $project_name"
    create_project $project_name $project_dir/$project_name -part xc7a35tcpg236-1 -force
    
    # Set project properties
    set_property target_language SystemVerilog [current_project]
    set_property simulator_language Mixed [current_project]
    set_property default_lib xil_defaultlib [current_project]
} else {
    puts "Opening existing project: $project_name"
    open_project $project_dir/$project_name/$project_name.xpr
}

# Add design sources
puts "Adding design sources..."
foreach file $design_files {
    if {[file exists $file]} {
        add_files -norecurse $file
        puts "  Added: $file"
    } else {
        puts "  WARNING: File not found: $file"
    }
}

# Add simulation sources  
puts "Adding simulation sources..."
foreach file $sim_files {
    if {[file exists $file]} {
        add_files -fileset sim_1 -norecurse $file
        puts "  Added: $file"
    } else {
        puts "  WARNING: File not found: $file"
    }
}

# Set top module for simulation
set_property top tb [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

# Update compile order
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "----------------------------------------"
puts "Starting simulation compilation..."
puts "----------------------------------------"

# Launch simulation
if {[catch {launch_simulation} result]} {
    puts "ERROR: Simulation failed to launch"
    puts $result
    return -1
}

puts "Simulation launched successfully"

# Wait for simulation to be ready
after 2000

# Configure waveform display
puts "Configuring waveform display..."

# Add all testbench signals
add_wave {{/tb/clk}}
add_wave {{/tb/rst}}  
add_wave {{/tb/clk_dev_3}}

# Add DUT internal signals
add_wave -divider "Counter 1"
add_wave {{/tb/DUT/current_state_1}}
add_wave {{/tb/DUT/out_1}}

add_wave -divider "Counter 2"  
add_wave {{/tb/DUT/current_state_2}}
add_wave {{/tb/DUT/out_2}}

add_wave -divider "Output"
add_wave {{/tb/DUT/y}}

# Set radix for state signals
set_property RADIX UNSIGNED [get_waves /tb/DUT/current_state_1]
set_property RADIX UNSIGNED [get_waves /tb/DUT/current_state_2]

# Configure waveform appearance
configure_wave -namecolwidth 250
configure_wave -valuecolwidth 100
configure_wave -justifyvalue left
configure_wave -signalnamewidth 1
configure_wave -snapdistance 10
configure_wave -datasetprefix 0
configure_wave -rowmargin 4
configure_wave -childrowmargin 2

puts "----------------------------------------"
puts "Running simulation for $sim_time..."
puts "----------------------------------------"

# Run simulation
run $sim_time

puts "Simulation completed"

# Zoom to fit all signals
wave zoom full

# Save waveform configuration
if {[catch {save_wave_config simulation.wcfg} result]} {
    puts "WARNING: Could not save waveform configuration"
} else {
    puts "Waveform configuration saved to simulation.wcfg"
}

puts "=========================================="
puts "Simulation Summary"
puts "=========================================="

# Extract key timing information from simulation
set current_time [current_time]
puts "Final simulation time: $current_time"

# Check if simulation completed successfully
if {$current_time >= [string trimright $sim_time "ns"]} {
    puts "Status: COMPLETED"
    puts "Result: Check console output for test results"
} else {
    puts "Status: TERMINATED EARLY"
    puts "WARNING: Simulation may have encountered errors"
}

puts "=========================================="
puts "Post-Simulation Analysis"
puts "=========================================="

# Basic waveform analysis (if simulation completed)
if {$current_time >= [string trimright $sim_time "ns"]} {
    
    # Measure output frequency (simple check)
    puts "Performing basic waveform analysis..."
    
    # Get signal values at specific times (example)
    set clk_transitions 0
    set output_transitions 0
    
    # Note: More sophisticated analysis would require custom Tcl procedures
    # For now, we rely on the testbench self-checking
    
    puts "Analysis complete - see testbench output for detailed results"
}

puts "=========================================="
puts "Next Steps"
puts "=========================================="
puts "1. Review simulation console output for test results"
puts "2. Examine waveforms in the GUI"
puts "3. Verify timing relationships"
puts "4. Check duty cycle measurements"
puts ""
puts "To re-run simulation:"
puts "  restart"
puts "  run $sim_time"
puts ""
puts "To close project:"
puts "  close_sim"
puts "  close_project"
puts "=========================================="

# Optional: Generate timing report
proc generate_timing_report {} {
    puts "Generating timing analysis report..."
    
    # This would require synthesis - commented out for simulation-only flow
    # synth_design -top dev_3
    # report_timing_summary -file timing_report.txt
    
    puts "Note: Timing analysis requires synthesis flow"
    puts "Use 'synth_design -top dev_3' followed by 'report_timing_summary'"
}

# Optional: Automated test result parsing
proc parse_test_results {} {
    puts "Parsing test results from simulation log..."
    
    # Search for PASS/FAIL patterns in simulation output
    set log_content [get_log]
    
    set freq_test_pass [regexp {Frequency.*PASS} $log_content]
    set duty_test_pass [regexp {Duty cycle.*PASS} $log_content]
    
    puts "Test Results Summary:"
    puts "  Frequency Test: [expr {$freq_test_pass ? "PASS" : "FAIL/NOT FOUND"}]"
    puts "  Duty Cycle Test: [expr {$duty_test_pass ? "PASS" : "FAIL/NOT FOUND"}]"
    
    if {$freq_test_pass && $duty_test_pass} {
        puts "Overall Result: ALL TESTS PASSED ✓"
        return 0
    } else {
        puts "Overall Result: SOME TESTS FAILED ✗"
        return 1
    }
}

# Make utility functions available
puts ""
puts "Additional commands available:"
puts "  generate_timing_report  - Generate timing analysis"  
puts "  parse_test_results      - Parse and summarize test results"

# End of script
puts ""
puts "Simulation script completed successfully"