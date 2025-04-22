module alu_unit (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        start,
    input  logic [2:0]  opcode,
    input  logic [2:0]  val1,
    input  logic [2:0]  val2,
    input  logic [1:0]  rob_idx,

    output logic        busy,
    output logic        done,
    output logic [2:0]  result,
    output logic [1:0]  result_rob_idx
);

  typedef enum logic [1:0] {
    IDLE  = 2'd0,
    EX1   = 2'd1,
  } state_t;

  state_t state;
  logic [2:0] operand1, operand2;
  logic [2:0] opcode_reg;
  logic [1:0] rob_idx_reg;
  logic [2:0] alu_result;

  assign busy = (state != IDLE);
  assign result = alu_result;
  assign result_rob_idx = rob_idx_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      done <= 0;
    end else begin
      case (state)
        IDLE: begin
          done <= 0;
          if (start) begin
            operand1 <= val1;
            operand2 <= val2;
            opcode_reg <= opcode;
            rob_idx_reg <= rob_idx;
            state <= EX1;
          end
        end
        EX1: begin
          // perform ALU operation
          case (opcode_reg)
            3'b000: alu_result <= operand1 + operand2; // ADD
            3'b001: alu_result <= operand1 - operand2; // SUB
            3'b010: alu_result <= operand1 & operand2; // AND
            3'b011: alu_result <= operand1 | operand2; // OR
            3'b100: alu_result <= operand1 ^ operand2; // XOR
            default: alu_result <= 3'd0;
          endcase
          done <= 1;
          state <= IDLE;
        end
      endcase
    end
  end

endmodule