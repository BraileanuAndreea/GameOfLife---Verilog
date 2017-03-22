`timescale 1ns / 1ps

 module world(
    input           clk,            // synchronization signal
    input [5:0]     row,            // row index of cell to be read/written
    input [5:0]     col,            // col index of cell to be read/written
    input           we,             // write enable: 0 - cell is read, 1 - cell is written
    input           in,             // when writing: new cell value
    output          out);           // when reading: current cell value

parameter init = 1;                 // init data: 0 - don't init, 1 - init

reg data[63:0][63:0];                     // storage for world data

integer data_file;                  // initialization file handle
integer seed;                       // seed for random data generation; 0 - don't generate, read from file instead
integer i, j;
initial begin
    if(init) begin
        // open file
        data_file = $fopen("test.data", "r");
        if(!data_file) begin
            $write("error opening data file\n");
            $finish;
        end

        // read seed
        if($fscanf(data_file, "seed=%d\n", seed) != 1) begin
            $write("error reading seed value\n");
            $finish;
        end

        // init data
        for(i = 0; i < 64; i = i + 1) begin
            for(j = 0; j < 64; j = j + 1) begin
                if(seed != 0) begin
                    // generate random data
                    data[i][j] = $random(seed);
                end
                else begin
                    // read data from file
                    if($fscanf(data_file, "%d\n", data[i][j]) != 1) begin
                        $write("error reading test data\n");
                        $finish;
                    end
                end
            end
        end

        // close file
        $fclose(data_file);
    end
end

// output is combinational; no delay
assign out = data[row][col];

// writing is synchronous; new value is available in next cycle
always @(posedge clk) begin
    if(we)
        data[row][col] <= in;
end

endmodule

