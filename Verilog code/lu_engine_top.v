`timescale 1ns / 1ps

module dual_port_bram #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4
)(
    input wire clk,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout
);
    reg [DATA_WIDTH-1:0] ram [0:(1<<ADDR_WIDTH)-1];
    
    always @(posedge clk) begin
        if (we) begin
            ram[addr] <= din;
        end
    end
    
    assign dout = ram[addr];
endmodule

module lu_engine_top #(
    parameter DATA_WIDTH = 32,
    parameter MATRIX_SIZE = 4
)(
    input wire clk,
    input wire rst_n,
    input wire start,
    output reg done
);
    localparam ADDR_WIDTH = 4;
    
    reg bram_we;
    reg [ADDR_WIDTH-1:0] bram_addr;
    reg [DATA_WIDTH-1:0] bram_din;
    wire [DATA_WIDTH-1:0] bram_dout;
    
    dual_port_bram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) bram_inst (
        .clk(clk),
        .we(bram_we),
        .addr(bram_addr),
        .din(bram_din),
        .dout(bram_dout)
    );
    
    localparam IDLE      = 3'd0;
    localparam READ_U    = 3'd1;
    localparam COMP_U    = 3'd2;
    localparam READ_L    = 3'd3;
    localparam COMP_L    = 3'd4;
    localparam FINISH    = 3'd5;
    
    reg [2:0] state;
    reg [2:0] k, i, j, s;
    reg signed [DATA_WIDTH-1:0] sum_reg;
    reg signed [DATA_WIDTH-1:0] val_ik;
    reg signed [63:0] mult_temp;
    reg signed [63:0] div_temp;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            done <= 0;
            bram_we <= 0;
            k <= 0; i <= 0; j <= 0; s <= 0;
        end else begin
            bram_we <= 0;
            
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        k <= 0;
                        j <= 0;
                        state <= READ_U;
                    end
                end
                
                READ_U: begin
                    if (j < MATRIX_SIZE) begin
                        bram_addr <= (k * MATRIX_SIZE) + j;
                        s <= 0;
                        state <= COMP_U;
                    end else begin
                        i <= k + 1;
                        state <= READ_L;
                    end
                end
                
                COMP_U: begin
                    if (s == 0) begin
                        sum_reg <= $signed(bram_dout);
                        if (k == 0) begin
                            j <= j + 1;
                            state <= READ_U;
                        end else begin
                            s <= s + 1;
                        end
                    end else if (s <= k) begin
                        mult_temp = $signed(bram_inst.ram[(k * MATRIX_SIZE) + (s - 1)]) * 
                                    $signed(bram_inst.ram[((s - 1) * MATRIX_SIZE) + j]);
                        sum_reg <= sum_reg - mult_temp[47:16];
                        
                        if (s == k) begin
                            bram_we <= 1;
                            bram_addr <= (k * MATRIX_SIZE) + j;
                            bram_din <= sum_reg - mult_temp[47:16];
                            j <= j + 1;
                            state <= READ_U;
                        end else begin
                            s <= s + 1;
                        end
                    end
                end
                
                READ_L: begin
                    if (i < MATRIX_SIZE) begin
                        bram_addr <= (i * MATRIX_SIZE) + k;
                        s <= 0;
                        state <= COMP_L;
                    end else begin
                        k <= k + 1;
                        if (k + 1 < MATRIX_SIZE) begin
                            j <= k + 1;
                            state <= READ_U;
                        end else begin
                            state <= FINISH;
                        end
                    end
                end
                
                COMP_L: begin
                    if (s == 0) begin
                        sum_reg <= $signed(bram_dout);
                        if (k == 0) begin
                            div_temp = ($signed(bram_dout) <<< 16);
                            bram_we <= 1;
                            bram_addr <= (i * MATRIX_SIZE) + k;
                            bram_din <= div_temp / $signed(bram_inst.ram[(k * MATRIX_SIZE) + k]);
                            i <= i + 1;
                            state <= READ_L;
                        end else begin
                            s <= s + 1;
                        end
                    end else if (s <= k) begin
                        mult_temp = $signed(bram_inst.ram[(i * MATRIX_SIZE) + (s - 1)]) * 
                                    $signed(bram_inst.ram[((s - 1) * MATRIX_SIZE) + k]);
                        sum_reg <= sum_reg - mult_temp[47:16];
                        
                        if (s == k) begin
                            val_ik = sum_reg - mult_temp[47:16];
                            div_temp = (val_ik <<< 16);
                            bram_we <= 1;
                            bram_addr <= (i * MATRIX_SIZE) + k;
                            bram_din <= div_temp / $signed(bram_inst.ram[(k * MATRIX_SIZE) + k]);
                            i <= i + 1;
                            state <= READ_L;
                        end else begin
                            s <= s + 1;
                        end
                    end
                end
                
                FINISH: begin
                    done <= 1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule