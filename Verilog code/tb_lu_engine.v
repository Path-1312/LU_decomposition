`timescale 1ns / 1ps

module tb_lu_engine();
    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 4;
    
    reg clk;
    reg rst_n;
    reg start;
    wire done;
    
    lu_engine_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .MATRIX_SIZE(4)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .done(done)
    );
    
    always #5 clk = ~clk;
    
    reg [DATA_WIDTH-1:0] golden_memory [0:15];
    integer i;
    integer errors;
    
    initial begin
        clk = 0;
        rst_n = 0;
        start = 0;
        errors = 0;
        
        $readmemh("C:/Users/Path Bhimani/ld_decomposition/generate_lu/matrix_in.txt", dut.bram_inst.ram);
        $readmemh("C:/Users/Path Bhimani/ld_decomposition/generate_lu/golden_lu.txt", golden_memory);
        
        #20 rst_n = 1;
        #10 start = 1;
        #10 start = 0;
        
        @(posedge done);
        #20;

        for (i = 0; i < 16; i = i + 1) begin
            if ($signed(dut.bram_inst.ram[i]) < $signed(golden_memory[i]) - 16 || 
                $signed(dut.bram_inst.ram[i]) > $signed(golden_memory[i]) + 16) begin
                $display("ERROR at index %0d: Expected %h, Got %h", i, golden_memory[i], dut.bram_inst.ram[i]);
                errors = errors + 1;
            end
        end
        
        if (errors == 0)
            $display("SIMULATION SUCCESS: All LU elements match golden model!");
        else
            $display("SIMULATION FAILED with %0d errors.", errors);
            
        $finish;
    end
endmodule