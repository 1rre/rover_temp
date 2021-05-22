module edge_detect (
input [23:0]
  px_in,
input unsigned [10:0]
  x,y,
input
  clk,line_sync,
output logic [23:0]
  px_out
);

wire in_range;
assign in_range = x >= 2 && y >= 2;

wire [7:0] grey;

wire [23:0] edge_px;
assign edge_px = {grey,grey,grey};

assign px_out = in_range? edge_px : px_in;

logic unsigned [7:0] px_buffer[3][640];

reg signed [9:0] dh, dv;

wire unsigned [9:0] abs_dh, abs_dv;
wire unsigned [9:0] abs_d;

assign abs_dh = dh<0? -dh : dh;
assign abs_dv = dv<0? -dv : dv;
assign abs_d = abs_dh[8:0] + abs_dv[8:0];

assign grey = (abs_d[9:1]>9'hff)?8'hff:abs_d[8:1];

wire [7:0] red,green,blue,mean_px;

assign red = px_in[23:16];
assign green = px_in[15:8];
assign blue = px_in[7:0];
assign mean_px = (red+blue+green+8'h0f)>>2;

always @(posedge clk) begin
	px_buffer[2][x] = mean_px;
	if (x >= 2) begin
		// Horizontal differential
		dh = (
			({2'b0,px_buffer[0][x-2]} - {2'b0,px_buffer[2][x-2]}) +
			(({1'b0,px_buffer[0][x-1]} - {1'b0,px_buffer[2][x-1]}) << 1) +
			({2'b0,px_buffer[0][x]} - {2'b0,px_buffer[2][x]})
		);
		
		// Vertical differential
		dv = (
		  ({2'b0,px_buffer[0][x-2]} - {2'b0,px_buffer[0][x]}) +
		  (({2'b0,px_buffer[1][x-2]} - {2'b0,px_buffer[1][x]})<<1) +
		  ({2'b0,px_buffer[2][x-2]} - {2'b0,px_buffer[2][x]})
		);
	end
end

always @(posedge line_sync) begin
	px_buffer[0] = px_buffer[1];
	px_buffer[1] = px_buffer[2];
end


endmodule