module instruction_queue (
    input  wire        clk,         
    input  wire        rst_n,       
    input  wire        write_en,    
    input  wire        dequeue_en,     
    input  wire [11:0] instr_in,    
    output wire [11:0] instr_out,   
    output wire        full,        
    output wire        empty        
);

reg [11:0] instr_out_reg;
reg [11:0] queue [0:7];
reg [2:0]  head, tail;
reg        is_full, is_empty;
reg        stop_writing;
assign instr_out = queue[head];

assign full = is_full;
assign empty = is_empty;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin

        head <= 3'd0;
        tail <= 3'd0;
        is_full <= 1'b0;
        is_empty <= 1'b1;
        stop_writing <= 1'b0;
        
        for (int i = 0; i < 8; i++) begin
            queue[i] <= 12'd0;
        end
    end else begin
        if (dequeue_en && !is_empty) begin
            // instr_out_reg <= queue[head];   
            head <= (head == 3'd7) ? 3'd0 : head + 1;
            is_full <= 1'b0;

            if ((head + 1 == tail) || (head == 3'd7 && tail == 3'd0))
                is_empty <= 1'b1;
            else
                is_empty <= 1'b0; 
        end

        if (write_en && !stop_writing) begin
            if (instr_in[11:9] == 3'b111) begin
                stop_writing <= 1'b1; 
            end else if (!is_full) begin
                queue[tail] <= instr_in;
                tail <= (tail == 3'd7) ? 3'd0 : tail + 1;

                is_empty <= 1'b0;
                if ((tail + 1 == head) || (tail == 3'd7 && head == 3'd0))
                    is_full <= 1'b1;
                else
                    is_full <= 1'b0;
            end
        end
    end
end

endmodule