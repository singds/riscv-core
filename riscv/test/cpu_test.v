
module cpu_test;

    reg clk;
    wire [31:0] inst_addr; // unused
    reg [31:0] inst_data;

    wire [31:0] data_addr, data_rd, data_wr;
    wire [3:0] data_wr_en;
    
    ram Ram (clk, data_wr_en, data_addr[21:0], data_wr, data_rd);

    cpu Cpu (clk, inst_addr, inst_data,
        data_addr, data_rd, data_wr, data_wr_en);

    reg [31:0] k; // variable for cycle
    reg [31:0] save;
    initial begin
        $dumpfile("cpu_test.vcd");
        $dumpvars(0,cpu_test);

        $display("TEST: cpu_test");
        $display("instructions sequence");

        clk = 0;
        inst_data = 0;

        testNop ( );
        testAddi ( );
        testStore ( );
        testJal ( );

        $finish(0);
    end

    task clkCycle;
    begin
        #1 clk = 1;
        #1 clk = 0;
    end
    endtask

    task exeInst;
        input [31:0] instruction;
    begin
        inst_data = instruction;
        clkCycle;
    end
    endtask

    // Test NOP operation
    task testNop;
    begin
        save = Cpu.pc;

        exeInst (32'h00000013); // nop
        assert (Cpu.pc == (save + 4));
        else $display("pc=%h", Cpu.pc);

        $display("ok: nop");
    end
    endtask

    // Test ADDI operation
    task testAddi;
    begin
        exeInst (32'h03400093); // addi x1, x0, 0x34
        assert (Cpu.xreg[1] == 32'h34);

        $display("ok: addi");
    end
    endtask

    // Test STORE operation
    task testStore;
    begin
        
        exeInst (32'h00100113); // li      x2,1

        // STORE 1 BYTE
        Ram.mem[0] = 32'hffffffff;
        exeInst (32'h00000093); // li      x1,0
        // store x2 in address x1 + 0
        exeInst (32'h00208023); // sb      x2,0(x1)
        assert (Ram.mem[0] == 32'hffffff01);

        Ram.mem[0] = 32'hffffffff;
        exeInst (32'h00100093); // li      x1,1
        exeInst (32'h00208023); // sb      x2,0(x1)
        assert (Ram.mem[0] == 32'hffff01ff);

        Ram.mem[0] = 32'hffffffff;
        exeInst (32'h00200093); // li      x1,2
        exeInst (32'h00208023); // sb      x2,0(x1)
        assert (Ram.mem[0] == 32'hff01ffff);

        Ram.mem[0] = 32'hffffffff;
        exeInst (32'h00300093); // li      x1,3
        exeInst (32'h00208023); // sb      x2,0(x1)
        assert (Ram.mem[0] == 32'h01ffffff);


        // STORE 2 BYTES
        Ram.mem[0] = 32'hffffffff;
        exeInst (32'h00000093); // li      x1,0
        exeInst (32'h00209023); // sh      x2,0(x1)
        assert (Ram.mem[0] == 32'hffff0001);

        Ram.mem[0] = 32'hffffffff;
        exeInst (32'h00200093); // li      x1,2
        exeInst (32'h00209023); // sh      x2,0(x1)
        assert (Ram.mem[0] == 32'h0001ffff);

        // STORE 4 BYTES
        Ram.mem[0] = 32'hffffffff;
        exeInst (32'h00000093); // li      x1,0
        exeInst (32'h0020a023); // sw      x2,0(x1)
        assert (Ram.mem[0] == 32'h00000001);

        $display("ok: store");
    end
    endtask

    task testJal;
    begin
        exeInst (32'h00000013); // nop
        exeInst (32'h00000013); // nop
        exeInst (32'h00000013); // nop
        exeInst (32'h00000013); // nop
        exeInst (32'h00000013); // nop
        save = Cpu.pc;
        exeInst (32'hfedff06f); // jal pc-20
        assert (Cpu.pc == (save - 20));

        $display("ok: jal");
    end
    endtask

endmodule

// ram start at address 0
module ram #(
	parameter integer WORDS = 256
) (
	input clk,
	input [3:0] wen,
	input [21:0] addr,
	input [31:0] wdata,
	output reg [31:0] rdata
);
	reg [31:0] mem [0:WORDS-1];

	always @(posedge clk) begin
		rdata <= mem[addr];
		if (wen[0]) mem[addr][ 7: 0] <= wdata[ 7: 0];
		if (wen[1]) mem[addr][15: 8] <= wdata[15: 8];
		if (wen[2]) mem[addr][23:16] <= wdata[23:16];
		if (wen[3]) mem[addr][31:24] <= wdata[31:24];
	end
endmodule