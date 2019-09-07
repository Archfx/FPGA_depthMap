/******************************************************************************/
/******************  Module for reading and processing image     **************/
/******************************************************************************/
`include "parameter.v" 						// Include definition file
module image_read
#(
  parameter WIDTH 	= 320, 					// Image width
			HEIGHT 	= 240, 						// Image height
			INFILE_L  = "Tsukuba_L.hex", 	// image file
			INFILE_R  = "Tsukuba_R.hex", 	// image file
			START_UP_DELAY = 100, 				// Delay during start up time
			HSYNC_DELAY = 160,					// Delay between HSYNC pulses	
			VALUE= 100,								// value for Brightness operation
			THRESHOLD= 90,							// Threshold value for Threshold operation
			SIGN=0									// Sign value using for brightness operation
														// SIGN = 0: Brightness subtraction
														// SIGN = 1: Brightness addition
)
(
	input HCLK,										// clock					
	input HRESETn,									// Reset (active low)
	output VSYNC,								// Vertical synchronous pulse
	// This signal is often a way to indicate that one entire image is transmitted.
	// Just create and is not used, will be used once a video or many images are transmitted.
	output reg HSYNC,								// Horizontal synchronous pulse
	// An HSYNC indicates that one line of the image is transmitted.
	// Used to be a horizontal synchronous signals for writing bmp file.
    output reg [7:0]  DATA_0_L,				// 8 bit Red data (even)
    output reg [7:0]  DATA_1_L,				// 8 bit Green data (even)
    output reg [7:0]  DATA_0_R,				// 8 bit Blue data (even)
    output reg [7:0]  DATA_1_R,				// 8 bit Red  data (odd)
	// Process and transmit 2 pixels in parallel to make the process faster, you can modify to transmit 1 pixels or more if needed
	output			  ctrl_done					// Done flag
);			
//-------------------------------------------------
// Internal Signals
//-------------------------------------------------

parameter sizeOfWidth = 8;						// data width
parameter sizeOfLengthReal = 76800; 		// image data : 1179648 bytes: 512 * 768 *3 
// local parameters for FSM
localparam		ST_IDLE 	= 2'b00,		// idle state
				ST_VSYNC	= 2'b01,			// state for creating vsync 
				ST_HSYNC	= 2'b10,			// state for creating hsync 
				ST_DATA		= 2'b11;		// state for data processing 
reg [1:0] cstate, 						// current state
		  nstate;							// next state			
reg start;									// start signal: trigger Finite state machine beginning to operate
reg HRESETn_d;								// delayed reset signal: use to create start signal
reg 		ctrl_vsync_run; 				// control signal for vsync counter  
reg [8:0]	ctrl_vsync_cnt;			// counter for vsync
reg 		ctrl_hsync_run;				// control signal for hsync counter
reg [8:0]	ctrl_hsync_cnt;			// counter  for hsync
reg 		ctrl_data_run;					// control signal for data processing
reg [31 : 0]  in_memory    [0 : sizeOfLengthReal/4]; 	// memory to store  32-bit data image
reg [7 : 0]   total_memory_L [0 : sizeOfLengthReal-1];	// memory to store  8-bit data image
reg [7 : 0]   total_memory_R [0 : sizeOfLengthReal-1];	// memory to store  8-bit data image
// temporary memory to save image data : size will be WIDTH*HEIGHT*3
integer temp_BMP_L   [0 : WIDTH*HEIGHT - 1];	
integer temp_BMP_R   [0 : WIDTH*HEIGHT - 1];		
integer org_L[0 : WIDTH*HEIGHT - 1]; 	// temporary storage for R component
integer org_R [0 : WIDTH*HEIGHT - 1];	// temporary storage for G component
//integer org_B  [0 : WIDTH*HEIGHT - 1];	// temporary storage for B component
// counting variables
integer i, j;
// temporary signals for calculation: details in the paper.
integer temp0,temp1;//,tempG0,tempG1,tempB0,tempB1; // temporary variables in contrast and brightness operation

integer value,value1,value2,value4;// temporary variables in invert and threshold operation
reg [ 8:0] row; // row index of the image
reg [8:0] col; // column index of the Left image
integer window = 7;
integer x,y; // column index of the Right image
reg [4:0] offset, best_offset, best_offset_1;
localparam [4:0] maxoffset = 10; // Maximum extent where to look for the same pixel
reg offsetfound;
reg offsetping;
reg compare,SSD_calc;
reg [20:0] ssd, ssd_1; // sum of squared difference
reg [20:0] prev_ssd, prev_ssd_1;
reg [18:0] data_count; // data counting for entire pixels of the image
//-------------------------------------------------//
// -------- Reading data from input file ----------//
//-------------------------------------------------//
initial begin
    $readmemh(INFILE_L,total_memory_L,0,sizeOfLengthReal-1); // read file from INFILE
	 $readmemh(INFILE_R,total_memory_R,0,sizeOfLengthReal-1); // read file from INFILE
end
// use 3 intermediate signals RGB to save image data
always@(start) begin
    if(start == 1'b1) begin
        for(i=0; i<WIDTH*HEIGHT ; i=i+1) begin
            temp_BMP_L[i] = total_memory_L[i+0][7:0];
				temp_BMP_R[i] = total_memory_R[i+0][7:0];
        end
        
        for(i=0; i<HEIGHT; i=i+1) begin
            for(j=0; j<WIDTH; j=j+1) begin
                org_L[WIDTH*i+j] = temp_BMP_L[WIDTH*(i)+j]; // save Left image
                org_R[WIDTH*i+j] = temp_BMP_R[WIDTH*(i)+j];// save Right image
//                org_B[WIDTH*i+j] = temp_BMP[WIDTH*3*(HEIGHT-i-1)+3*j+2];// save Blue component
            end
        end
    end
end
//----------------------------------------------------//
// ---Begin to read image file once reset was high ---//
// ---by creating a starting pulse (start)------------//
//----------------------------------------------------//
always@(posedge HCLK, negedge HRESETn)
begin
    if(!HRESETn) begin
        start <= 0;
		HRESETn_d <= 0;
		
    end
    else begin											//        		______ 				
        HRESETn_d <= HRESETn;							//       	|		|
		if(HRESETn == 1'b1 && HRESETn_d == 1'b0)		// __0___|	1	|___0____	: starting pulse
			start <= 1'b1;
		else
			start <= 1'b0;
    end
end

//-----------------------------------------------------------------------------------------------//
// Finite state machine for reading RGB888 data from memory and creating hsync and vsync pulses --//
//-----------------------------------------------------------------------------------------------//
always@(posedge HCLK, negedge HRESETn)
begin
    if(~HRESETn) begin
        cstate <= ST_IDLE;
    end
    else begin
        cstate <= nstate; // update next state 
    end
end
//-----------------------------------------//
//--------- State Transition --------------//
//-----------------------------------------//
// IDLE . VSYNC . HSYNC . DATA
always @(*) begin
	case(cstate)
		ST_IDLE: begin
			if(start)
				nstate = ST_VSYNC;
			else
				nstate = ST_IDLE;
		end			
		ST_VSYNC: begin
			if(ctrl_vsync_cnt == START_UP_DELAY) 
				nstate = ST_HSYNC;
			else
				nstate = ST_VSYNC;
		end
		ST_HSYNC: begin
			if(ctrl_hsync_cnt == HSYNC_DELAY) 
				nstate = ST_DATA;
			else
				nstate = ST_HSYNC;
		end		
		ST_DATA: begin
			if(ctrl_done)
				nstate = ST_IDLE;
			else begin
				if(col == WIDTH - 2)
					nstate = ST_HSYNC;
				else
					nstate = ST_DATA;
			end
		end
	endcase
end
// ------------------------------------------------------------------- //
// --- counting for time period of vsync, hsync, data processing ----  //
// ------------------------------------------------------------------- //
always @(*) begin
	ctrl_vsync_run = 0;
	ctrl_hsync_run = 0;
	ctrl_data_run  = 0;
	case(cstate)
		ST_VSYNC: 	begin ctrl_vsync_run = 1; end 	// trigger counting for vsync
		ST_HSYNC: 	begin ctrl_hsync_run = 1; end	// trigger counting for hsync
		ST_DATA: 	begin ctrl_data_run  = 1; end	// trigger counting for data processing
	endcase
end
// counters for vsync, hsync
always@(posedge HCLK, negedge HRESETn)
begin
    if(~HRESETn) begin
        ctrl_vsync_cnt <= 0;
		ctrl_hsync_cnt <= 0;
    end
    else begin
        if(ctrl_vsync_run)
			ctrl_vsync_cnt <= ctrl_vsync_cnt + 1; // counting for vsync
		else 
			ctrl_vsync_cnt <= 0;
			
        if(ctrl_hsync_run)
			ctrl_hsync_cnt <= ctrl_hsync_cnt + 1;	// counting for hsync		
		else
			ctrl_hsync_cnt <= 0;
    end
end
// counting column and row index  for reading memory 
always@(posedge HCLK, negedge HRESETn)
begin
    if(~HRESETn) begin
        row <= 0;
		  col<= 0;
		  offset<=4;
		  offsetping<=0;
		  compare<=0;
		  
    end
	else begin
		
		if(ctrl_data_run  ) begin //& offsetping==0 & compare==0
			if (offsetfound==1  ) begin //& offsetping==0
				if(col == WIDTH - 2) begin
					 col <= 0;  	
					 row <= row + 1;
					 //data_count<=data_count+"1";
				end
				else  begin
					 col <= col + 2;
					 //data_count <= data_count + 1;
				end
				offsetfound <= 0;
				best_offset <= 0;
				prev_ssd <= 65535;
				best_offset_1 <= 0;
				prev_ssd_1 <= 65535;
				offset <= 4;
		  end
		  else begin
				if(offset==maxoffset) begin
					 offsetfound <= 1;
				end
				else begin
					 offset<=offset+1;
					 //x<=0;
					 //y<=0;
				end
				
				offsetping<=1;	
			end
			
			if (ssd < prev_ssd & SSD_calc==1) begin //& SSD_calc==1 & offsetping==1
				prev_ssd <= ssd;
				best_offset <= offset;
				//$display("ssd %d prev_ssd %d  offset %d x %d y %d ",ssd,prev_ssd,offset,x,y);
			end
		  
			if (ssd_1 < prev_ssd_1  & SSD_calc==1) begin //& SSD_calc==1 & offsetping ==1
				prev_ssd_1 <= ssd_1;
				best_offset_1 <= offset;
			end
			if (SSD_calc==1) begin
				offsetping<=0;
			end  	
		end
	end
end

always@(posedge offsetfound) begin
	DATA_0_L=best_offset*(255/maxoffset);
	DATA_1_L =best_offset_1*(255/maxoffset);
	//DATA_0_L=(org_L[WIDTH * row + col  ]+org_R[WIDTH * row + col  ])/2 ;
	//DATA_1_L =(org_L[WIDTH * row + col+1  ]+org_R[WIDTH * row + col+1  ])/2;
end
//-------------------------------------------------//
//----------------Data counting---------- ---------//
//-------------------------------------------------//
always@(posedge HCLK, negedge HRESETn)
begin
    if(~HRESETn) begin
        data_count <= 0;
    end
    else begin
        if(ctrl_data_run) begin

				data_count <= data_count + 1;

			end
    end
end
assign VSYNC = ctrl_vsync_run;
assign ctrl_done = (data_count == 308487)? 1'b1: 1'b0; // done flag308472
//-------------------------------------------------//
//-------------  Image processing   ---------------//
//-------------------------------------------------//
always @(*) begin
	
	HSYNC   = 1'b0;
	DATA_0_L = 0;
	DATA_1_L = 0;
	DATA_0_R = 0;                                       
	DATA_1_R = 0;
                                       
	if(ctrl_data_run) begin
		if (offsetfound) HSYNC   = 1'b1;
		else HSYNC   = 1'b0;
		
	end
end


always @(posedge HCLK) begin
        SSD_calc<=0;
        if (offsetping==1) begin
			 
					 for(x=-(window-1)/2; x<((window-1)/2); x=x+1) begin
							for(y=-(window-1)/2; y<((window-1)/2); y=y+1) begin
								ssd<=(org_L[(row + x ) * WIDTH + col + y   ]-org_R[(row + x ) * WIDTH + col + y -offset])*(org_L[(row +  x ) * WIDTH + col + y   ]-org_R[(row +  x ) * WIDTH + col + y - offset]);
								ssd_1<=(org_L[(row + x ) * WIDTH + col + y  + 1 ]-org_R[(row + x ) * WIDTH + col + y -offset + 1 ])*(org_L[(row +  x ) * WIDTH + col + y  + 1 ]-org_R[(row +  x ) * WIDTH + col + y - offset + 1 ]);
							end
						end
                SSD_calc<=1;
			end
        else begin
            ssd<=0;
				ssd_1<=0;
        end
    end
//end





endmodule