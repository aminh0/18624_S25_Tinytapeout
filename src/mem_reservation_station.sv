module mem_reservation_station (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        write_en,
    input  logic [1:0]  rob_idx,
    input  logic [2:0]  opcode,
    input  logic [2:0]  val1,
    input  logic [1:0]  q1,
    input  logic        ready1,

    input  logic        cdb_en,
    input  logic [1:0]  cdb_rob_idx,
    input  logic [2:0]  cdb_val,

    output logic        rs_ready,
    output logic [2:0]  exec_opcode,
    output logic [2:0]  exec_val1,
    output logic [1:0]  exec_rob_idx,
    output logic        rs_full
);

  typedef struct packed {
    logic        busy;
    logic [1:0]  rob_idx;
    logic [2:0]  opcode;
    logic [2:0]  val1;
    logic [1:0]  q1;
    logic        rdy1;
  } rs_entry_t;

  rs_entry_t rs;

  assign rs_full = rs.busy;
  assign rs_ready = rs.busy && rs.rdy1;

  assign exec_opcode  = rs.opcode;
  assign exec_val1    = rs.val1;
  assign exec_rob_idx = rs.rob_idx;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rs <= '{default: '0};
    end else begin
      if (rs.busy && !rs.rdy1 && cdb_en && rs.q1 == cdb_rob_idx) begin
        rs.val1 <= cdb_val;
        rs.rdy1 <= 1;
      end

      if (write_en && !rs.busy) begin
        rs.busy    <= 1;
        rs.rob_idx <= rob_idx;
        rs.opcode  <= opcode;
        rs.val1    <= val1;
        rs.q1      <= q1;
        rs.rdy1    <= ready1;
      end

      if (rs_ready) begin
        rs.busy <= 0;
      end
    end
  end
endmodule