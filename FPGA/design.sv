module ClockDivider (
  input wire clk_in,
  output reg clk_out
);
  reg [31:0] count;

  initial begin
    clk_out = 0; // Initializare cu valoarea 0
    count = 0; // Initializare cu valoarea 0
  end

  always @(posedge clk_in) begin
    if (count == 50000000-1) begin 
      clk_out <= ~clk_out;
      count <= 0;
    end else begin
      count <= count + 1;
    end
  end
endmodule
module MIPSProcessor (
    input clk,
    input reset,
  output reg [16:0] result
);
  reg[31:0] pc;
  	reg Jump,Branch;
  reg[31:0] jumpAddress,branchAddress;
    reg [31:0] registers [0:31];
  reg [31:0] dataMemory[0:99];
  reg [8:0] memory[0:95];
  reg [31:0] instruction;
  reg [5:0] opcode;
  reg [4:0] rs;
  reg [4:0] rt;
  reg [4:0] rd;
  reg [4:0] shamt;
  reg [5:0] funct;
  reg [15:0] immediate;
  reg [25:0] address;
  integer i;
    initial begin
      $readmemh("instructions.mem", memory);
       pc = 32'hFFFFFFFC; // Initializare cu -4
        for (i = 0; i <= 31; i = i + 1)
          registers[i] = 0;
      for (i = 0; i <= 99; i = i + 1)
            dataMemory[i] = 32'h0000_0000;
   		result=0;
    end
        	wire clk_div;
  ClockDivider clk_divider (
    .clk_in(clk),
    .clk_out(clk_div)
  );
  always @(pc) begin
        instruction = {memory[pc][7:0], memory[pc+1][7:0], memory[pc+2][7:0], memory[pc+3][7:0]};
        opcode = instruction[31:26];
        rs = instruction[25:21];
        rt = instruction[20:16];
        rd = instruction[15:11];
        shamt = instruction[10:6];
        funct = instruction[5:0];
        immediate = instruction[15:0];
        address = instruction[25:0];
    end
  always @(posedge clk_div) begin
        if (reset) begin
            pc = 32'hFFFFFFFC; // Initializare cu -4
        end
    else if (Branch) begin
            pc = pc+4+branchAddress; // Sãrim la adresa specificatã de branchAddress dacã zero
        end
        else if (Jump) begin
            pc = jumpAddress; // Sãrim la adresa specificatã de jumpAddress
        end
    else begin
            pc= pc + 4; // Incrementarea PC-ului cu 4
        end
    end
  always @(negedge clk_div) begin
    if(!reset)
        // Identificarea tipului de instruc?iune
      case (opcode)
            6'b000000: // Tip R
                begin
                    Jump = 0;
                    Branch = 0;
                  case (funct)
                        6'b100000: // add
                          begin
                          registers[rd]=registers[rs]+registers[rt];
                          result=registers[rd];
                          end                      
                    	6'b100100: //and
                          begin
                          registers[rd]=registers[rs]&registers[rt];
                          result=registers[rd];
                          end
                    	6'b001000://jr
                          begin
                            Jump=1;
                            jumpAddress=registers[rt];
                          end
                    	6'b100111://nor
                          begin
                            registers[rd]=!(registers[rs]|registers[rt]);
                          result=registers[rd];
                          end
                    	6'b100101://or
                          begin
                            registers[rd]=registers[rs]|registers[rt];
                          result=registers[rd];
                          end                   	
                    	6'b101010://slt
                          begin
                            registers[rd]=(registers[rs] < registers[rt]) ? 1 : 0;
                          result=registers[rd];
                          end
                    	6'b000000://sll
                          begin
                            registers[rd]=registers[rt]<<shamt;
                          result=registers[rd];
                          end
                    	6'b000010://srl
                          begin
                            registers[rd]=registers[rt]>>shamt;
                          result=registers[rd];
                          end                  	
                    6'b100010: // sub
                          begin
                          registers[rd]=registers[rs]-registers[rt];
                          result=registers[rd];
                          end
                        default: // Altele
                            result = 0; // Nedefinit
                    endcase
                end
        6'b001000: // addi
                begin
                    Jump = 0;
                    Branch = 0;
                    registers[rt] = registers[rs] + {{16{immediate[15]}}, immediate};
                  result=registers[rt];
                end
        6'b001100: // andi
              begin
                  Jump = 0;
                  Branch = 0;
                  registers[rt] = registers[rs] & {16'b0, immediate};
                  result = registers[rt];
              end

        6'b001111: // lui
              begin
                  Jump = 0;
                  Branch = 0;
                  registers[rt] = {immediate, 16'b0};
                  result = registers[rt];
              end     
            6'b100011: // lw
                begin
                    Jump = 0;
                    Branch = 0;
                  registers[rt]=dataMemory[registers[rs]+{{16{immediate[15]}}, immediate}];
                  result=registers[rt];
                end
        	6'b001101: // ori
                begin
                    Jump = 0;
                    Branch = 0;
                    registers[rt] = registers[rs] | {16'b0, immediate};
                    result = registers[rt];
                end

            6'b101011: // sw
                begin                 
                    Jump = 0;
                    Branch = 0;
                  dataMemory[registers[rs]+immediate]=registers[rt];
                  result=dataMemory[registers[rs]+immediate];
                end
            6'b000100: // beq
                begin
                  Jump = 0;                              
                  if(registers[rs] == registers[rt])begin
                    branchAddress = { {14{immediate[15]}}, immediate, 2'b00 };
                  	Branch=1;
                    result=branchAddress;
                  end
                  else begin
                    Branch=0;
                    result=registers[rs];
                  end
                end
            6'b000101: // bne
                begin
                  Jump = 0;                              
                  if(registers[rs] != registers[rt])begin
                    branchAddress = { {14{immediate[15]}}, immediate, 2'b00 };
                  	Branch=1;
                    result=branchAddress;
                  end
                  else begin
                    Branch=0;
                    result=0;
                  end
                end
            6'b000010: // j
                begin
                    Jump = 1;
                    Branch = 0;
                  jumpAddress = {pc[31:28], address, 2'b00};
				  result=jumpAddress;
                end
            6'b000011: // jal
                begin
                    Jump = 1;
                    Branch = 0;
                    registers[31]=pc;
                  jumpAddress = {pc[31:28], address, 2'b00};
				  result=jumpAddress;
                end
        	6'b111111: //instructiune de reset intern
              begin
                for (i = 0; i <= 31; i = i + 1)
                  registers[i] = 0;
               for (i = 0; i <= 99; i = i + 1)
                    dataMemory[i] = 32'h0000_0000;
        		Branch=0;
        		Jump=1;
        		jumpAddress=0;
              end
            default: // Instructiuni nesuportate
                begin
                    Jump = 0;
                    Branch = 0;
                end
        endcase
    else
      begin
        result<=0;
         Jump = 0;
        Branch=0;
        for (i = 0; i <= 31; i = i + 1)
          registers[i] = 0;
        for (i = 0; i <= 99; i = i + 1)
            dataMemory[i] = 32'h0000_0000;
    end
  end

endmodule