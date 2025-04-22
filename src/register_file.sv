module register_file (
    input  logic        clk,
    input  logic        rst_n,

    // Write (commit stage)
    input  logic        write_en,
    input  logic [2:0]  write_addr,
    input  logic [2:0]  write_data,

    // Read (decode stage)
    input  logic [2:0]  read_addr1,
    input  logic [2:0]  read_addr2,
  	input  logic [2:0]  final_addr,
    output logic [2:0]  read_data1,
    output logic [2:0]  read_data2,
  	output logic [2:0]  final_data
);

  logic [2:0] rf [0:7]; // 8 general-purpose 3-bit registers

  // Async read
  assign read_data1 = rf[read_addr1];
  assign read_data2 = rf[read_addr2];
  assign final_data = rf[final_addr];

  // Sync write on commit
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i = 0; i < 8; i++) begin
        rf[i] <= i;
      end
    end else if (write_en) begin
      rf[write_addr] <= write_data; 
    end
  end

endmodule
