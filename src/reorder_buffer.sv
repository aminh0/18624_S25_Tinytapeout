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

  typedef struct packed {
    logic valid;
    logic ready;
    logic [2:0] opcode;
    logic [2:0] dest;
    logic [2:0] value;
  } rob_entry_t;

  rob_entry_t rob [0:3]; // 4-entry ROB

  logic do_write;
  logic do_commit;

  assign do_write  = write_en && !full;
  assign do_commit = commit_en && rob[head].valid && rob[head].ready;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      head <= 2'd0;
      tail <= 2'd0;
      count <= 3'd0;
      for (int i = 0; i < 4; i++) rob[i] <= '{default: '0};
    end else begin
      // ALU or MEM completion result broadcast
      for (int i = 0; i < 4; i++) begin
        if (rob[i].valid && !rob[i].ready) begin
          if (alu_complete && alu_rob_idx == i[1:0]) begin
            rob[i].value <= alu_result;
            rob[i].ready <= 1;
          end else if (mem_complete && mem_rob_idx == i[1:0]) begin
            rob[i].value <= mem_result;
            rob[i].ready <= 1;
          end
        end
      end

      // Dispatch
      if (do_write) begin
        rob[tail] <= '{valid: 1'b1, ready: 1'b0, opcode: opcode, dest: dest_reg, value: 3'b0};
        tail <= tail + 1;
      end

      // Commit
      if (do_commit) begin
        rob[head] <= '{default: '0};
        head <= head + 1;
      end

      // Update count
      case ({do_write, do_commit})
        2'b10: count <= count + 1;
        2'b01: count <= count - 1;
        default: count <= count;
      endcase
    end
  end

  assign full  = (count == 4);
  assign empty = (count == 0);

  assign head_ready = rob[head].valid && rob[head].ready;
  assign head_dest  = rob[head].dest;
  assign head_value = rob[head].value;
  assign head_opcode = rob[head].opcode;

endmodule
