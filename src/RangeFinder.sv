module RangeFinder 
  #(parameter WIDTH=16)
    (input logic [WIDTH-1:0] data_in,
     input logic             clock, reset,
     input logic             go, finish,
     output logic [WIDTH-1:0] range,
     output logic            debug_error,
     output logic [WIDTH-1:0] high_q,  // Add max_value as high_q
     output logic [WIDTH-1:0] low_q    // Add min_value as low_q
    );

    // Registers to store the current maximum and minimum values
    logic [WIDTH-1:0] max_value;
    logic [WIDTH-1:0] min_value;
    logic go_active;  // Track whether a valid sequence has started

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            max_value <= {WIDTH{1'b0}};  // Reset max_value to minimum
            min_value <= {WIDTH{1'b1}};  // Reset min_value to maximum
            range <= {WIDTH{1'b0}};
            debug_error <= 1'b0;
            go_active <= 1'b0;
        end
        else begin
            if (go) begin
                // Start a new sequence
                go_active <= 1'b1;
                debug_error <= 1'b0;  // Clear any previous error state

                // Initialize max and min values on the first valid input
                if (data_in > max_value)
                    max_value <= data_in;
                if (data_in < min_value)
                    min_value <= data_in;
            end
            else if (go_active) begin
                // Update max and min values while go_active is true
                if (data_in > max_value)
                    max_value <= data_in;
                if (data_in < min_value)
                    min_value <= data_in;
            end

            if (finish) begin
                if (!go_active) begin
                    // Error: finish without a valid go
                    debug_error <= 1'b1;
                end else begin
                    // Compute the range
                    range <= max_value - min_value;
                end
                go_active <= 1'b0;  // Reset sequence state
            end
        end
    end

    assign high_q = max_value;
    assign low_q = min_value;
    
endmodule : RangeFinder