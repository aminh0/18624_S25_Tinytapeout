`default_nettype none

module my_chip (
    input logic [11:0] io_in, // Inputs to your chip
    output logic [11:0] io_out, // Outputs from your chip
    input logic clock,
    input logic reset // Important: Reset is ACTIVE-HIGH
);
    
    // Basic counter design as an example
    // TODO: remove the counter design and use this module to insert your own design
    // DO NOT change the I/O header of this design


    RangeFinder #(.WIDTH(10)) rf_inst ( 
        .data_in(io_in[9:0]),     
        .clock(clock),
        .reset(reset),
        .go(io_in[10]),          
        .finish(io_in[11]),    
        .range(io_out[9:0]),      
        .debug_error(io_out[10]), 
        .high_q(),               
        .low_q()               
    );

endmodule
