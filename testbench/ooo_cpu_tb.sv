`timescale 10ns / 10ns

module ooo_cpu_issue_tb;

  logic clk, reset;
  logic [11:0] io_in;
  wire [11:0] io_out;

  // Instantiate the DUT (Design Under Test)
  my_chip uut (
    .clock(clk),
    .reset(reset),
    .io_in(io_in),
    .io_out(io_out)
  );

  // Clock generation for 30MHz (period ≈ 33ns → ~16ns per half cycle)
  always #17 clk = ~clk;

  logic [11:0] instr_mem [0:7];
  int idx;

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, ooo_cpu_issue_tb);
    $dumpvars(0, uut);

    clk = 0;
    reset = 1;

    instr_mem[0] = {3'b101, 3'd0, 3'd0, 3'd0}; // LD R0, MEM[0]
    instr_mem[1] = {3'b000, 3'd1, 3'd0, 3'd2}; // ADD R1, R0, R2
    instr_mem[2] = {3'b001, 3'd4, 3'd5, 3'd3}; // SUB R4, R5, R3
    instr_mem[3] = {3'b011, 3'd4, 3'd6, 3'd7}; // OR  R4, R6, R7
    instr_mem[4] = {3'b101, 3'd6, 3'd6, 3'd2}; // LD  R6, MEM[2]
    instr_mem[5] = {3'b100, 3'd2, 3'd3, 3'd6}; // XOR R2, R3, R6
    instr_mem[6] = {3'b010, 3'd3, 3'd7, 3'd6}; // AND R3, R7, R6
    instr_mem[7] = {3'b111, 9'd0};            // HALT

    #30 reset = 0; // deassert reset after a few cycles
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      idx <= 0;
      io_in <= 12'd0;
    end else if (idx < 8) begin
      io_in <= instr_mem[idx];
      idx <= idx + 1;
    end else begin
      io_in <= 12'd0;
    end
  end

  initial begin
    #1300;
    $finish;
  end

endmodule
