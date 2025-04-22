module alu_reservation_station (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        write_en,
    input  logic [1:0]  rob_idx,
    input  logic [2:0]  opcode,
    input  logic [2:0]  val1,
    input  logic [2:0]  val2,
    input  logic [1:0]  q1,
    input  logic [1:0]  q2,
    input  logic        ready1,
    input  logic        ready2,

    input  logic        cdb_en,
    input  logic [1:0]  cdb_rob_idx,
    input  logic [2:0]  cdb_val,

    input  logic        alu_busy,

    output logic        rs_ready,
    output logic [2:0]  exec_opcode,
    output logic [2:0]  exec_val1,
    output logic [2:0]  exec_val2,
    output logic [1:0]  exec_rob_idx,
    output logic        rs_full,
    output logic [1:0]  count
);

  typedef struct packed {
    logic        busy;
    logic [1:0]  rob_idx;
    logic [2:0]  opcode;
    logic [2:0]  val1;
    logic [2:0]  val2;
    logic [1:0]  q1;
    logic [1:0]  q2;
    logic        rdy1;
    logic        rdy2;
  } rs_entry_t;

  rs_entry_t rs[0:1];

  logic       found_free;
  int         free_idx;
  int         exec_idx;

  assign rs_full = (count == 2);
  assign rs_ready = (exec_idx != -1);

  always_comb begin
    found_free = 0;
    free_idx = 0;
    exec_idx = -1;
    for (int i = 0; i < 2; i++) begin
      if (!found_free && !rs[i].busy) begin
        free_idx = i;
        found_free = 1;
      end
      if (exec_idx == -1 && rs[i].busy && rs[i].rdy1 && rs[i].rdy2 && !alu_busy) begin
        exec_idx = i;
      end
    end
  end

  assign exec_opcode  = (exec_idx != -1) ? rs[exec_idx].opcode : 3'd0;
  assign exec_val1    = (exec_idx != -1) ? rs[exec_idx].val1   : 3'd0;
  assign exec_val2    = (exec_idx != -1) ? rs[exec_idx].val2   : 3'd0;
  assign exec_rob_idx = (exec_idx != -1) ? rs[exec_idx].rob_idx: 2'd0;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i = 0; i < 2; i++) begin
        rs[i] <= '0;
      end
      count <= 0;
    end else begin
      // CDB broadcast
      for (int i = 0; i < 2; i++) begin
        if (rs[i].busy) begin
          if (!rs[i].rdy1 && cdb_en && rs[i].q1 == cdb_rob_idx) begin
            rs[i].val1 <= cdb_val;
            rs[i].rdy1 <= 1;
          end
          if (!rs[i].rdy2 && cdb_en && rs[i].q2 == cdb_rob_idx) begin
            rs[i].val2 <= cdb_val;
            rs[i].rdy2 <= 1;
          end
        end
      end

      // Write entry
      if (write_en && found_free) begin
        rs[free_idx].busy    <= 1;
        rs[free_idx].rob_idx <= rob_idx;
        rs[free_idx].opcode  <= opcode;
        rs[free_idx].val1    <= val1;
        rs[free_idx].val2    <= val2;
        rs[free_idx].q1      <= q1;
        rs[free_idx].q2      <= q2;
        rs[free_idx].rdy1    <= ready1;
        rs[free_idx].rdy2    <= ready2;
      end

      // Clear entry after execution
      if (exec_idx != -1) begin
        if(!(rs_ready && write_en)) begin
        	rs[exec_idx].busy <= 0;
        end
      end

      // Update count
      if (write_en && (exec_idx == -1)) count <= count + 1;
      else if (!write_en && (exec_idx != -1)) count <= count - 1;
      // write & exec both active → no count change
    end
  end
endmodule
