module mem_reservation_station (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        write_en,
    input  logic [1:0]  rob_idx,
    input  logic [2:0]  opcode,      // LD or STR
    input  logic [2:0]  val,         // value to be written
    input  logic [1:0]  q_val,       
    input  logic        val_ready,   // ready signal
    input  logic [1:0]  addr,        // memory address

    input  logic        cdb_en,
    input  logic [1:0]  cdb_rob_idx,
    input  logic [2:0]  cdb_val,

    output logic        rs_ready,
    output logic [2:0]  exec_opcode,
    output logic [2:0]  exec_val,     // value to be written
    output logic [1:0]  exec_addr,    // memory address 
    output logic [1:0]  exec_rob_idx, // ROB idx
    output logic        rs_full
);

  // Flattened version of the reservation station entry
  logic        rs_busy;
  logic [1:0]  rs_rob_idx;
  logic [2:0]  rs_opcode;
  logic [2:0]  rs_val;
  logic [1:0]  rs_q_val;
  logic        rs_val_ready;
  logic [1:0]  rs_addr;

  assign rs_full = rs_busy;

  assign rs_ready = rs_busy && (
      (rs_opcode == 3'b101) ||                // LD
      (rs_opcode == 3'b110 && rs_val_ready)   // STR with data ready
  );

  assign exec_opcode    = rs_opcode;
  assign exec_val       = rs_val;
  assign exec_addr      = rs_addr;
  assign exec_rob_idx   = rs_rob_idx;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rs_busy       <= 0;
      rs_rob_idx    <= 2'b00;
      rs_opcode     <= 3'b000;
      rs_val        <= 3'b000;
      rs_q_val      <= 2'b00;
      rs_val_ready  <= 0;
      rs_addr       <= 2'b00;
    end else begin
      // CDB broadcast for STR value
      if (rs_busy && !rs_val_ready && rs_opcode == 3'b110 && cdb_en && rs_q_val == cdb_rob_idx) begin
        rs_val       <= cdb_val;
        rs_val_ready <= 1;
      end

      // Write new entry
      if (write_en && !rs_busy) begin
        rs_busy       <= 1;
        rs_rob_idx    <= rob_idx;
        rs_opcode     <= opcode;
        rs_val        <= val;
        rs_q_val      <= q_val;
        rs_val_ready  <= val_ready;
        rs_addr       <= addr;
      end

      // Clear entry if issued
      if (rs_ready) begin
        rs_busy <= 0;
      end
    end
  end

endmodule
