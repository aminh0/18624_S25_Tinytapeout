module memory_unit (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        start_read,
    input  logic        start_write,
    input  logic [1:0]  addr,
    input  logic [2:0]  write_data,
    input  logic [1:0]  rob_idx_in,

    output logic        busy,
    output logic        done,
    output logic [2:0]  read_data,
    output logic [1:0]  rob_idx_out
);

  // memory array: 4 entries of 3-bit each
  logic [2:0] mem [0:3];

  // FSM states
  typedef enum logic [2:0] {
    IDLE  = 3'd0,
    C1    = 3'd1,
    C2    = 3'd2,
    C3    = 3'd3,
    C4    = 3'd4
  } state_t;

  state_t state;

  // internal registers
  logic [2:0] temp_data;
  logic       is_read; 
  logic [1:0] addr_reg;
  logic [2:0] write_data_reg;
  logic [1:0] rob_idx_reg;

  assign read_data = (done && is_read) ? temp_data : 3'd0;
  assign rob_idx_out = (done) ? rob_idx_reg : 2'd0;
  assign busy = (state != IDLE);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      done <= 0;
      is_read<= 0;
      rob_idx_reg <= 2'd0;
      for (int i = 0; i < 4; i++) begin
        mem[i] <= i; // for debug: initialize memory with known values
      end
    end else begin
      done <= 0;

      case (state)
        IDLE: begin
          if (start_read || start_write) begin
            addr_reg <= addr;
            write_data_reg <= write_data;
            rob_idx_reg <= rob_idx_in;
            is_read <= start_read;
            state <= C1;
          end
        end
        C1: state <= C2;
        C2: state <= C3;
        C3: state <= C4;
        C4: begin
          if (is_read) begin
            temp_data <= mem[addr_reg];
          end else begin
            mem[addr_reg] <= write_data_reg;
          end
          done <= 1;
          state <= IDLE;
        end
      endcase
    end
  end

endmodule