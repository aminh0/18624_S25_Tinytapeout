module register_alias_table (
    input  logic       clk,
    input  logic       rst_n,

    // Write (new mapping)
    input  logic       update_en,
    input  logic [2:0] dest_reg,
    input  logic [1:0] rob_tail,

    // Commit (restore mapping)
    input  logic       commit_en,
    input  logic [2:0] commit_reg,

    // Read (decode source operands)
    input  logic [2:0] src1_reg,
    input  logic [2:0] src2_reg,

    output logic       src1_ready,
    output logic       src2_ready,
    output logic [1:0] src1_rob,
    output logic [1:0] src2_rob
);

  typedef struct packed {
    logic valid;           // valid = 0 -> register file
    logic [1:0] rob_idx;   // rob result
  } rat_entry_t;

  rat_entry_t rat [0:7]; // 8 general-purpose registers

  // Source operand lookup
  assign src1_ready = !rat[src1_reg].valid;
  assign src2_ready = !rat[src2_reg].valid;
  assign src1_rob   = rat[src1_reg].rob_idx;
  assign src2_rob   = rat[src2_reg].rob_idx;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i = 0; i < 8; i++) begin
        rat[i].valid <= 1'b0; 
        rat[i].rob_idx <= 2'b00;
      end
    end else begin

      // Commit:
      if (commit_en) begin
        rat[commit_reg].valid <= 1'b0;
      end

      // Update
      if (update_en) begin
        rat[dest_reg].valid <= 1'b1;
        rat[dest_reg].rob_idx <= rob_tail;
      end

    end
  end

endmodule