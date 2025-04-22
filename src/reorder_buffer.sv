module reorder_buffer (
    input  logic        clk,
    input  logic        rst_n,

    // Instruction dispatch
    input  logic        write_en,
    input  logic [2:0]  opcode,
    input  logic [2:0]  dest_reg,

    // ALU completion
    input  logic        alu_complete,
    input  logic [1:0]  alu_rob_idx,
    input  logic [2:0]  alu_result,

    // MEM completion
    input  logic        mem_complete,
    input  logic [1:0]  mem_rob_idx,
    input  logic [2:0]  mem_result,

    // Commit
    input  logic        commit_en,

    output logic        full,
    output logic        empty,
    output logic [1:0]  tail,
    output logic [1:0]  head,
    output logic        head_ready,
    output logic [2:0]  head_dest,
    output logic [2:0]  head_value,
    output logic [2:0]  head_opcode,
    output logic [2:0]  count
);

  logic valid     [0:3];
  logic ready     [0:3];
  logic [2:0] op  [0:3];
  logic [2:0] dst [0:3];
  logic [2:0] val [0:3];

  logic do_write;
  logic do_commit;

  assign do_write  = write_en && !full;
  assign do_commit = commit_en && valid[head] && ready[head];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      head <= 0;
      tail <= 0;
      count <= 0;
      for (int i = 0; i < 4; i++) begin
        valid[i] <= 0;
        ready[i] <= 0;
        op[i]    <= 3'd0;
        dst[i]   <= 3'd0;
        val[i]   <= 3'd0;
      end
    end else begin
      for (int i = 0; i < 4; i++) begin
        if (valid[i] && !ready[i]) begin
          if (alu_complete && alu_rob_idx == i[1:0]) begin
            val[i] <= alu_result;
            ready[i] <= 1;
          end else if (mem_complete && mem_rob_idx == i[1:0]) begin
            val[i] <= mem_result;
            ready[i] <= 1;
          end
        end
      end

      if (do_write) begin
        valid[tail] <= 1;
        ready[tail] <= 0;
        op[tail]    <= opcode;
        dst[tail]   <= dest_reg;
        val[tail]   <= 3'd0;
        tail <= tail + 1;
      end

      if (do_commit) begin
        valid[head] <= 0;
        ready[head] <= 0;
        op[head]    <= 3'd0;
        dst[head]   <= 3'd0;
        val[head]   <= 3'd0;
        head <= head + 1;
      end

      case ({do_write, do_commit})
        2'b10: count <= count + 1;
        2'b01: count <= count - 1;
        default: count <= count;
      endcase
    end
  end

  assign full  = (count == 4);
  assign empty = (count == 0);

  assign head_ready = valid[head] && ready[head];
  assign head_dest  = dst[head];
  assign head_value = val[head];
  assign head_opcode = op[head];

endmodule
