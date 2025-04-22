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

  // Flattened RAT arrays
  logic rat_valid [0:7];
  logic [1:0] rat_rob_idx [0:7];

  // Source operand lookup
  assign src1_ready = !rat_valid[src1_reg];
  assign src2_ready = !rat_valid[src2_reg];
  assign src1_rob   = rat_rob_idx[src1_reg];
  assign src2_rob   = rat_rob_idx[src2_reg];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i = 0; i < 8; i++) begin
        rat_valid[i]   <= 1'b0;
        rat_rob_idx[i] <= 2'b00;
      end
    end else begin
      // Commit: clear mapping
      if (commit_en) begin
        rat_valid[commit_reg] <= 1'b0;
      end

      // Update: new mapping to ROB
      if (update_en) begin
        rat_valid[dest_reg]   <= 1'b1;
        rat_rob_idx[dest_reg] <= rob_tail;
      end
    end
  end

endmodule
