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
  reg Jump;
  integer regdif;
  reg[31:0] jumpAddress;
  reg [31:0] registers [0:31];
  reg [31:0] dataMemory[0:99];
  reg [8:0] memory[0:99];
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
      //Citirea din fisier a continutului memoriei
      $readmemh("instructions.mem", memory);
       pc = 32'hFFFFFFFC; // Initializare cu -4
      //Initializare cu 0 banc de registre
      /*  for (i = 0; i <= 31; i = i + 1)
          registers[i] = 0;*/
      $readmemh("reg.mem", registers);
      //Intializare cu 0 memorie de date
      $readmemh("data.mem", dataMemory);
   		result=0;
    end
    wire clk_div;
  ClockDivider clk_divider (
    .clk_in(clk),
    .clk_out(clk_div)
  );
  //La fiecare schimbare a lui PC calculez noua instructiune si parametrii acesteia
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
        else if (Jump) begin
            pc = jumpAddress; // Calculez noul PC dupa formula din Green Card
        end
    else begin
            pc= pc + 4; // Pentru celelalte instructiuni
        end
    end
  //Prelucrarea instructiunii
  always @(negedge clk_div) begin
    if(!reset)
        // Identificarea tipului de instructiune
      case (opcode)
            6'b000000: // Tip R
                begin
                    Jump = 0;
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
                            registers[rd]=~(registers[rs]|registers[rt]);
                            result=registers[rd];
                          end
                    	6'b100101://or
                          begin
                            registers[rd]=registers[rs]|registers[rt];
                          result=registers[rd];
                          end                   	
                    	6'b101010://slt
                          begin
                            regdif=registers[rs] - registers[rt];
                            registers[rd]=regdif[31];
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
                    registers[rt] = registers[rs] + {{16{immediate[15]}}, immediate};
                  result=registers[rt];
                end
        6'b001100: // andi
              begin
                  Jump = 0;
                  registers[rt] = registers[rs] & {16'b0, immediate};
                  result = registers[rt];
              end

        6'b001111: // lui
              begin
                  Jump = 0;
                  registers[rt] = {immediate, 16'b0};
                  result = registers[rt];
              end     
            6'b100011: // lw
                begin
                    Jump = 0;
                  registers[rt]=dataMemory[registers[rs]+{{16{immediate[15]}}, immediate}];
                  result=registers[rt];
                end
        	6'b001101: // ori
                begin
                    Jump = 0;
                  registers[rt] = registers[rs] | {16'b0, immediate};
                  result = registers[rt];
                end

            6'b101011: // sw
                begin                 
                    Jump = 0;
                  dataMemory[registers[rs]+{{16{immediate[15]}}, immediate}]=registers[rt];
                  result=dataMemory[registers[rs]+{{16{immediate[15]}}, immediate}];
                end
            6'b000100: // beq
                begin                             
                  if(registers[rs] == registers[rt])begin
                    Jump=1;
                    jumpAddress = pc+{ {14{immediate[15]}}, immediate, 2'b00 }+4; 
                    result=jumpAddress;
                  end
                end
            6'b000101: // bne
                begin
                  Jump = 0;                              
                  if(registers[rs] != registers[rt])begin
					Jump=1;
                    jumpAddress = pc+{ {14{immediate[15]}}, immediate, 2'b00 }+4; 
                    result=jumpAddress;
                  end
                end
            6'b000010: // j
                begin
                    Jump = 1;
                  regdif=pc+4;
                  jumpAddress = {regdif[31:28], address, 2'b00};
				  result=jumpAddress;
                end
            6'b000011: // jal
                begin
                  Jump = 1;
                  registers[31]=pc+8;
                  regdif=pc+4;
                  jumpAddress = {regdif[31:28], address, 2'b00};
				  result=jumpAddress;
                end
        	6'b111111: //instructiune de reset intern
              begin
               $readmemh("reg.mem", registers);
               $readmemh("data.mem", dataMemory);
        		Jump=1;
        		jumpAddress=0;
              end
            default: // Instructiuni nesuportate
                begin
                    Jump = 0;
                  	result=0;
                end
        endcase
    else
       //daca reset este activ, resetez bancul de registre, flag-urile Jump si Branch si memoria de date
      begin
        result=0;
         Jump = 0;
        $readmemh("reg.mem", registers);
        $readmemh("data.mem", dataMemory);
    end
  end

endmodule