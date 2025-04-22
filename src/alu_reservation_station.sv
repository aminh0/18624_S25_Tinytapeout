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

  // Flattened reservation station entries
  logic        rs_busy   [0:1];
  logic [1:0]  rs_rob_idx[0:1];
  logic [2:0]  rs_opcode [0:1];
  logic [2:0]  rs_val1   [0:1];
  logic [2:0]  rs_val2   [0:1];
  logic [1:0]  rs_q1     [0:1];
  logic [1:0]  rs_q2     [0:1];
  logic        rs_rdy1   [0:1];
  logic        rs_rdy2   [0:1];

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
      if (!found_free && !rs_busy[i]) begin
        free_idx = i;
        found_free = 1;
      end
      if (exec_idx == -1 && rs_busy[i] && rs_rdy1[i] && rs_rdy2[i] && !alu_busy) begin
        exec_idx = i;
      end
    end
  end

  assign exec_opcode  = (exec_idx != -1) ? rs_opcode[exec_idx]  : 3'd0;
  assign exec_val1    = (exec_idx != -1) ? rs_val1[exec_idx]    : 3'd0;
  assign exec_val2    = (exec_idx != -1) ? rs_val2[exec_idx]    : 3'd0;
  assign exec_rob_idx = (exec_idx != -1) ? rs_rob_idx[exec_idx] : 2'd0;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i = 0; i < 2; i++) begin
        rs_busy[i]    <= 0;
        rs_rob_idx[i] <= 0;
        rs_opcode[i]  <= 0;
        rs_val1[i]    <= 0;
        rs_val2[i]    <= 0;
        rs_q1[i]      <= 0;
        rs_q2[i]      <= 0;
        rs_rdy1[i]    <= 0;
        rs_rdy2[i]    <= 0;
      end
      count <= 0;
    end else begin
      // CDB broadcast update
      for (int i = 0; i < 2; i++) begin
        if (rs_busy[i]) begin
          if (!rs_rdy1[i] && cdb_en && rs_q1[i] == cdb_rob_idx) begin
            rs_val1[i] <= cdb_val;
            rs_rdy1[i] <= 1;
          end
          if (!rs_rdy2[i] && cdb_en && rs_q2[i] == cdb_rob_idx) begin
            rs_val2[i] <= cdb_val;
            rs_rdy2[i] <= 1;
          end
        end
      end

      // Write entry
      if (write_en && found_free) begin
        rs_busy[free_idx]    <= 1;
        rs_rob_idx[free_idx] <= rob_idx;
        rs_opcode[free_idx]  <= opcode;
        rs_val1[free_idx]    <= val1;
        rs_val2[free_idx]    <= val2;
        rs_q1[free_idx]      <= q1;
        rs_q2[free_idx]      <= q2;
        rs_rdy1[free_idx]    <= ready1;
        rs_rdy2[free_idx]    <= ready2;
      end

      // Clear after execution (unless simultaneous write)
      if (exec_idx != -1 && !(rs_ready && write_en)) begin
        rs_busy[exec_idx] <= 0;
      end

      // Count update logic
      if (write_en && (exec_idx == -1)) begin
        count <= count + 1;
      end else if (!write_en && (exec_idx != -1)) begin
        count <= count - 1;
      end
      // else: write + exec → count unchanged
    end
  end
endmodule
