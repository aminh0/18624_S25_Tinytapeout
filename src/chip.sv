

`timescale 10ns / 10ps

// `include "instruction_queue.sv"
// `include "register_file.sv"
// `include "register_alias_table.sv"
// `include "alu_unit.sv"
// `include "alu_reservation_station.sv"
// `include "mem_reservation_station.sv"
// `include "reorder_buffer.sv"
// `include "memory_unit.sv"

module my_chip (
    input logic [11:0] io_in, // Inputs to your chip
    output logic [11:0] io_out, // Outputs from your chip
    input logic clock,
    input logic reset // Important: Reset is ACTIVE-HIGH
);
    logic clk;
    logic rst_n;
    logic [11:0] instr_in;
    logic [5:0] cycle_count;
    logic [2:0] reg_out_addr;
    logic [2:0] reg_out_data;

    assign clk = clock;
    assign rst_n = ~reset;
    assign instr_in = io_in[11:0];
    assign io_out[11:0] = {cycle_count, reg_out_addr, reg_out_data};
    
    // Basic counter design as an example
    // TODO: remove the counter design and use this module to insert your own design
    localparam ADD = 3'b000;
    localparam SUB = 3'b001;
    localparam AND = 3'b010;
    localparam OR  = 3'b011;
    localparam XOR = 3'b100;
    localparam LD  = 3'b101;
    localparam STR = 3'b110;
    
    
    // IQ
    wire [11:0] iq_head_instr;
    wire        is_mem_op;
    wire        iq_write_en;
    wire        iq_dequeue_en;
    wire        iq_full, iq_empty;


    wire        alu_rs_ready;
    wire        alu_rs_full; 

    wire        mem_rs_ready;   
    wire        mem_rs_full;    
    wire [2:0]  mem_opcode;     
    wire [2:0]  mem_addr;       
    wire [1:0]  mem_rob_idx_in;

    //RF
    wire [2:0]  rf_value;
    wire [2:0]  rf_addr;

    // RAT
    wire        rat_update_en;
    wire [2:0]  rat_dest_reg;
    wire [1:0]  rat_rob_idx;
    wire        rat_src1_ready, rat_src2_ready;
    wire [2:0]  rat_src1_val, rat_src2_val;
    wire [1:0]  rat_src1_rob, rat_src2_rob;

    // RS
    wire        rs_write_en;
    wire [2:0]  rs_opcode;
    wire [2:0]  rs_val1, rs_val2;
    wire [1:0]  rs_rob_idx;
    wire [1:0]  alu_rs_count;

    // ROB
    wire        rob_write_en, rob_commit_en;
    wire        rob_full, rob_empty;
    wire [1:0]  rob_tail;
    wire [1:0]  rob_head;
    wire        rob_head_ready;
    wire [2:0]  rob_head_dest;
    wire [2:0]  rob_head_value;
    wire [2:0]  rob_head_opcode;
    wire [2:0]  rob_count;
    wire will_write_rob;



    // ALU
    wire        alu_busy, mem_busy;
    wire        alu_done, mem_done;
    wire [1:0]  alu_rob_idx;
    wire [2:0]  alu_result, mem_result;

    wire [2:0] opcode, dest_reg, src1_reg, src2_reg;


    assign opcode = iq_head_instr[11:9];
    assign dest_reg = iq_head_instr[8:6];
    assign src1_reg = iq_head_instr[5:3];
    assign src2_reg = iq_head_instr[2:0];
    assign is_mem_op = (iq_head_instr[11:9] == 3'b110) || (iq_head_instr[11:9] == 3'b101);
    //fetch
    assign iq_write_en = !iq_full;

    // DECODE/ISSUE
    // assign iq_dequeue_en = !iq_empty && 
    // ((is_mem_op && !mem_rs_full) ||
    // (!is_mem_op && !alu_rs_full)) &&
    // !rob_full; //IQ
    assign will_write_rob = ((is_mem_op && !mem_rs_full) || (!is_mem_op && !alu_rs_full));

    assign iq_dequeue_en = !iq_empty && will_write_rob && (rob_count < 3) && (alu_rs_count < 1); 
    logic iq_dequeue_en_d1;
    always_ff @(posedge clk or negedge rst_n) begin

    if (!rst_n)
        iq_dequeue_en_d1 <= 1'b0;
    else
        iq_dequeue_en_d1 <= iq_dequeue_en;
    end

    assign rs_write_en  = iq_dequeue_en_d1;
    assign rob_write_en = iq_dequeue_en_d1;
    assign rat_update_en = iq_dequeue_en_d1 && (opcode != STR);
    assign rat_rob_idx = rob_tail;// update the des reg in RAT
    assign rat_dest_reg = dest_reg;// update the des reg in RAT

    // COMMIT
    assign rob_commit_en = rob_head_ready && !rob_empty;

    instruction_queue iq (
        .clk(clk),
        .rst_n(rst_n),
        .write_en(iq_write_en),
        .dequeue_en(iq_dequeue_en),
        .instr_in(instr_in),
        .instr_out(iq_head_instr),
        .full(iq_full),
        .empty(iq_empty)
    );

    register_alias_table rat (
        .clk(clk),
        .rst_n(rst_n),
        .update_en(rat_update_en),
        .dest_reg(dest_reg),
        .rob_tail(rob_tail),
        .commit_en(rob_commit_en),
        .commit_reg(rob_head_dest),
        .src1_reg(src1_reg),
        .src2_reg(src2_reg),
        .src1_ready(rat_src1_ready),
        .src2_ready(rat_src2_ready),
        .src1_rob(rat_src1_rob),
        .src2_rob(rat_src2_rob)
    );

    register_file rf (
        .clk(clk),
        .rst_n(rst_n),
        .write_en(rob_commit_en),
        .write_addr(rob_head_dest),
        .write_data(rob_head_value),
        .read_addr1(src1_reg),
        .read_addr2(src2_reg),
        .final_addr(rf_addr),
        .read_data1(rat_src1_val),
        .read_data2(rat_src2_val),
        .final_data(rf_value)
    );



    reorder_buffer rob (
        .clk(clk),
        .rst_n(rst_n),
        .write_en(rob_write_en),
        .opcode(opcode),
        .dest_reg(dest_reg),
        .alu_complete(alu_done),
        .alu_rob_idx(alu_rob_idx),
        .alu_result(alu_result),
        .mem_complete(mem_done),
        .mem_rob_idx(mem_rob_idx),
        .mem_result(mem_result),
        .commit_en(rob_commit_en),
        .full(rob_full),
        .empty(rob_empty),
        .tail(rob_tail),
        .head(rob_head),
        .head_ready(rob_head_ready),
        .head_dest(rob_head_dest),
        .head_value(rob_head_value),
        .head_opcode(rob_head_opcode),
        .count(rob_count)
    );

    alu_reservation_station alu_rs (
        .clk(clk),
        .rst_n(rst_n),
        .write_en(rs_write_en && !is_mem_op),
        .rob_idx(rob_tail),
        .opcode(opcode),
        .val1(rat_src1_val),
        .val2(rat_src2_val),
        .q1(rat_src1_rob),
        .q2(rat_src2_rob),
        .ready1(rat_src1_ready),
        .ready2(rat_src2_ready),
        .cdb_en(alu_done || mem_done),
        .cdb_rob_idx(alu_done ? alu_rob_idx : mem_rob_idx),
        .cdb_val(alu_done ? alu_result : mem_result),
        .alu_busy(alu_busy),
        .rs_ready(alu_rs_ready),
        .exec_opcode(rs_opcode),
        .exec_val1(rs_val1),
        .exec_val2(rs_val2),
        .exec_rob_idx(rs_rob_idx),
        .rs_full(alu_rs_full),
        .count(alu_rs_count)
    );

    alu_unit alu (
        .clk(clk),
        .rst_n(rst_n),
        .start(alu_rs_ready),
        .opcode(rs_opcode),
        .val1(rs_val1),
        .val2(rs_val2),
        .rob_idx(rs_rob_idx),
        .busy(alu_busy),
        .done(alu_done),
        .result(alu_result),
        .result_rob_idx(alu_rob_idx)
    );

    mem_reservation_station mem_rs (
        .clk(clk),
        .rst_n(rst_n),
        .write_en(rs_write_en && is_mem_op),
        .rob_idx(rob_tail),
        .opcode(opcode),
        .val(rat_src1_val),                  // STR data
        .q_val(rat_src1_rob),
        .val_ready(rat_src1_ready),
        .addr(src2_reg[1:0]),                // address = instr[2:0] = src2

        .cdb_en(alu_done || mem_done),
        .cdb_rob_idx(alu_done ? alu_rob_idx : mem_rob_idx),
        .cdb_val(alu_done ? alu_result : mem_result),

        .rs_ready(mem_rs_ready),
        .exec_opcode(mem_opcode),
        .exec_val(mem_data),                // STR data
        .exec_addr(mem_addr),
        .exec_rob_idx(mem_rob_idx_in),
        .rs_full(mem_rs_full)
    );

    memory_unit mem (
        .clk(clk),
        .rst_n(rst_n),
        .start_read(mem_rs_ready && (mem_opcode == LD)),
        .start_write(mem_rs_ready && (mem_opcode == STR)),
        .addr(mem_addr),
        .write_data(rat_src1_val),
        .rob_idx_in(mem_rob_idx_in),
        .busy(mem_busy),
        .done(mem_done),
        .read_data(mem_result),
        .rob_idx_out(mem_rob_idx)
    );

    logic done;            
    logic [2:0] reg_idx;   
    logic printing_regs;    
    logic [5:0] cycle_counter_internal;
    logic [5:0] final_cycle_count;


    assign done = iq_empty && rob_empty && (alu_rs_count == 0) && !mem_rs_full;


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            printing_regs <= 0;
            reg_idx <= 3'd0;
            final_cycle_count <= 6'd0;
            cycle_counter_internal <= 6'd0;
        end else begin
                cycle_counter_internal <= cycle_counter_internal + 1;
            

            if (done && !printing_regs) begin
                printing_regs <= 1;
                final_cycle_count <= cycle_counter_internal;
                reg_idx <= 3'd0;
            end else if (printing_regs && reg_idx < 3'd7) begin
                reg_idx <= reg_idx + 1;
            end else if (printing_regs && reg_idx == 3'd7) begin
                printing_regs <= 0;
            end
        end
    end
    assign reg_out_addr = reg_idx;
    assign rf_addr = reg_idx;
    assign reg_out_data = rf_value;
    assign cycle_count = printing_regs ? final_cycle_count : cycle_counter_internal;



endmodule
