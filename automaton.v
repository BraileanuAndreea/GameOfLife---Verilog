`timescale 1ns / 1ps

module automaton(
    input               clk,            // synchronization signal
    input [31:0]        rule,           // next generation rule; only used for bonus points
    output reg [5:0]    row,            // row index cell to be read/written
    output reg [5:0]    col,            // column index cell to be read/written
    output reg          world_we,       // write enable: 0 - cell is read, 1 - cell is written
    input               world_in,       // when reading: current cell value in world
    output reg          world_out,      // when writing: new cell value in world
    output reg          update_done);   // next generation was calculated; must be active for 1 clock cycle

`define start												0
`define setPreviousRowToCurrentRow					1 						
`define readRow											2
`define incrementColumnToReadEntireRow				3
`define readCell											4
`define readNorth 										5
`define readSouth											6
`define readWest											7
`define readEast											8
`define writeCell											9
`define increment											10

reg previous_row[63:0], current_row[63:0];
reg [6:0] index;
reg [5:0] index_row, index_column, next_index_row, next_index_column, indexRule;
reg [4:0] state, next_state;
reg N, S, E, W, C, next_update_done;

initial begin
	state = 0;
	next_index_row = 0;
	next_index_column = 0;
	for(index = 0; index < 64; index = index + 1) begin
		previous_row[index] = 0;
		current_row[index] = 0;
	end
end

//pe frontul pozitiv se seteaza noile valori pentru state index_row, index_column, update_done calculate in blocul always@(*)
always@(posedge clk) begin
 	state <= next_state;								//setare stare
	index_row <= next_index_row;					//setare index rand
	index_column <= next_index_column;			//setare index coloana
	update_done <= next_update_done;				//setare update_done
end	
	
always@(*)begin
	world_we = 0;										//citim din matrice, atunci cand setam row si col, vom primi in world_in valoarea celulei
    case (state)
		`start:   
				begin
					next_update_done = 0;			//initial starile urmatoare pentru stare, index rand si coloana sunt 0
					next_index_row = 0;
					next_index_column = 0;					
					next_state = `setPreviousRowToCurrentRow;			//se trece la urmatoarea stare
				end
		`setPreviousRowToCurrentRow:	
				begin	
					for(index = 0; index < 64; index = index + 1) begin
						previous_row[index] = current_row[index];		//retinem randul precedent citit din matrice si nemodificat pentru a seta vecinii din nord
					  end
					next_state = `readRow;			//se trece la urmatoarea stare
				end
		`readRow:   
				begin
					row = index_row;					//setam row si col pentru a retine in vectorul curent valoarea elementului de pe 
					col = index_column;				//pozitia index_column data de iesirea world_in a modulului world
					current_row[col] = world_in;
					next_state = `incrementColumnToReadEntireRow;	//se trece la urmatoarea stare
				end
		`incrementColumnToReadEntireRow:	
					begin
					if(index_column == 63)begin
						next_index_column = 0;		//daca s-a citit tot randul curent se trece la prima coloana
						next_state = `readCell;		//se trece la urmatoarea stare(readCell) pentru a seta vecinii
					end
					else begin
						next_index_column = index_column + 1;			//daca nu s-a citit tot randul, incrementam index_column pentru a citi si celelalte celule de pe rand
						next_state = `readRow; 		//se trece la urmatoarea stare(readRow) pentru a termina de citit randul
					end
				end
		`readCell:
				begin
					row = index_row;					//setam row si col pentru a ne reaminti asupra carei celule operam
					col = index_column;				
					C = current_row[index_column];						//retinem valoare celulei in variabila C, retinuta anterior in vectorul current_row
					next_state = `readNorth;		//se trece la urmatoarea stare unde citim vecinul din nord
				end
		`readNorth:
				begin
					if(index_row == 0)begin
						N = 0;							//daca ne aflam pe prima linie, vecinul din nord e 0
					end
					else begin
						N = previous_row[index_column];					//vecinul din nord este retinut in vectorul previous_row la index-ul index_column
					end
					next_state = `readSouth;		//in continuare citim vecinul din sud
				end
		`readSouth:
				begin
					if(index_row == 63)begin
						S = 0;							//daca ne aflam pe ultimul rand, vecinul din sud este 0
					end
					else begin
						row = index_row + 1;			//incrementam randul si setam row
						col = index_column;			//setam col
						S = world_in;					//retinem in S valoarea data de modulul world prin iesirea world_in, adica valoarea celulei
					end
					next_state = `readWest;			//se trece la starea urmatoare, unde citim vecinul din vest
				end
		`readWest:
				begin
					if(index_column == 0)begin
						W = 0;							//daca ne aflam pe prima coloana, vecinul din vest este 0
					end
					else begin
						W = current_row[index_column - 1];				//altfel, vecinul din vest este retinut in vectorul curent la pozitia index_column - 1
					end
					next_state = `readEast;			//se trece la starea urmatoare, unde citim vecinul din est
				end
		`readEast:
				begin
					if(index_column == 63)begin
						E = 0;							//daca ne aflam pe ultima coloana, vecinul din est este 0
					end
					else begin
						E = current_row[index_column + 1];				//altfel, vecinul din est este retinul in vectorul curent la pozitia index_column + 1
					end
					next_state = `writeCell;		//se trece la starea urmatoare unde scriem noua valoare a celulei
				end
		`writeCell:
				begin
					world_we = 1;						//setam world_we pe 1 pentru a putea scrie in matrice
					row = index_row;					//setam randul la care vrem sa scriem
					col = index_column;				//setam coloana la care vrem sa scriem
					//setam numarul bitului din vectorul rule care corespunde cu noua valoare a celulei in functie de configuratia N W C E S
					if((N == 1) && (W == 1) && (C == 1) && (E == 1) && (S == 1))begin
						indexRule = 31;
					end
					else if((N == 1) && (W == 1) && (C == 1) && (E == 1) && (S == 0))begin
						indexRule = 30;
					end
					else if((N == 1) && (W == 1) && (C == 1) && (E == 0) && (S == 1))begin
						indexRule = 29;
					end
					else if((N == 1) && (W == 1) && (C == 1) && (E == 0) && (S == 0))begin
						indexRule = 28;
					end
					else if((N == 1) && (W == 1) && (C == 0) && (E == 1) && (S == 1))begin
						indexRule = 27;
					end
					else if((N == 1) && (W == 1) && (C == 0) && (E == 1) && (S == 0))begin
						indexRule = 26;
					end
					else if((N == 1) && (W == 1) && (C == 0) && (E == 0) && (S == 1))begin
						indexRule = 25;
					end
					else if((N == 1) && (W == 1) && (C == 0) && (E == 0) && (S == 0))begin
						indexRule = 24;
					end
					else if((N == 1) && (W == 0) && (C == 1) && (E == 1) && (S == 1))begin
						indexRule = 23;
					end
					else if((N == 1) && (W == 0) && (C == 1) && (E == 1) && (S == 0))begin
						indexRule = 22;
					end
					else if((N == 1) && (W == 0) && (C == 1) && (E == 0) && (S == 1))begin
						indexRule = 21;
					end
					else if((N == 1) && (W == 0) && (C == 1) && (E == 0) && (S == 0))begin
						indexRule = 20;
					end
					else if((N == 1) && (W == 0) && (C == 0) && (E == 1) && (S == 1))begin
						indexRule = 19;
					end
					else if((N == 1) && (W == 0) && (C == 0) && (E == 1) && (S == 0))begin
						indexRule = 18;
					end
					else if((N == 1) && (W == 0) && (C == 0) && (E == 0) && (S == 1))begin
						indexRule = 17;
					end
					else if((N == 1) && (W == 0) && (C == 0) && (E == 0) && (S == 0))begin
						indexRule = 16;
					end
					else if((N == 0) && (W == 1) && (C == 1) && (E == 1) && (S == 1))begin
						indexRule = 15;
					end
					else if((N == 0) && (W == 1) && (C == 1) && (E == 1) && (S == 0))begin
						indexRule = 14;
					end
					else if((N == 0) && (W == 1) && (C == 1) && (E == 0) && (S == 1))begin
						indexRule = 13;
					end
					else if((N == 0) && (W == 1) && (C == 1) && (E == 0) && (S == 0))begin
						indexRule = 12;
					end
					else if((N == 0) && (W == 1) && (C == 0) && (E == 1) && (S == 1))begin
						indexRule = 11;
					end
					else if((N == 0) && (W == 1) && (C == 0) && (E == 1) && (S == 0))begin
						indexRule = 10;
					end
					else if((N == 0) && (W == 1) && (C == 0) && (E == 0) && (S == 1))begin
						indexRule = 9;
					end
					else if((N == 0) && (W == 1) && (C == 0) && (E == 0) && (S == 0))begin
						indexRule = 8;
					end
					else if((N == 0) && (W == 0) && (C == 1) && (E == 1) && (S == 1))begin
						indexRule = 7;
					end
					else if((N == 0) && (W == 0) && (C == 1) && (E == 1) && (S == 0))begin
						indexRule = 6;
					end
					else if((N == 0) && (W == 0) && (C == 1) && (E == 0) && (S == 1))begin
						indexRule = 5;
					end
					else if((N == 0) && (W == 0) && (C == 1) && (E == 0) && (S == 0))begin
						indexRule = 4;
					end
					else if((N == 0) && (W == 0) && (C == 0) && (E == 1) && (S == 1))begin
						indexRule = 3;
					end
					else if((N == 0) && (W == 0) && (C == 0) && (E == 1) && (S == 0))begin
						indexRule = 2;
					end
					else if((N == 0) && (W == 0) && (C == 0) && (E == 0) && (S == 1))begin
						indexRule = 1;
					end
					else if((N == 0) && (W == 0) && (C == 0) && (E == 0) && (S == 0))begin
						indexRule = 0;
					end
					world_out = rule[indexRule];		//setam noua valoare a celulei cu bitul corespunzator din vectorul rule
					next_state = `increment;			//se trece la noua stare, unde incrementam randul si/sau coloana pentru urmatoarea iteratie
				end		
		`increment:	
				begin
					if(index_row == 63 && index_column == 63) begin
						next_update_done = 1;			//am citit generatia, noua valoare pentru update_done e setata in next_update_done
						next_state = `start;				//se trece la start pentru a citi urmatoarea generatie
					end
					else if(index_column == 63) begin
							next_index_column = 0;		//daca am citit tot randul, index_column trebuie sa devina 0, deci ii setam next_index_column
							next_index_row = index_row + 1;				//se trece la randul urmator
							next_state = `setPreviousRowToCurrentRow;	//in urmatoarea stare retinem vectorul deja citit in  previous_row
						end
						else begin
							next_index_column = index_column + 1;		//incrementam coloana
							next_state = `readCell;		//se trece la urmatoarea stare in care citim vecinii celorlalte celule de pe acelasi rand
						end
				end
		endcase
end
endmodule
