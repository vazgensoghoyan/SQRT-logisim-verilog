`include "sqrt2.sv"

// put your code here
module sqrt2_tb; 
	reg CLK;
	integer fd;

	initial begin
		CLK = 0;
		fd = $fopen("sqrt2_log.csv", "w");
		// ...		
		#2;
        $fclose(fd);
        $finish;
	end

	always #1 CLK = ~CLK;

	always @(CLK) begin
        $fstrobe(fd, "%d\t%b", $time, CLK);
    end    

endmodule
