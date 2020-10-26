`timescale 1 ns / 1 ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Xilinx, Inc.
// Engineer: Davy Huang
// 
// Create Date: 04/24/2018 01:24:00 PM
// Design Name: VCU low latency synchronization IP
// Module Name: ring_addr_buffer_ctrl
// Project Name: VCU low latency 
// Target Devices: Zynq UltraScale+ EV
// Tool Versions: Vivado 2018.1
// Description: 
// 
// Dependencies:
//  
// SW programming behavior:
//  Ring address buffer FSM
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module ring_addr_buffer_ctrl
  (
   input wire clk,
   input wire aresetn,
   (* mark_debug = "true" *)   input wire [2:0]  addr_valid,
   (* mark_debug = "true" *)   input wire frmbuf_addr_next,
   (* mark_debug = "true" *)   output wire [1:0] frmbuf_done,
   (* mark_debug = "true" *)   output wire frmbuf_skipped,
   (* mark_debug = "true" *)   output wire frmbuf_irq,
   (* mark_debug = "true" *)   output reg [31:0] buf_cnt,
   (* mark_debug = "true" *)   output reg [1:0] buf_id,
   (* mark_debug = "true" *)   output wire buf_id_valid,   //pulsed buf_id valid
   (* mark_debug = "true" *)   output wire [2:0] debug
   );

   localparam [2:0] S_IDLE = 3'b000;
   localparam [2:0] S_CHECK_VALID = 3'b001;
   localparam [2:0] S_PROC_BUF = 3'b010;
   localparam [2:0] S_SKIP_BUF = 3'b011;
   localparam [2:0] S_SKIP_BUF2= 3'b100;
   wire [2:0]  const1_3b = 6'd1;
   
   //FSM to circle through 3 address buffer
   reg [2:0] cur_st, next_st;
   reg [1:0] frmdone_buf_id;

   // Current buffer address's valid bit value
   wire      c_frmbuf_addr_valid = (addr_valid & (const1_3b << buf_id)) != 0;

   assign debug = cur_st;
   
   assign buf_id_valid = c_frmbuf_addr_valid & (cur_st == S_CHECK_VALID);

   //always @(posedge clk or negedge aresetn)
   always @(posedge clk)
     begin
	if (aresetn == 1'b0)
	  cur_st <= S_IDLE;
	else
	  cur_st <= next_st;
     end

   always @(*) begin
      case (cur_st)
	S_IDLE:
	  if (addr_valid[0])
	    next_st = S_CHECK_VALID;
	  else
	    next_st = S_IDLE;
	S_CHECK_VALID:
	  if (c_frmbuf_addr_valid)
	    next_st = S_PROC_BUF;
	  else
	    next_st = S_SKIP_BUF;
	S_PROC_BUF:
	  if (c_frmbuf_addr_valid)
          begin
	    if (frmbuf_addr_next)
	      next_st = S_CHECK_VALID;
	    else
	      next_st = S_PROC_BUF;
          end
	  else
	    next_st = S_CHECK_VALID;
	S_SKIP_BUF:
	  next_st = S_SKIP_BUF2;
	S_SKIP_BUF2:
	  next_st = S_CHECK_VALID;
	
	default:  next_st = S_IDLE;
      endcase
   end

   //always @(posedge clk or negedge aresetn)
   always @(posedge clk)
     begin
	if (aresetn == 1'b0)
	  buf_id <= 2'd0;
	else if (cur_st == S_PROC_BUF && frmbuf_addr_next == 1 || cur_st == S_SKIP_BUF)
	  begin
	     if (buf_id == 2'd2)
	       buf_id <= 2'd0;
	     else
	       buf_id <= buf_id + 2'd1;
	  end

	if (aresetn == 1'b0)
	begin
	  frmdone_buf_id <= 2'd0;
          buf_cnt        <= {32{1'b0}};
	end
	else if (cur_st == S_PROC_BUF && frmbuf_addr_next == 1 )
	begin
          buf_cnt <= buf_cnt + 1'b1;
          if (frmdone_buf_id == 2'd2)
	  begin
	    frmdone_buf_id <= 2'd0;
	  end
	  else
	  begin
	    frmdone_buf_id <= frmdone_buf_id + 1'b1;
	  end
	end
     end

   assign frmbuf_done[1:0] = frmdone_buf_id[1:0]; //buf_id[1:0];
   assign frmbuf_skipped   = 1'b0; //(cur_st == S_SKIP_BUF);
   assign frmbuf_irq       = frmbuf_addr_next; //(cur_st == S_SKIP_BUF) | frmbuf_addr_next;
   
   
endmodule


`timescale 1 ns / 1 ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Xilinx, Inc.
// Engineer: Davy Huang
// 
// Create Date: 04/24/2018 01:24:00 PM
// Design Name: VCU low latency synchronization IP
// Module Name: addr_thres_ctrl
// Project Name: VCU low latency 
// Target Devices: Zynq UltraScale+ EV
// Tool Versions: Vivado 2018.1
// Description: 
//   Producer address threshold monitor and control
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module addr_thres_ctrl #
  (
   parameter C_VIDEO_CHAN = 4,
   parameter C_VIDEO_CHAN_ID = 0,
   parameter C_S_AXI_ADDR_WIDTH = 64,
   parameter C_FRMBUF_ADDR_WIDTH = 44,
   parameter C_DEC_ENC_N = 0,
   parameter [23:0] C_TIMEOUT = 24'h4C4B40
    )
   (
    input wire  aclk,
    input wire  aresetn,
    input wire 	en,

    (* mark_debug = "true" *) input wire [2*C_VIDEO_CHAN-1:0] buf_id,
		
   (* mark_debug = "true" *) input wire axi_axaddr_valid,
   (* mark_debug = "true" *) input wire axi_axaddr_inrange,
  (* mark_debug = "true" *)  input wire [C_S_AXI_ADDR_WIDTH-1:0] axi_axaddr,
    input wire chan_active,
   (* mark_debug = "true" *) input wire [2:0] chan_id, 

    input wire axi_axaddr_next_valid,
    input wire [C_S_AXI_ADDR_WIDTH-1:0] axi_axaddr_next,

    input wire axi_bresp_valid,
    input wire axi_bresp_ok,

    input wire [C_VIDEO_CHAN-1:0] int_frmbuf_addr_valid_pulse,
    input wire [C_VIDEO_CHAN-1:0] int_frmbuf_addr_valid,
    input wire [C_VIDEO_CHAN*32-1:0] int_frmbuf_addr_margin,
    input wire [C_VIDEO_CHAN*C_FRMBUF_ADDR_WIDTH-1:0] int_frmbuf_addr_start,
    input wire [C_VIDEO_CHAN*C_FRMBUF_ADDR_WIDTH-1:0] int_frmbuf_addr_end,
    input wire [C_VIDEO_CHAN*C_FRMBUF_ADDR_WIDTH-1:0] c0_frmbuf_addr_end,
    input wire [C_VIDEO_CHAN*C_FRMBUF_ADDR_WIDTH-1:0] c1_frmbuf_addr_end,
    input wire [C_VIDEO_CHAN*C_FRMBUF_ADDR_WIDTH-1:0] c2_frmbuf_addr_end,
    input wire [C_VIDEO_CHAN*C_FRMBUF_ADDR_WIDTH-1:0] c3_frmbuf_addr_end,

   (* mark_debug = "true" *) output reg [C_VIDEO_CHAN-1:0] frmbuf_addr_next,
   (* mark_debug = "true" *) output reg [C_VIDEO_CHAN-1:0] frmbuf_addr_done,
   (* mark_debug = "true" *) output reg [C_VIDEO_CHAN-1:0] frmbuf_c0_addr_done,
   (* mark_debug = "true" *) output reg [C_VIDEO_CHAN-1:0] frmbuf_c1_addr_done,
   (* mark_debug = "true" *) output reg [C_VIDEO_CHAN-1:0] frmbuf_c2_addr_done,
   (* mark_debug = "true" *) output reg [C_VIDEO_CHAN-1:0] frmbuf_c3_addr_done,
   (* mark_debug = "true" *) output wire [C_VIDEO_CHAN*C_FRMBUF_ADDR_WIDTH-1:0] frmbuf_addr_outthres,
   (* mark_debug = "true" *) output reg [C_VIDEO_CHAN-1:0] frmbuf_addr_outthres_valid_pulse,

    output wire [C_VIDEO_CHAN-1:0] err_timeout
    
    );

   reg [2:0] 	chan_id_p;
   reg          chan_active_p;
   
   reg 		axi_axaddr_inrange_p;
   
   reg [C_FRMBUF_ADDR_WIDTH-1:0] in_thres [C_VIDEO_CHAN-1:0];
   reg [C_FRMBUF_ADDR_WIDTH-1:0] new_thres [C_VIDEO_CHAN-1:0];
   reg [C_FRMBUF_ADDR_WIDTH-1:0] out_thres [C_VIDEO_CHAN-1:0];
   
   reg [1+2+C_S_AXI_ADDR_WIDTH-1:0] req_resp [0:15];
  (* mark_debug = "true" *) reg [4:0] 			  wr_ptr, rd_ptr;
  (* mark_debug = "true" *) wire 			  empty;
  (* mark_debug = "true" *) wire 			  full;
   reg [C_VIDEO_CHAN-1:0] 	  timeout;
   reg [23:0] 			  timeout_counter;
   
   //wire [1:0] 			  req_resp_chan_id = (C_DEC_ENC_N == 0 ? C_VIDEO_CHAN_ID : req_resp[rd_ptr[3:0]][2:1]);
   wire [1:0] 			  req_resp_chan_id = req_resp[rd_ptr[3:0]][2:1];
  (* mark_debug = "true" *) wire  req_resp_inrange = req_resp[rd_ptr[3:0]][0];
  (* mark_debug = "true" *) wire  [C_FRMBUF_ADDR_WIDTH-1:0] req_resp_axaddr  = req_resp[rd_ptr[3:0]][3 +: C_FRMBUF_ADDR_WIDTH];
  (* mark_debug = "true" *) reg   [1:0]                    req_resp_chan_id_p;
    
   integer 			  i;
   
   assign err_timeout = timeout;

   //synthesis translate_off
   wire [1+2+C_S_AXI_ADDR_WIDTH-1:0] debug_wdata = req_resp[wr_ptr[3:0]];
   wire [1+2+C_S_AXI_ADDR_WIDTH-1:0] debug_rdata = req_resp[rd_ptr[3:0]];
   wire [C_FRMBUF_ADDR_WIDTH-1:0]    debug_inthres_0  = in_thres[0];
   wire [C_FRMBUF_ADDR_WIDTH-1:0]    debug_inthres_1  = in_thres[1];
   wire [C_FRMBUF_ADDR_WIDTH-1:0]    debug_inthres_2  = in_thres[2];
   wire [C_FRMBUF_ADDR_WIDTH-1:0]    debug_inthres_3  = in_thres[3];
   wire [C_FRMBUF_ADDR_WIDTH-1:0]    debug_newthres_0 = new_thres[0];
   wire [C_FRMBUF_ADDR_WIDTH-1:0]    debug_newthres_1 = new_thres[1];
   wire [C_FRMBUF_ADDR_WIDTH-1:0]    debug_newthres_2 = new_thres[2];
   wire [C_FRMBUF_ADDR_WIDTH-1:0]    debug_newthres_3 = new_thres[3];
   wire [C_FRMBUF_ADDR_WIDTH-1:0]    debug_outthres_0 = out_thres[0];
   wire [C_FRMBUF_ADDR_WIDTH-1:0]    debug_outthres_1 = out_thres[1];
   wire [C_FRMBUF_ADDR_WIDTH-1:0]    debug_outthres_2 = out_thres[2];
   wire [C_FRMBUF_ADDR_WIDTH-1:0]    debug_outthres_3 = out_thres[3];
   //synthesis translate_on
   
   // pipelines
   always @(posedge aclk) begin
      axi_axaddr_inrange_p <= axi_axaddr_inrange;
      chan_id_p <= chan_id;
      chan_active_p <= chan_active;
      
     end
   
   // request/response FIFO, 
   // shared by multiple decoder channels in Decode-display case
   // assumption is when switching channel, prior data should be
   // flushed already (already received BRESP for previous channel)

   // write port
   //always @(posedge aclk or negedge aresetn)
   always @(posedge aclk)
     begin
	if (~aresetn) begin
	   wr_ptr <= 'd0;
	end
	else if (axi_axaddr_next_valid & chan_active_p) begin
	   wr_ptr <= wr_ptr + 1;
	end
     end
   
   always @(posedge aclk)
     begin
	if (axi_axaddr_next_valid & chan_active_p) begin
	   req_resp[wr_ptr[3:0]][0] <= axi_axaddr_inrange_p;
	   req_resp[wr_ptr[3:0]][1 +: 2] <= chan_id_p[1:0];
	   req_resp[wr_ptr[3:0]][3 +: C_S_AXI_ADDR_WIDTH] <= axi_axaddr_next;
	end
     end 
   
   // read port
   //always @(posedge aclk or negedge aresetn)
   always @(posedge aclk)
     begin
	if (~aresetn) begin
	   rd_ptr <= 'd0;
	   req_resp_chan_id_p <= 0;
	end
	else if (axi_bresp_valid & chan_active_p) begin
	   rd_ptr <= rd_ptr + 1;
	   req_resp_chan_id_p <= req_resp_chan_id;
	end
     end
   
   assign empty = (wr_ptr == rd_ptr);
   assign full = (wr_ptr[3:0] == rd_ptr[3:0]) && (wr_ptr[4] != rd_ptr[4]);
   
   
   
   // threshold - need to track per channel
   genvar c;
   generate
      for (c=0;c<C_VIDEO_CHAN;c=c+1) begin: gen_chan
	 
	 //always @(posedge aclk or negedge aresetn)
	 always @(posedge aclk)
	   begin
	      if (~aresetn) begin
		 in_thres[c] = 0;
		 new_thres[c] = 0;
		 out_thres[c] = 0;
	      end
	      // ring buffer moves to next entry, update in_thres
	      else if (int_frmbuf_addr_valid_pulse[c]) begin
		 in_thres[c] = int_frmbuf_addr_start[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH];
		 out_thres[c] = int_frmbuf_addr_start[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH];
	      end
	      
	      // new AXI request received
	      else if (~empty & axi_bresp_valid & axi_bresp_ok
		       & (req_resp_chan_id == c)) begin
		 //if (req_resp[rd_ptr[3:0]][0] == 1
		 //    && req_resp[rd_ptr[3:0]][3 +: C_FRMBUF_ADDR_WIDTH] >= in_thres[c]) begin
		 if ((req_resp_inrange == 1)&& (req_resp_axaddr >= in_thres[c])) begin
		    in_thres[c] = req_resp[rd_ptr[3:0]][3 +: C_FRMBUF_ADDR_WIDTH];
		    new_thres[c] = in_thres[c] - int_frmbuf_addr_margin[c*32 +: 32];
		    if (new_thres[c] < int_frmbuf_addr_start[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH])
		      out_thres[c] = int_frmbuf_addr_start[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH];
		    else
		      out_thres[c] = new_thres[c];
		 end
	      end
	   end // always @ (posedge aclk or negedge aresetn)


	 // create valid pulses for the outthres
	 //always @(posedge aclk or negedge aresetn) begin
	 always @(posedge aclk) begin
	    if (~aresetn)
	      frmbuf_addr_outthres_valid_pulse[c] <= 1'b0;
	   
	    else
	      frmbuf_addr_outthres_valid_pulse[c] <= int_frmbuf_addr_valid_pulse[c] 
						  | 
						  ~empty & axi_bresp_valid & axi_bresp_ok &
						     (req_resp_chan_id == c) &
						     req_resp_inrange & 
						     (req_resp_axaddr >= in_thres[c]);
						     //req_resp[rd_ptr[3:0]][0] & 
						     //(req_resp[rd_ptr[3:0]][3 +: C_FRMBUF_ADDR_WIDTH] >= in_thres[c]);
	    
	 end
	 
	 assign frmbuf_addr_outthres[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH] = out_thres[c];
	 
      end // block: gen_chan
   endgenerate
   
	 

 
   // FSM
   //-------------------------------
   (* mark_debug = "true" *) reg [3:0] cur_st, next_st;
   localparam [3:0] S_IDLE     = 4'b0001;
   localparam [3:0] S_WAIT_REQ = 4'b0010;
   localparam [3:0] S_C0_WAIT_END = 4'b0011;
   localparam [3:0] S_C1_WAIT_END = 4'b0100;
   localparam [3:0] S_C2_WAIT_END = 4'b0101;
   localparam [3:0] S_C3_WAIT_END = 4'b0110;
   localparam [3:0] S_WAIT_END = 4'b0111;
   localparam [3:0] S_C0_END   = 4'b1000;
   localparam [3:0] S_C1_END   = 4'b1001;
   localparam [3:0] S_C2_END   = 4'b1010;
   localparam [3:0] S_C3_END   = 4'b1011;
   localparam [3:0] S_END      = 4'b1100;
   
   //always @(posedge aclk or negedge aresetn)
   always @(posedge aclk)
     begin
	if (aresetn == 1'b0)
	  cur_st <= S_IDLE;
	else if (~en)
	  cur_st <= S_IDLE;
	else
	  cur_st <= next_st;
     end

   always @(*) begin
      case (cur_st)
	S_IDLE:
	  if (|int_frmbuf_addr_valid_pulse)
	    next_st = S_WAIT_REQ;
	  else
	    next_st = S_IDLE;
	S_WAIT_REQ:
	  if (~empty)
	    //next_st = S_C0_WAIT_END;
	    next_st = S_WAIT_END;
	  else
	    next_st = S_WAIT_REQ;
	S_C0_WAIT_END:
	  // int_frmbuf_addr_end points to the last byte address of the buffer
          if ( (~empty & axi_bresp_valid & axi_bresp_ok) == 1
	       && req_resp_inrange == 1  // in range
	       && req_resp_axaddr  >=  ((c0_frmbuf_addr_end >> (req_resp_chan_id*C_FRMBUF_ADDR_WIDTH)) & {C_FRMBUF_ADDR_WIDTH{1'b1}}) )
	       //&& req_resp[rd_ptr[3:0]][0] == 1  // in range
	       //&& req_resp[rd_ptr[3:0]][3 +: C_FRMBUF_ADDR_WIDTH] >=  ((c0_frmbuf_addr_end >> (req_resp_chan_id*C_FRMBUF_ADDR_WIDTH)) & {C_FRMBUF_ADDR_WIDTH{1'b1}}) )
	     next_st = S_C0_END;
	  else if (timeout[req_resp_chan_id_p])
	    next_st = S_END;
	  else
	    next_st = S_C0_WAIT_END;
	S_C1_WAIT_END:
	  // int_frmbuf_addr_end points to the last byte address of the buffer
	  if ( (~empty & axi_bresp_valid & axi_bresp_ok) == 1
	       && req_resp_inrange == 1  // in range
	       && req_resp_axaddr  >=  ((c1_frmbuf_addr_end >> (req_resp_chan_id*C_FRMBUF_ADDR_WIDTH)) & {C_FRMBUF_ADDR_WIDTH{1'b1}}) )
	       //&& req_resp[rd_ptr[3:0]][0] == 1  // in range
	       //&& req_resp[rd_ptr[3:0]][3 +: C_FRMBUF_ADDR_WIDTH] >=  ((c1_frmbuf_addr_end >> (req_resp_chan_id*C_FRMBUF_ADDR_WIDTH)) & {C_FRMBUF_ADDR_WIDTH{1'b1}}) )
	     next_st = S_C1_END;
	  else if (timeout[req_resp_chan_id_p])
	    next_st = S_END;
	  else
	    next_st = S_C1_WAIT_END;
	S_C2_WAIT_END:
	  // int_frmbuf_addr_end points to the last byte address of the buffer
	  if ( (~empty & axi_bresp_valid & axi_bresp_ok) == 1
	       && req_resp_inrange == 1  // in range
	       && req_resp_axaddr  >=  ((c2_frmbuf_addr_end >> (req_resp_chan_id*C_FRMBUF_ADDR_WIDTH)) & {C_FRMBUF_ADDR_WIDTH{1'b1}}) )
	       //&& req_resp[rd_ptr[3:0]][0] == 1  // in range
	       //&& req_resp[rd_ptr[3:0]][3 +: C_FRMBUF_ADDR_WIDTH] >=  ((c2_frmbuf_addr_end >> (req_resp_chan_id*C_FRMBUF_ADDR_WIDTH)) & {C_FRMBUF_ADDR_WIDTH{1'b1}}) )
	     next_st = S_C2_END;
	  else if (timeout[req_resp_chan_id_p])
	    next_st = S_END;
	  else
	    next_st = S_C2_WAIT_END;
	S_C3_WAIT_END:
	  // int_frmbuf_addr_end points to the last byte address of the buffer
	  if ( (~empty & axi_bresp_valid & axi_bresp_ok) == 1
	       && req_resp_inrange == 1  // in range
	       && req_resp_axaddr  >=  ((c3_frmbuf_addr_end >> (req_resp_chan_id*C_FRMBUF_ADDR_WIDTH)) & {C_FRMBUF_ADDR_WIDTH{1'b1}}) )
	       //&& req_resp[rd_ptr[3:0]][0] == 1  // in range
	       //&& req_resp[rd_ptr[3:0]][3 +: C_FRMBUF_ADDR_WIDTH] >=  ((c3_frmbuf_addr_end >> (req_resp_chan_id*C_FRMBUF_ADDR_WIDTH)) & {C_FRMBUF_ADDR_WIDTH{1'b1}}) )
	     next_st = S_C3_END;
	  else if (timeout[req_resp_chan_id_p])
	    next_st = S_END;
	  else
	    next_st = S_C3_WAIT_END;
	S_WAIT_END:
	  // int_frmbuf_addr_end points to the last byte address of the buffer
          if (C_DEC_ENC_N)
          begin
	    if ( ((~empty & axi_bresp_valid & axi_bresp_ok) == 1) &&
                 (req_resp_inrange == 1) &&  // in range
                 (req_resp_axaddr  ==  (((int_frmbuf_addr_end >> (req_resp_chan_id*C_FRMBUF_ADDR_WIDTH)) + 1'b1) & 
                                                                        ({C_FRMBUF_ADDR_WIDTH{1'b1}})) ))
	      next_st = S_END;
	    //else if (timeout[req_resp_chan_id_p])
	    //  next_st = S_END;
	    else
	      next_st = S_WAIT_END;
          end
          else
          begin
	    if ( ((~empty & axi_bresp_valid & axi_bresp_ok) == 1) &&
                 (req_resp_inrange == 1) &&  // in range
                 (req_resp_axaddr  >= ((int_frmbuf_addr_end >> (req_resp_chan_id*C_FRMBUF_ADDR_WIDTH)) & 
                                                                       ({C_FRMBUF_ADDR_WIDTH{1'b1}})) ))
	      next_st = S_END;
	    //else if (timeout[req_resp_chan_id_p])
	    //  next_st = S_END;
	    else
	      next_st = S_WAIT_END;

          end

	S_C0_END:
	  next_st = S_C1_WAIT_END;
	  //next_st  = S_IDLE;
	S_C1_END:
	  next_st = S_C2_WAIT_END;
	  //next_st  = S_IDLE;
	S_C2_END:
	  next_st = S_WAIT_END;
	  //next_st = S_C3_WAIT_END;
	  //next_st  = S_IDLE;
	S_C3_END:
	  next_st = S_WAIT_END;
	  //next_st  = S_IDLE;
	S_END:
	  next_st = S_IDLE;
	default: next_st = S_IDLE;
      endcase
   end

   //always @(posedge aclk or negedge aresetn)
   always @(posedge aclk)
     begin
	if (~aresetn) begin
	   frmbuf_addr_next <= {C_VIDEO_CHAN{1'b0}};
	   frmbuf_addr_done <= {C_VIDEO_CHAN{1'b0}};
	   frmbuf_c0_addr_done <= {C_VIDEO_CHAN{1'b0}};
	   frmbuf_c1_addr_done <= {C_VIDEO_CHAN{1'b0}};
	   frmbuf_c2_addr_done <= {C_VIDEO_CHAN{1'b0}};
	   frmbuf_c3_addr_done <= {C_VIDEO_CHAN{1'b0}};
	end
	else if (cur_st == S_END) begin
	   frmbuf_addr_next[req_resp_chan_id_p]    <= 1'b1; // to Ctrl to advance ring buffer
	   frmbuf_addr_done[req_resp_chan_id_p]    <= 1'b1; // to Consumer to flush data
	   frmbuf_c3_addr_done[req_resp_chan_id_p] <= 1'b1;
	end
	else if (cur_st == S_C0_END) begin
	  frmbuf_c0_addr_done[req_resp_chan_id_p] <= 1'b1;
	end
	else if (cur_st == S_C1_END) begin
	  frmbuf_c1_addr_done[req_resp_chan_id_p] <= 1'b1;
	end
	else if (cur_st == S_C2_END) begin
	  frmbuf_c2_addr_done[req_resp_chan_id_p] <= 1'b1;
	end
	//else if ((cur_st == S_C3_END) |
	//         (cur_st == S_END))begin
	//  frmbuf_c3_addr_done[req_resp_chan_id_p] <= 1'b1;
	//end
	else begin
	   frmbuf_addr_next <= {C_VIDEO_CHAN{1'b0}};
	   frmbuf_addr_done <= {C_VIDEO_CHAN{1'b0}};
	   frmbuf_c0_addr_done <= {C_VIDEO_CHAN{1'b0}};
	   frmbuf_c1_addr_done <= {C_VIDEO_CHAN{1'b0}};
	   frmbuf_c2_addr_done <= {C_VIDEO_CHAN{1'b0}};
	   frmbuf_c3_addr_done <= {C_VIDEO_CHAN{1'b0}};
	end
     end // always @ (posedge aclk or negedge aresetn)
   

   // Timeout counter
   //always @(posedge aclk or negedge aresetn)
   always @(posedge aclk)
     begin
	if (~aresetn) begin
	   timeout_counter <= 24'd0;
	   timeout <= {C_VIDEO_CHAN{1'b0}};
	end
	else if ((cur_st == S_WAIT_END)|
	         (cur_st == S_C0_WAIT_END) |
		 (cur_st == S_C1_WAIT_END) |
		 (cur_st == S_C2_WAIT_END) |
		 (cur_st == S_C3_WAIT_END) )
	begin
	   timeout_counter <= timeout_counter + 1;
	   if (timeout_counter == C_TIMEOUT) timeout[req_resp_chan_id_p] <= 1'b1;
	end
	else begin
	   timeout_counter <= 24'd0;
	   timeout <= {C_VIDEO_CHAN{1'b0}};
	   
	end
     end // always @ (posedge aclk or negedge aresetn)
   
   
endmodule


`timescale 1 ns / 1 ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Xilinx, Inc.
// Engineer: Davy Huang
// 
// Create Date: 04/24/2018 01:24:00 PM
// Design Name: VCU low latency synchronization IP
// Module Name: sync_ip_v1_0_2_ip
// Project Name: VCU low latency 
// Target Devices: Zynq UltraScale+ EV
// Tool Versions: Vivado 2018.1
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//`define TRIPLE_FF_SYNC

//Asynchronous reset synchronizer
module aresetn_sync
  (
   input i_aresetn,
   input clk,
   output o_aresetn);

   reg 	  r1, r2, r3;
   
   //always @(posedge clk or negedge i_aresetn)
   always @(posedge clk)
     begin
	if (~i_aresetn)
	  r1 <= 1'b0;
	else
	  r1 <= 1'b1;
     end

   //always @(posedge clk or negedge i_aresetn)
   always @(posedge clk)
     begin
	if (~i_aresetn)
	  r2 <= 1'b0;
	else
	  r2 <= r1;
     end

   //always @(posedge clk or negedge i_aresetn)
   always @(posedge clk)
     begin
	if (~i_aresetn)
	  r3 <= 1'b0;
	else
	  r3 <= r2;
     end
 
`ifdef TRIPLE_FF_SYNC
   assign o_aresetn = r3;
`else  
   assign o_aresetn = r2;
`endif
   
endmodule // aresetn_sync

//DFF synchronizer
module dff_sync
  (
   input wire i,
   input wire clk,
   output wire o);

   (* ASYNC_REG = "TRUE" *) reg r0 = 1'b0;
   reg 	      r1, r2;
   
   always @(posedge clk)
     begin
	r0 <= i;
	r1 <= r0;
	r2 <= r1;	
     end

`ifdef TRIPPLE_FF_SYNC
   assign o = r2;
`else
   assign o = r1;
`endif
   
endmodule // dff_sync

//DFF synchronizer w/ async reset
module dff_ar_sync
  (
   input wire i,
   input wire arst_n,
   input wire clk,
   output wire o);

   (* ASYNC_REG = "TRUE" *) reg r0 = 1'b0;

   reg 	      r1, r2;
   
   //always @(posedge clk or negedge arst_n)
   always @(posedge clk)
     begin
	if (~arst_n) begin
	   r0 <= 1'b0;
	   r1 <= 1'b0;
	   r2 <= 1'b0;   
	end
	else begin
	   r0 <= i;
	   r1 <= r0;
	   r2 <= r1;
	end
     end

`ifdef TRIPPLE_FF_SYNC
   assign o = r2;
`else
   assign o = r1;
`endif
  
   
endmodule // dff_ar_sync

//Pulse crossing async clock domains 
module pulse_crossing
  (
   input wire i,  // pulse in i_clk domain
   input wire i_clk,
   input wire i_arst_n,
   input wire o_clk,
   input wire o_arst_n, // for clk domain
   output wire o); // pulse in o_clk domain

   reg        i_p;
   wire       i_sync, o_sync;
   wire       o0;
   reg 	      o0_p;
   
   // extend i till it's captured on the o_clk domain
   //always @(posedge i_clk or negedge i_arst_n)
   always @(posedge i_clk)
     begin
	if (~i_arst_n)
	  i_p <= 1'b0;
	else if (i & ~o_sync) begin
	   if (i_p) // new pulse arrives, o_sync cleared, but i_p not yet cleared, 
	     // this is an error condition indicating arrival of new pulse is too soon
	     begin
//synthesis translate_off
		$display ("[%m:%0t] ERROR: Pulse interval is too small for the circuit to handle", $time);
		//$stop;
//synthesis translate_on		
	     end
	   else
	     i_p <= 1'b1;
	end
	else if (i & o_sync) begin
	   if (i_p) // input pulse stays high (very wide pulse) even o_sync appears, stop extending the pulse
	     i_p <= 1'b0;
	   else begin // new arrival of pulse before o_sync cleared
	      i_p <= 1'b1;
	   end
	end
	else if (~i & o_sync) begin // input removed but o_sync not yet appears
	  i_p <= 1'b0;
	end
     end

   // forward sync FFs
   dff_ar_sync i_sync2_o (.i ((i | i_p) & ~o_sync ),
			  .arst_n (o_arst_n),
			  .clk (o_clk),
			  .o (i_sync));

   // backward sync FFs
   dff_ar_sync o_sync2_i (.i (i_sync),
			  .arst_n (i_arst_n),
			  .clk (i_clk),
			  .o (o_sync));

   assign o0 = i_sync;

   
   //always @(posedge o_clk or negedge o_arst_n)
   always @(posedge o_clk)
     begin
	if (~o_arst_n) begin
	   o0_p <= 1'b0;
	end
	else begin
	   o0_p <= o0;
	end
     end
   
   // pulse the output
   assign o = o0 & ~o0_p;
   
endmodule


`timescale 1 ns / 1 ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Xilinx, Inc.
// Engineer: Davy Huang
// 
// Create Date: 04/24/2018 01:24:00 PM
// Design Name: VCU low latency synchronization IP
// Module Name: sync_ip_v1_0_2_S_AXI_CTRL
// Project Name: VCU low latency 
// Target Devices: Zynq UltraScale+ EV
// Tool Versions: Vivado 2018.1
// Description: 
// 
// Dependencies:
//  
// SW programming behavior:
// 1. Must program threshold, margin, end address, start address, then
//  assert valid bit at last
// 2. As SW rotates among those 3 ring-buffer addresses, it must set or clear
//  the next address entry *before* HW finish processing the current address 
// (i.e. Producer finishes writing from start to end end address). Otherwise,
//  HW will read the old value from the next entry and cause error.
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
// TODO: 1. Add IRQ mask
//       2. Add debug regs
//////////////////////////////////////////////////////////////////////////////////

module syn_ip_v1_0_S_AXI_CTRL #
  (
   // Users to add parameters here
   parameter integer C_NUM_CHAN = 4, // Number of channels supported
   parameter integer C_DEC_ENC_N = 0, // Encoder (0) or Decoder (1)
   parameter integer C_FRMBUF_ADDR_WIDTH = 44,
   
   // User parameters ends
   // Do not modify the parameters beyond this line

   // Width of S_AXI data bus
   parameter integer C_S_AXI_DATA_WIDTH	= 32,
   // Width of S_AXI address bus
   parameter integer C_S_AXI_ADDR_WIDTH	= 12
   )
   (
    // Users to add ports here
    // ctrl_aclk domain
    (* mark_debug = "true" *) output reg [C_NUM_CHAN-1:0] en,
   (* mark_debug = "true" *) output wire                   irq, //output to IRQ line
   (* mark_debug = "true" *) output wire  [C_NUM_CHAN-1:0] S_AXI_SW_ARESET, //Software reset
   (* mark_debug = "true" *) output reg [C_NUM_CHAN-1:0] buf_rd_cnt_en,

   (* mark_debug = "true" *) output reg [C_FRMBUF_ADDR_WIDTH*C_NUM_CHAN-1:0] prod_luma_frmbuf_start_addr,
   (* mark_debug = "true" *) output reg [C_FRMBUF_ADDR_WIDTH*C_NUM_CHAN-1:0] prod_luma_frmbuf_end_addr,
   (* mark_debug = "true" *) output reg [32*C_NUM_CHAN-1:0] prod_luma_frmbuf_margin,
   (* mark_debug = "true" *) output reg [C_NUM_CHAN-1:0] prod_luma_frmbuf_addr_valid_pulse, //pulsed address valid to indicate above 3 values are valid

   (* mark_debug = "true" *) output reg [C_FRMBUF_ADDR_WIDTH*C_NUM_CHAN-1:0] prod_chroma_frmbuf_start_addr,
   (* mark_debug = "true" *) output reg [C_FRMBUF_ADDR_WIDTH*C_NUM_CHAN-1:0] prod_chroma_frmbuf_end_addr,
   (* mark_debug = "true" *) output reg [32*C_NUM_CHAN-1:0] prod_chroma_frmbuf_margin,
   (* mark_debug = "true" *) output reg [C_NUM_CHAN-1:0] prod_chroma_frmbuf_addr_valid_pulse, //pulsed address valid to indicate above 3 values are valid

    
   (* mark_debug = "true" *) output reg [C_FRMBUF_ADDR_WIDTH*C_NUM_CHAN-1:0] cons_luma_frmbuf_start_addr,
   (* mark_debug = "true" *) output reg [C_FRMBUF_ADDR_WIDTH*C_NUM_CHAN-1:0] cons_luma_frmbuf_end_addr,
   (* mark_debug = "true" *) output reg [32*C_NUM_CHAN-1:0] cons_luma_frmbuf_margin,
   (* mark_debug = "true" *) output reg [C_NUM_CHAN-1:0] cons_luma_frmbuf_addr_valid_pulse, //pulsed address valid to indicate above 3 values are valid

   (* mark_debug = "true" *) output reg [C_FRMBUF_ADDR_WIDTH*C_NUM_CHAN-1:0] cons_chroma_frmbuf_start_addr,
   (* mark_debug = "true" *) output reg [C_FRMBUF_ADDR_WIDTH*C_NUM_CHAN-1:0] cons_chroma_frmbuf_end_addr,
   (* mark_debug = "true" *) output reg [32*C_NUM_CHAN-1:0] cons_chroma_frmbuf_margin,
   (* mark_debug = "true" *) output reg [C_NUM_CHAN-1:0] cons_chroma_frmbuf_addr_valid_pulse, //pulsed address valid to indicate above 3 values are valid
       
    output reg [32-1:0]  luma_c0_offset, //#### Offsets and factor value addition 
    output reg [32-1:0]  luma_c1_offset,
    output reg [32-1:0]  luma_c2_offset,
    output reg [32-1:0]  luma_c3_offset,
    output reg [32-1:0]  chroma_c0_offset, //#### Offsets and factor value addition 
    output reg [32-1:0]  chroma_c1_offset,
    output reg [32-1:0]  chroma_c2_offset,
    output reg [32-1:0]  chroma_c3_offset,

   (* mark_debug = "true" *) output wire [2*C_NUM_CHAN-1:0] 			  prod_luma_buf_id, //shreyas
   (* mark_debug = "true" *) output wire [2*C_NUM_CHAN-1:0] 			  prod_chroma_buf_id,//shreyas
   (* mark_debug = "true" *) output wire [2*C_NUM_CHAN-1:0] 			  cons_luma_buf_id,//shreyas
   (* mark_debug = "true" *) output wire [2*C_NUM_CHAN-1:0] 			  cons_chroma_buf_id,//shreyas
 
    // producer_aclk domain
    input wire producer_aclk,
    input wire producer_aresetn,
    input wire [C_NUM_CHAN-1:0] prod_err_syncfail,
    input wire [C_NUM_CHAN-1:0] prod_err_wdt,
   (* mark_debug = "true" *) input wire [C_NUM_CHAN-1:0] prod_luma_frmbuf_addr_next,
   (* mark_debug = "true" *) input wire [C_NUM_CHAN-1:0] prod_chroma_frmbuf_addr_next,
   (* mark_debug = "true" *) input wire [C_NUM_CHAN-1:0] prod_luma_frmbuf_addr_done,
   (* mark_debug = "true" *) input wire [C_NUM_CHAN-1:0] prod_chroma_frmbuf_addr_done,

    // consumer_aclk domain
    input wire consumer_aclk,
    input wire consumer_aresetn,
    input wire [C_NUM_CHAN-1:0] cons_err_syncfail,
    input wire [C_NUM_CHAN-1:0] cons_err_wdt,
   (* mark_debug = "true" *) input wire [C_NUM_CHAN-1:0] cons_luma_frmbuf_addr_next,
   (* mark_debug = "true" *) input wire [C_NUM_CHAN-1:0] cons_luma_frmbuf_addr_done,
   (* mark_debug = "true" *) input wire [C_NUM_CHAN-1:0] cons_chroma_frmbuf_addr_next,
    (* mark_debug = "true" *)input wire [C_NUM_CHAN-1:0] cons_chroma_frmbuf_addr_done,
    
    
    // User ports ends
    // Do not modify the ports beyond this line

    // Global Clock Signal
    input wire  S_AXI_ACLK,
    // Global Reset Signal. This Signal is Active LOW
    input wire  S_AXI_ARESETN,
    // Write address (issued by master, acceped by Slave)
   (* mark_debug = "true" *) input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    // Write channel Protection type. This signal indicates the
    // privilege and security level of the transaction, and whether
    // the transaction is a data access or an instruction access.
    input wire [2 : 0] S_AXI_AWPROT,
    // Write address valid. This signal indicates that the master signaling
    // valid write address and control information.
   (* mark_debug = "true" *) input wire  S_AXI_AWVALID,
    // Write address ready. This signal indicates that the slave is ready
    // to accept an address and associated control signals.
   (* mark_debug = "true" *) output wire  S_AXI_AWREADY,
    // Write data (issued by master, acceped by Slave) 
   (* mark_debug = "true" *) input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    // Write strobes. This signal indicates which byte lanes hold
    // valid data. There is one write strobe bit for each eight
    // bits of the write data bus.    
   (* mark_debug = "true" *) input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    // Write valid. This signal indicates that valid write
    // data and strobes are available.
   (* mark_debug = "true" *) input wire  S_AXI_WVALID,
    // Write ready. This signal indicates that the slave
    // can accept the write data.
   (* mark_debug = "true" *) output wire  S_AXI_WREADY,
    // Write response. This signal indicates the status
    // of the write transaction.
   (* mark_debug = "true" *) output wire [1 : 0] S_AXI_BRESP,
    // Write response valid. This signal indicates that the channel
    // is signaling a valid write response.
   (* mark_debug = "true" *) output wire  S_AXI_BVALID,
    // Response ready. This signal indicates that the master
    // can accept a write response.
   (* mark_debug = "true" *) input wire  S_AXI_BREADY,
    // Read address (issued by master, acceped by Slave)
   (* mark_debug = "true" *) input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    // Protection type. This signal indicates the privilege
    // and security level of the transaction, and whether the
    // transaction is a data access or an instruction access.
    input wire [2 : 0] S_AXI_ARPROT,
    // Read address valid. This signal indicates that the channel
    // is signaling valid read address and control information.
   (* mark_debug = "true" *) input wire  S_AXI_ARVALID,
    // Read address ready. This signal indicates that the slave is
    // ready to accept an address and associated control signals.
   (* mark_debug = "true" *) output wire  S_AXI_ARREADY,
    // Read data (issued by slave)
   (* mark_debug = "true" *) output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    // Read response. This signal indicates the status of the
    // read transfer.
   (* mark_debug = "true" *) output wire [1 : 0] S_AXI_RRESP,
    // Read valid. This signal indicates that the channel is
    // signaling the required read data.
   (* mark_debug = "true" *) output wire  S_AXI_RVALID,
    // Read ready. This signal indicates that the master can
    // accept the read data and response information.
   (* mark_debug = "true" *) input wire  S_AXI_RREADY
    );

   // AXI4LITE signals
  (* mark_debug = "true" *) reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_awaddr;
  (* mark_debug = "true" *) reg 				  axi_awready;
  (* mark_debug = "true" *) reg 				  axi_wready;
  (* mark_debug = "true" *) reg [1 : 0] 			  axi_bresp;
  (* mark_debug = "true" *) reg 				  axi_bvalid;
  (* mark_debug = "true" *) reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_araddr;
  (* mark_debug = "true" *) reg 				  axi_arready;
  (* mark_debug = "true" *) reg [C_S_AXI_DATA_WIDTH-1 : 0] axi_rdata;
  (* mark_debug = "true" *) reg [1 : 0] 			  axi_rresp;
  (* mark_debug = "true" *) reg 				  axi_rvalid;

  //New addition of Consumer register to avoid overlapping //####
  reg [31:0] luma_line_offset;
  reg [31:0] chroma_line_offset;

  (* mark_debug = "true" *) reg [19:0] half_point_one_ms_cnt;
  (* mark_debug = "true" *) reg half_point_one_ms_clk;

   // Example-specific design signals
   // local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
   // ADDR_LSB is used for addressing 32/64 bit registers/memories
   // ADDR_LSB = 2 for 32 bits (n downto 2)
   // ADDR_LSB = 3 for 64 bits (n downto 3)
   localparam integer 		  ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;  // 2
   localparam integer 		  OPT_MEM_ADDR_BITS = 5; // total 2^(5+1)=64 x 32b registers
   localparam integer             CONS_REG_ADDR_BITS =8; //Consumer specific registers starts from 0x400
   localparam integer             CHAN_ADDR_LSB = 8;  // 
   localparam integer 		  ADDR_VALID_WIDTH = C_FRMBUF_ADDR_WIDTH +1;
   
    
   //----------------------------------------------
   //-- Signals for user logic register space example
   //------------------------------------------------
   //-- Number of Slave Registers 32
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg0 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg1 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg2 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg3 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg4 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg5 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg6 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg7 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg8 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg9 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg10 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg11 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg12 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg13 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg14 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg15 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg16 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg17 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg18 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg19 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg20 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg21 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg22 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg23 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg24 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg25 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg26 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg27 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg28 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg29 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg30 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg31 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg32 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg33 [0:C_NUM_CHAN-1];
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg34 [0:C_NUM_CHAN-1];//####
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg35 [0:C_NUM_CHAN-1];//####
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg36 [0:C_NUM_CHAN-1];//####
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg37 [0:C_NUM_CHAN-1];//####
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg38 [0:C_NUM_CHAN-1];//####
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg39 [0:C_NUM_CHAN-1];//####
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg40 [0:C_NUM_CHAN-1];//####
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg41 [0:C_NUM_CHAN-1];//####
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg42 [0:C_NUM_CHAN-1];//####
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg43 [0:C_NUM_CHAN-1];//####
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg44 [0:C_NUM_CHAN-1];//####
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg45 [0:C_NUM_CHAN-1];//####
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg46 [0:C_NUM_CHAN-1];//####
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg47 [0:C_NUM_CHAN-1];//####
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg48 [0:C_NUM_CHAN-1];//####
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg49 [0:C_NUM_CHAN-1];//####
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg50 [0:C_NUM_CHAN-1];//####
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg51 [0:C_NUM_CHAN-1];//####
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg52 [0:C_NUM_CHAN-1];//####
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg53 [0:C_NUM_CHAN-1];//####
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg54 [0:C_NUM_CHAN-1];//####
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg55 [0:C_NUM_CHAN-1];//####
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg56 [0:C_NUM_CHAN-1];//####
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg57 [0:C_NUM_CHAN-1];//####
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg58 [0:C_NUM_CHAN-1];//####
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg59 [0:C_NUM_CHAN-1];//####
   reg [C_S_AXI_DATA_WIDTH-1:0]   slv_reg60 [0:C_NUM_CHAN-1];//####
   reg [C_S_AXI_DATA_WIDTH-1:0]   cons_slv_reg0; //Luma core0 offset 
   reg [C_S_AXI_DATA_WIDTH-1:0]   cons_slv_reg1; //Luma core1 offset
   reg [C_S_AXI_DATA_WIDTH-1:0]   cons_slv_reg2; //Luma core2 offset
   reg [C_S_AXI_DATA_WIDTH-1:0]   cons_slv_reg3; //Luma core3 offset
   reg [C_S_AXI_DATA_WIDTH-1:0]   cons_slv_reg4; //Chroma core0 offset
   reg [C_S_AXI_DATA_WIDTH-1:0]   cons_slv_reg5; //Chroma core1 offset
   reg [C_S_AXI_DATA_WIDTH-1:0]   cons_slv_reg6; //Chroma core2 offset
   reg [C_S_AXI_DATA_WIDTH-1:0]   cons_slv_reg7; //Chroma core3 offset
   reg [C_S_AXI_DATA_WIDTH-1:0]   cons_slv_reg8; //Luma length offset for additional lines on consumer //####
   reg [C_S_AXI_DATA_WIDTH-1:0]   cons_slv_reg9; //Chroma length offset //####

 
  (* mark_debug = "true" *) reg [1:0] 			  chan_awaddr;
  (* mark_debug = "true" *) reg [1:0] 			  chan_araddr;
  (* mark_debug = "true" *) reg 				  chan_awaddr_valid;
  (* mark_debug = "true" *) reg 				  chan_araddr_valid;

  (* mark_debug = "true" *) wire [(C_S_AXI_DATA_WIDTH * C_NUM_CHAN)-1:0]  int_prod_luma_buf_cnt;
  (* mark_debug = "true" *) wire [(C_S_AXI_DATA_WIDTH * C_NUM_CHAN)-1:0]  int_prod_chroma_buf_cnt;
  (* mark_debug = "true" *) wire [(C_S_AXI_DATA_WIDTH * C_NUM_CHAN)-1:0]  int_cons_luma_buf_cnt;
  (* mark_debug = "true" *) wire [(C_S_AXI_DATA_WIDTH * C_NUM_CHAN)-1:0]  int_cons_chroma_buf_cnt;
  (* mark_debug = "true" *) reg [C_NUM_CHAN-1:0] int_luma_buf_diff_err; 
  (* mark_debug = "true" *) reg [C_NUM_CHAN-1:0] int_chroma_buf_diff_err; 
   
   wire 			  slv_reg_rden;
   wire 			  slv_reg_wren;
   reg [C_S_AXI_DATA_WIDTH-1:0]   reg_data_out;
   reg [2:0]                      srst_cnt [0:C_NUM_CHAN-1];//####
   //wire                           S_AXI_SW_ARESET;//####
   wire [C_NUM_CHAN-1:0]          S_AXI_ARESET;
   wire                           rst;
   integer 			  byte_index;
  (* mark_debug = "true" *) reg 				  aw_en;

  (* mark_debug = "true" *) reg [C_FRMBUF_ADDR_WIDTH*C_NUM_CHAN-1:0] 			  prod_luma_start_addr [0:2];
  (* mark_debug = "true" *) reg [C_FRMBUF_ADDR_WIDTH*C_NUM_CHAN-1:0] 			  prod_chroma_start_addr [0:2];
  (* mark_debug = "true" *) reg [C_FRMBUF_ADDR_WIDTH*C_NUM_CHAN-1:0] 			  prod_luma_end_addr [0:2];
  (* mark_debug = "true" *) reg [C_FRMBUF_ADDR_WIDTH*C_NUM_CHAN-1:0] 			  prod_chroma_end_addr [0:2];
  (* mark_debug = "true" *) reg [C_FRMBUF_ADDR_WIDTH*C_NUM_CHAN-1:0] 			  cons_luma_start_addr [0:2];
  (* mark_debug = "true" *) reg [C_FRMBUF_ADDR_WIDTH*C_NUM_CHAN-1:0] 			  cons_chroma_start_addr [0:2];
  (* mark_debug = "true" *) reg [C_FRMBUF_ADDR_WIDTH*C_NUM_CHAN-1:0] 			  cons_luma_end_addr [0:2];
  (* mark_debug = "true" *) reg [C_FRMBUF_ADDR_WIDTH*C_NUM_CHAN-1:0] 			  cons_chroma_end_addr [0:2];
  (* mark_debug = "true" *) reg [C_S_AXI_DATA_WIDTH*C_NUM_CHAN-1:0] 			  prod_luma_addr_offset;//####
  (* mark_debug = "true" *) reg [C_S_AXI_DATA_WIDTH*C_NUM_CHAN-1:0] 			  prod_chroma_addr_offset;//####
   
   reg [32*C_NUM_CHAN-1:0] 			  frmbuf_luma_margin [0:2];
   reg [32*C_NUM_CHAN-1:0] 			  frmbuf_chroma_margin [0:2];

  //(* mark_debug = "true" *) wire [2*C_NUM_CHAN-1:0] 			  prod_luma_buf_id;
  (* mark_debug = "true" *) wire [C_NUM_CHAN-1:0] 			  prod_luma_buf_id_valid;   //pulsed buf_id valid
  //(* mark_debug = "true" *) wire [2*C_NUM_CHAN-1:0] 			  prod_chroma_buf_id;
  (* mark_debug = "true" *) wire [C_NUM_CHAN-1:0] 			  prod_chroma_buf_id_valid;   //pulsed buf_id valid

  //(* mark_debug = "true" *) wire [2*C_NUM_CHAN-1:0] 			  cons_luma_buf_id;
  (* mark_debug = "true" *) wire [C_NUM_CHAN-1:0] 			  cons_luma_buf_id_valid;   //pulsed buf_id valid
  //(* mark_debug = "true" *) wire [2*C_NUM_CHAN-1:0] 			  cons_chroma_buf_id;
  (* mark_debug = "true" *) wire [C_NUM_CHAN-1:0] 			  cons_chroma_buf_id_valid;   //pulsed buf_id valid
   
  (* mark_debug = "true" *) wire [C_NUM_CHAN-1:0] 			  int_prod_luma_frmbuf_addr_next;
  (* mark_debug = "true" *) wire [C_NUM_CHAN-1:0] 			  int_prod_chroma_frmbuf_addr_next;
  (* mark_debug = "true" *) wire [C_NUM_CHAN-1:0] 			  int_prod_luma_frmbuf_addr_done;
  (* mark_debug = "true" *) wire [C_NUM_CHAN-1:0] 			  int_prod_chroma_frmbuf_addr_done;

  (* mark_debug = "true" *) wire [C_NUM_CHAN-1:0] 			  int_cons_luma_frmbuf_addr_next;
  (* mark_debug = "true" *) wire [C_NUM_CHAN-1:0] 			  int_cons_luma_frmbuf_addr_done;
  (* mark_debug = "true" *) wire [C_NUM_CHAN-1:0] 			  int_cons_chroma_frmbuf_addr_next;
  (* mark_debug = "true" *) wire [C_NUM_CHAN-1:0] 			  int_cons_chroma_frmbuf_addr_done;

  (* mark_debug = "true" *) reg [2:0] 					  prod_luma_addr_valid [C_NUM_CHAN-1:0];
  (* mark_debug = "true" *) reg [2:0] 					  prod_chroma_addr_valid [C_NUM_CHAN-1:0];
  (* mark_debug = "true" *) reg [2:0] 					  cons_luma_addr_valid [C_NUM_CHAN-1:0];
  (* mark_debug = "true" *) reg [2:0] 					  cons_chroma_addr_valid [C_NUM_CHAN-1:0];

  (* mark_debug = "true" *) reg [2:0] 					  luma_skip_valid[C_NUM_CHAN-1:0];
  (* mark_debug = "true" *) reg [2:0] 					  chroma_skip_valid[C_NUM_CHAN-1:0];

   wire [C_NUM_CHAN-1:0] 			  int_luma_frmbuf_irq;
  (* mark_debug = "true" *) wire [2*C_NUM_CHAN-1:0] 			  int_luma_frmbuf_done;
  (* mark_debug = "true" *) wire [C_NUM_CHAN-1:0] 			  int_luma_frmbuf_skipped;

   wire [C_NUM_CHAN-1:0] 			  int_chroma_frmbuf_irq;
  (* mark_debug = "true" *) wire [2*C_NUM_CHAN-1:0] 			  int_chroma_frmbuf_done;
  (* mark_debug = "true" *) wire [C_NUM_CHAN-1:0] 			  int_chroma_frmbuf_skipped;
 
   wire [C_NUM_CHAN-1:0] 			  int_cons_luma_frmbuf_irq;
   wire [2*C_NUM_CHAN-1:0] 			  int_cons_luma_frmbuf_done;
   wire [C_NUM_CHAN-1:0] 			  int_cons_luma_frmbuf_skipped;

   wire [C_NUM_CHAN-1:0] 			  int_cons_chroma_frmbuf_irq;
   wire [2*C_NUM_CHAN-1:0] 			  int_cons_chroma_frmbuf_done;
   wire [C_NUM_CHAN-1:0] 			  int_cons_chroma_frmbuf_skipped;
   
  (* mark_debug = "true" *) reg [C_NUM_CHAN-1:0] 			  irq_en;
  (* mark_debug = "true" *) reg [C_NUM_CHAN-1:0] 			  int_irq;
   
   wire [C_NUM_CHAN-1:0] 			  int_prod_err_syncfail;
   wire [C_NUM_CHAN-1:0] 			  int_prod_err_wdt;
   
   wire [C_NUM_CHAN-1:0] 			  int_cons_err_syncfail;
   wire [C_NUM_CHAN-1:0] 			  int_cons_err_wdt;
   

  (* mark_debug = "true" *) wire [3*C_NUM_CHAN-1:0] 			  prod_luma_fsm_debug;
  (* mark_debug = "true" *) wire [3*C_NUM_CHAN-1:0] 			  prod_chroma_fsm_debug;
  (* mark_debug = "true" *) wire [3*C_NUM_CHAN-1:0] 			  cons_luma_fsm_debug;
  (* mark_debug = "true" *) wire [3*C_NUM_CHAN-1:0] 			  cons_chroma_fsm_debug;
 
 
  (* mark_debug = "true" *) reg  [C_NUM_CHAN-1:0] int_prod_luma_frmbuf_addr_done_rg;
  (* mark_debug = "true" *) reg  [C_NUM_CHAN-1:0] int_prod_chroma_frmbuf_addr_done_rg;
  (* mark_debug = "true" *) reg  [C_NUM_CHAN-1:0] int_cons_luma_frmbuf_addr_done_rg;
  (* mark_debug = "true" *) reg  [C_NUM_CHAN-1:0] int_cons_chroma_frmbuf_addr_done_rg;

  (* mark_debug = "true" *) reg  [15:0] prod_luma_buf0_cnt [0:C_NUM_CHAN-1]; 
  (* mark_debug = "true" *) reg  [15:0] cons_luma_buf0_cnt [0:C_NUM_CHAN-1]; 
  (* mark_debug = "true" *) reg  [19:0] prod_cons_luma_buf0_cnt [0:C_NUM_CHAN-1]; 
  (* mark_debug = "true" *) reg  [15:0] prod_luma_buf1_cnt [0:C_NUM_CHAN-1]; 
  (* mark_debug = "true" *) reg  [15:0] cons_luma_buf1_cnt [0:C_NUM_CHAN-1]; 
  (* mark_debug = "true" *) reg  [19:0] prod_cons_luma_buf1_cnt [0:C_NUM_CHAN-1]; 
  (* mark_debug = "true" *) reg  [15:0] prod_luma_buf2_cnt [0:C_NUM_CHAN-1]; 
  (* mark_debug = "true" *) reg  [15:0] cons_luma_buf2_cnt [0:C_NUM_CHAN-1]; 
  (* mark_debug = "true" *) reg  [19:0] prod_cons_luma_buf2_cnt [0:C_NUM_CHAN-1]; 

  (* mark_debug = "true" *) reg  [15:0] prod_chroma_buf0_cnt [0:C_NUM_CHAN-1]; 
  (* mark_debug = "true" *) reg  [15:0] cons_chroma_buf0_cnt [0:C_NUM_CHAN-1]; 
  (* mark_debug = "true" *) reg  [19:0] prod_cons_chroma_buf0_cnt [0:C_NUM_CHAN-1]; 
  (* mark_debug = "true" *) reg  [15:0] prod_chroma_buf1_cnt [0:C_NUM_CHAN-1]; 
  (* mark_debug = "true" *) reg  [15:0] cons_chroma_buf1_cnt [0:C_NUM_CHAN-1]; 
  (* mark_debug = "true" *) reg  [19:0] prod_cons_chroma_buf1_cnt [0:C_NUM_CHAN-1]; 
  (* mark_debug = "true" *) reg  [15:0] prod_chroma_buf2_cnt [0:C_NUM_CHAN-1]; 
  (* mark_debug = "true" *) reg  [15:0] cons_chroma_buf2_cnt [0:C_NUM_CHAN-1]; 
  (* mark_debug = "true" *) reg  [19:0] prod_cons_chroma_buf2_cnt [0:C_NUM_CHAN-1]; 
 
   //synthesis translate_off
   wire [31:0] debug_slv_reg00_0 = slv_reg0[0] [31:0];
   wire [31:0] debug_slv_reg00_1 = slv_reg0[1] [31:0];
   wire [31:0] debug_slv_reg00_2 = slv_reg0[2] [31:0];
   wire [31:0] debug_slv_reg00_3 = slv_reg0[3] [31:0];
   wire [31:0] debug_slv_reg01_0 = slv_reg1[0] [31:0];
   wire [31:0] debug_slv_reg01_1 = slv_reg1[1] [31:0];
   wire [31:0] debug_slv_reg01_2 = slv_reg1[2] [31:0];
   wire [31:0] debug_slv_reg01_3 = slv_reg1[3] [31:0];
   wire [31:0] debug_slv_reg02_0 = slv_reg2[0] [31:0];
   wire [31:0] debug_slv_reg02_1 = slv_reg2[1] [31:0];
   wire [31:0] debug_slv_reg02_2 = slv_reg2[2] [31:0];
   wire [31:0] debug_slv_reg02_3 = slv_reg2[3] [31:0];
   wire [31:0] debug_slv_reg03_0 = slv_reg3[0] [31:0];
   wire [31:0] debug_slv_reg03_1 = slv_reg3[1] [31:0];
   wire [31:0] debug_slv_reg03_2 = slv_reg3[2] [31:0];
   wire [31:0] debug_slv_reg03_3 = slv_reg3[3] [31:0];
   wire [31:0] debug_slv_reg04_0 = slv_reg4[0] [31:0];
   wire [31:0] debug_slv_reg04_1 = slv_reg4[1] [31:0];
   wire [31:0] debug_slv_reg04_2 = slv_reg4[2] [31:0];
   wire [31:0] debug_slv_reg04_3 = slv_reg4[3] [31:0];
   wire [31:0] debug_slv_reg05_0 = slv_reg5[0] [31:0];
   wire [31:0] debug_slv_reg05_1 = slv_reg5[1] [31:0];
   wire [31:0] debug_slv_reg05_2 = slv_reg5[2] [31:0];
   wire [31:0] debug_slv_reg05_3 = slv_reg5[3] [31:0];
   wire [31:0] debug_slv_reg06_0 = slv_reg6[0] [31:0];
   wire [31:0] debug_slv_reg06_1 = slv_reg6[1] [31:0];
   wire [31:0] debug_slv_reg06_2 = slv_reg6[2] [31:0];
   wire [31:0] debug_slv_reg06_3 = slv_reg6[3] [31:0];
   wire [31:0] debug_slv_reg07_0 = slv_reg7[0] [31:0];
   wire [31:0] debug_slv_reg07_1 = slv_reg7[1] [31:0];
   wire [31:0] debug_slv_reg07_2 = slv_reg7[2] [31:0];
   wire [31:0] debug_slv_reg07_3 = slv_reg7[3] [31:0];
   wire [31:0] debug_slv_reg08_0 = slv_reg8[0] [31:0];
   wire [31:0] debug_slv_reg08_1 = slv_reg8[1] [31:0];
   wire [31:0] debug_slv_reg08_2 = slv_reg8[2] [31:0];
   wire [31:0] debug_slv_reg08_3 = slv_reg8[3] [31:0];
   wire [31:0] debug_slv_reg09_0 = slv_reg9[0] [31:0];
   wire [31:0] debug_slv_reg09_1 = slv_reg9[1] [31:0];
   wire [31:0] debug_slv_reg09_2 = slv_reg9[2] [31:0];
   wire [31:0] debug_slv_reg09_3 = slv_reg9[3] [31:0];
   wire [31:0] debug_slv_reg10_0 = slv_reg10[0] [31:0];
   wire [31:0] debug_slv_reg10_1 = slv_reg10[1] [31:0];
   wire [31:0] debug_slv_reg10_2 = slv_reg10[2] [31:0];
   wire [31:0] debug_slv_reg10_3 = slv_reg10[3] [31:0];
   wire [31:0] debug_slv_reg11_0 = slv_reg11[0] [31:0];
   wire [31:0] debug_slv_reg11_1 = slv_reg11[1] [31:0];
   wire [31:0] debug_slv_reg11_2 = slv_reg11[2] [31:0];
   wire [31:0] debug_slv_reg11_3 = slv_reg11[3] [31:0];
   wire [31:0] debug_slv_reg12_0 = slv_reg12[0] [31:0];
   wire [31:0] debug_slv_reg12_1 = slv_reg12[1] [31:0];
   wire [31:0] debug_slv_reg12_2 = slv_reg12[2] [31:0];
   wire [31:0] debug_slv_reg12_3 = slv_reg12[3] [31:0];
   wire [31:0] debug_slv_reg13_0 = slv_reg13[0] [31:0];
   wire [31:0] debug_slv_reg13_1 = slv_reg13[1] [31:0];
   wire [31:0] debug_slv_reg13_2 = slv_reg13[2] [31:0];
   wire [31:0] debug_slv_reg13_3 = slv_reg13[3] [31:0];
   wire [31:0] debug_slv_reg14_0 = slv_reg14[0] [31:0];
   wire [31:0] debug_slv_reg14_1 = slv_reg14[1] [31:0];
   wire [31:0] debug_slv_reg14_2 = slv_reg14[2] [31:0];
   wire [31:0] debug_slv_reg14_3 = slv_reg14[3] [31:0];
   wire [31:0] debug_slv_reg15_0 = slv_reg15[0] [31:0];
   wire [31:0] debug_slv_reg15_1 = slv_reg15[1] [31:0];
   wire [31:0] debug_slv_reg15_2 = slv_reg15[2] [31:0];
   wire [31:0] debug_slv_reg15_3 = slv_reg15[3] [31:0];
   wire [31:0] debug_slv_reg16_0 = slv_reg16[0] [31:0];
   wire [31:0] debug_slv_reg16_1 = slv_reg16[1] [31:0];
   wire [31:0] debug_slv_reg16_2 = slv_reg16[2] [31:0];
   wire [31:0] debug_slv_reg16_3 = slv_reg16[3] [31:0];
   wire [31:0] debug_slv_reg17_0 = slv_reg17[0] [31:0];
   wire [31:0] debug_slv_reg17_1 = slv_reg17[1] [31:0];
   wire [31:0] debug_slv_reg17_2 = slv_reg17[2] [31:0];
   wire [31:0] debug_slv_reg17_3 = slv_reg17[3] [31:0];
   wire [31:0] debug_slv_reg18_0 = slv_reg18[0] [31:0];
   wire [31:0] debug_slv_reg18_1 = slv_reg18[1] [31:0];
   wire [31:0] debug_slv_reg18_2 = slv_reg18[2] [31:0];
   wire [31:0] debug_slv_reg18_3 = slv_reg18[3] [31:0];
   wire [31:0] debug_slv_reg19_0 = slv_reg19[0] [31:0];
   wire [31:0] debug_slv_reg19_1 = slv_reg19[1] [31:0];
   wire [31:0] debug_slv_reg19_2 = slv_reg19[2] [31:0];
   wire [31:0] debug_slv_reg19_3 = slv_reg19[3] [31:0];
   wire [31:0] debug_slv_reg20_0 = slv_reg20[0] [31:0];
   wire [31:0] debug_slv_reg20_1 = slv_reg20[1] [31:0];
   wire [31:0] debug_slv_reg20_2 = slv_reg20[2] [31:0];
   wire [31:0] debug_slv_reg20_3 = slv_reg20[3] [31:0];
   wire [31:0] debug_slv_reg21_0 = slv_reg21[0] [31:0];
   wire [31:0] debug_slv_reg21_1 = slv_reg21[1] [31:0];
   wire [31:0] debug_slv_reg21_2 = slv_reg21[2] [31:0];
   wire [31:0] debug_slv_reg21_3 = slv_reg21[3] [31:0];
   wire [31:0] debug_slv_reg22_0 = slv_reg22[0] [31:0];
   wire [31:0] debug_slv_reg22_1 = slv_reg22[1] [31:0];
   wire [31:0] debug_slv_reg22_2 = slv_reg22[2] [31:0];
   wire [31:0] debug_slv_reg22_3 = slv_reg22[3] [31:0];
   wire [31:0] debug_slv_reg23_0 = slv_reg23[0] [31:0];
   wire [31:0] debug_slv_reg23_1 = slv_reg23[1] [31:0];
   wire [31:0] debug_slv_reg23_2 = slv_reg23[2] [31:0];
   wire [31:0] debug_slv_reg23_3 = slv_reg23[3] [31:0];
   wire [31:0] debug_slv_reg24_0 = slv_reg24[0] [31:0];
   wire [31:0] debug_slv_reg24_1 = slv_reg24[1] [31:0];
   wire [31:0] debug_slv_reg24_2 = slv_reg24[2] [31:0];
   wire [31:0] debug_slv_reg24_3 = slv_reg24[3] [31:0];
   wire [31:0] debug_slv_reg25_0 = slv_reg25[0] [31:0];
   wire [31:0] debug_slv_reg25_1 = slv_reg25[1] [31:0];
   wire [31:0] debug_slv_reg25_2 = slv_reg25[2] [31:0];
   wire [31:0] debug_slv_reg25_3 = slv_reg25[3] [31:0];
   wire [31:0] debug_slv_reg26_0 = slv_reg26[0] [31:0];
   wire [31:0] debug_slv_reg26_1 = slv_reg26[1] [31:0];
   wire [31:0] debug_slv_reg26_2 = slv_reg26[2] [31:0];
   wire [31:0] debug_slv_reg26_3 = slv_reg26[3] [31:0];
   wire [31:0] debug_slv_reg27_0 = slv_reg27[0] [31:0];
   wire [31:0] debug_slv_reg27_1 = slv_reg27[1] [31:0];
   wire [31:0] debug_slv_reg27_2 = slv_reg27[2] [31:0];
   wire [31:0] debug_slv_reg27_3 = slv_reg27[3] [31:0];
   wire [31:0] debug_slv_reg28_0 = slv_reg28[0] [31:0];
   wire [31:0] debug_slv_reg28_1 = slv_reg28[1] [31:0];
   wire [31:0] debug_slv_reg28_2 = slv_reg28[2] [31:0];
   wire [31:0] debug_slv_reg28_3 = slv_reg28[3] [31:0];
   wire [31:0] debug_slv_reg29_0 = slv_reg29[0] [31:0];
   wire [31:0] debug_slv_reg29_1 = slv_reg29[1] [31:0];
   wire [31:0] debug_slv_reg29_2 = slv_reg29[2] [31:0];
   wire [31:0] debug_slv_reg29_3 = slv_reg29[3] [31:0];
   wire [31:0] debug_slv_reg30_0 = slv_reg30[0] [31:0];
   wire [31:0] debug_slv_reg30_1 = slv_reg30[1] [31:0];
   wire [31:0] debug_slv_reg30_2 = slv_reg30[2] [31:0];
   wire [31:0] debug_slv_reg30_3 = slv_reg30[3] [31:0];
   wire [31:0] debug_slv_reg31_0 = slv_reg31[0] [31:0];
   wire [31:0] debug_slv_reg31_1 = slv_reg31[1] [31:0];
   wire [31:0] debug_slv_reg31_2 = slv_reg31[2] [31:0];
   wire [31:0] debug_slv_reg31_3 = slv_reg31[3] [31:0];
   wire [31:0] debug_slv_reg32_0 = slv_reg32[0] [31:0];
   wire [31:0] debug_slv_reg32_1 = slv_reg32[1] [31:0];
   wire [31:0] debug_slv_reg32_2 = slv_reg32[2] [31:0];
   wire [31:0] debug_slv_reg32_3 = slv_reg32[3] [31:0];
   wire [31:0] debug_slv_reg33_0 = slv_reg33[0] [31:0];
   wire [31:0] debug_slv_reg33_1 = slv_reg33[1] [31:0];
   wire [31:0] debug_slv_reg33_2 = slv_reg33[2] [31:0];
   wire [31:0] debug_slv_reg33_3 = slv_reg33[3] [31:0];
   wire [31:0] debug_slv_reg34_0 = slv_reg34[0] [31:0];
   wire [31:0] debug_slv_reg34_1 = slv_reg34[1] [31:0];
   wire [31:0] debug_slv_reg34_2 = slv_reg34[2] [31:0];
   wire [31:0] debug_slv_reg34_3 = slv_reg34[3] [31:0];
   wire [31:0] debug_slv_reg35_0 = slv_reg35[0] [31:0];
   wire [31:0] debug_slv_reg35_1 = slv_reg35[1] [31:0];
   wire [31:0] debug_slv_reg35_2 = slv_reg35[2] [31:0];
   wire [31:0] debug_slv_reg35_3 = slv_reg35[3] [31:0];
   wire [31:0] debug_slv_reg36_0 = slv_reg36[0] [31:0];
   wire [31:0] debug_slv_reg36_1 = slv_reg36[1] [31:0];
   wire [31:0] debug_slv_reg36_2 = slv_reg36[2] [31:0];
   wire [31:0] debug_slv_reg36_3 = slv_reg36[3] [31:0];
   wire [31:0] debug_slv_reg37_0 = slv_reg37[0] [31:0];
   wire [31:0] debug_slv_reg37_1 = slv_reg37[1] [31:0];
   wire [31:0] debug_slv_reg37_2 = slv_reg37[2] [31:0];
   wire [31:0] debug_slv_reg37_3 = slv_reg37[3] [31:0];
   wire [31:0] debug_slv_reg38_0 = slv_reg38[0] [31:0];
   wire [31:0] debug_slv_reg38_1 = slv_reg38[1] [31:0];
   wire [31:0] debug_slv_reg38_2 = slv_reg38[2] [31:0];
   wire [31:0] debug_slv_reg38_3 = slv_reg38[3] [31:0];
   wire [31:0] debug_slv_reg39_0 = slv_reg39[0] [31:0];
   wire [31:0] debug_slv_reg39_1 = slv_reg39[1] [31:0];
   wire [31:0] debug_slv_reg39_2 = slv_reg39[2] [31:0];
   wire [31:0] debug_slv_reg39_3 = slv_reg39[3] [31:0];
   wire [31:0] debug_slv_reg40_0 = slv_reg40[0] [31:0];
   wire [31:0] debug_slv_reg40_1 = slv_reg40[1] [31:0];
   wire [31:0] debug_slv_reg40_2 = slv_reg40[2] [31:0];
   wire [31:0] debug_slv_reg40_3 = slv_reg40[3] [31:0];
   wire [31:0] debug_slv_reg41_0 = slv_reg41[0] [31:0];
   wire [31:0] debug_slv_reg41_1 = slv_reg41[1] [31:0];
   wire [31:0] debug_slv_reg41_2 = slv_reg41[2] [31:0];
   wire [31:0] debug_slv_reg41_3 = slv_reg41[3] [31:0];
   wire [31:0] debug_slv_reg42_0 = slv_reg42[0] [31:0];
   wire [31:0] debug_slv_reg42_1 = slv_reg42[1] [31:0];
   wire [31:0] debug_slv_reg42_2 = slv_reg42[2] [31:0];
   wire [31:0] debug_slv_reg42_3 = slv_reg42[3] [31:0];
   wire [31:0] debug_slv_reg43_0 = slv_reg43[0] [31:0];
   wire [31:0] debug_slv_reg43_1 = slv_reg43[1] [31:0];
   wire [31:0] debug_slv_reg43_2 = slv_reg43[2] [31:0];
   wire [31:0] debug_slv_reg43_3 = slv_reg43[3] [31:0];
   wire [31:0] debug_slv_reg44_0 = slv_reg44[0] [31:0];
   wire [31:0] debug_slv_reg44_1 = slv_reg44[1] [31:0];
   wire [31:0] debug_slv_reg44_2 = slv_reg44[2] [31:0];
   wire [31:0] debug_slv_reg44_3 = slv_reg44[3] [31:0];
   wire [31:0] debug_slv_reg45_0 = slv_reg45[0] [31:0];
   wire [31:0] debug_slv_reg45_1 = slv_reg45[1] [31:0];
   wire [31:0] debug_slv_reg45_2 = slv_reg45[2] [31:0];
   wire [31:0] debug_slv_reg45_3 = slv_reg45[3] [31:0];
   wire [31:0] debug_slv_reg46_0 = slv_reg46[0] [31:0];
   wire [31:0] debug_slv_reg46_1 = slv_reg46[1] [31:0];
   wire [31:0] debug_slv_reg46_2 = slv_reg46[2] [31:0];
   wire [31:0] debug_slv_reg46_3 = slv_reg46[3] [31:0];
   wire [31:0] debug_slv_reg47_0 = slv_reg47[0] [31:0];
   wire [31:0] debug_slv_reg47_1 = slv_reg47[1] [31:0];
   wire [31:0] debug_slv_reg47_2 = slv_reg47[2] [31:0];
   wire [31:0] debug_slv_reg47_3 = slv_reg47[3] [31:0];
   wire [31:0] debug_slv_reg48_0 = slv_reg48[0] [31:0];
   wire [31:0] debug_slv_reg48_1 = slv_reg48[1] [31:0];
   wire [31:0] debug_slv_reg48_2 = slv_reg48[2] [31:0];
   wire [31:0] debug_slv_reg48_3 = slv_reg48[3] [31:0];
   wire [31:0] debug_slv_reg49_0 = slv_reg49[0] [31:0];
   wire [31:0] debug_slv_reg49_1 = slv_reg49[1] [31:0];
   wire [31:0] debug_slv_reg49_2 = slv_reg49[2] [31:0];
   wire [31:0] debug_slv_reg49_3 = slv_reg49[3] [31:0];
   wire [31:0] debug_slv_reg50_0 = slv_reg50[0] [31:0];
   wire [31:0] debug_slv_reg50_1 = slv_reg50[1] [31:0];
   wire [31:0] debug_slv_reg50_2 = slv_reg50[2] [31:0];
   wire [31:0] debug_slv_reg50_3 = slv_reg50[3] [31:0];
   wire [31:0] debug_slv_reg51_0 = slv_reg51[0] [31:0];
   wire [31:0] debug_slv_reg51_1 = slv_reg51[1] [31:0];
   wire [31:0] debug_slv_reg51_2 = slv_reg51[2] [31:0];
   wire [31:0] debug_slv_reg51_3 = slv_reg51[3] [31:0];
   wire [31:0] debug_slv_reg52_0 = slv_reg52[0] [31:0];
   wire [31:0] debug_slv_reg52_1 = slv_reg52[1] [31:0];
   wire [31:0] debug_slv_reg52_2 = slv_reg52[2] [31:0];
   wire [31:0] debug_slv_reg52_3 = slv_reg52[3] [31:0];
   wire [31:0] debug_slv_reg53_0 = slv_reg53[0] [31:0];
   wire [31:0] debug_slv_reg53_1 = slv_reg53[1] [31:0];
   wire [31:0] debug_slv_reg53_2 = slv_reg53[2] [31:0];
   wire [31:0] debug_slv_reg53_3 = slv_reg53[3] [31:0];
   wire [31:0] debug_slv_reg54_0 = slv_reg54[0] [31:0];
   wire [31:0] debug_slv_reg54_1 = slv_reg54[1] [31:0];
   wire [31:0] debug_slv_reg54_2 = slv_reg54[2] [31:0];
   wire [31:0] debug_slv_reg54_3 = slv_reg54[3] [31:0];
   wire [31:0] debug_slv_reg55_0 = slv_reg55[0] [31:0];
   wire [31:0] debug_slv_reg55_1 = slv_reg55[1] [31:0];
   wire [31:0] debug_slv_reg55_2 = slv_reg55[2] [31:0];
   wire [31:0] debug_slv_reg55_3 = slv_reg55[3] [31:0];
   wire [31:0] debug_slv_reg56_0 = slv_reg56[0] [31:0];
   wire [31:0] debug_slv_reg56_1 = slv_reg56[1] [31:0];
   wire [31:0] debug_slv_reg56_2 = slv_reg56[2] [31:0];
   wire [31:0] debug_slv_reg56_3 = slv_reg56[3] [31:0];
   wire [31:0] debug_slv_reg57_0 = slv_reg57[0] [31:0];
   wire [31:0] debug_slv_reg57_1 = slv_reg57[1] [31:0];
   wire [31:0] debug_slv_reg57_2 = slv_reg57[2] [31:0];
   wire [31:0] debug_slv_reg57_3 = slv_reg57[3] [31:0];
   wire [31:0] debug_slv_reg58_0 = slv_reg58[0] [31:0];
   wire [31:0] debug_slv_reg58_1 = slv_reg58[1] [31:0];
   wire [31:0] debug_slv_reg58_2 = slv_reg58[2] [31:0];
   wire [31:0] debug_slv_reg58_3 = slv_reg58[3] [31:0];
   wire [31:0] debug_slv_reg59_0 = slv_reg59[0] [31:0];
   wire [31:0] debug_slv_reg59_1 = slv_reg59[1] [31:0];
   wire [31:0] debug_slv_reg59_2 = slv_reg59[2] [31:0];
   wire [31:0] debug_slv_reg59_3 = slv_reg59[3] [31:0];
   wire [31:0] debug_slv_reg60_0 = slv_reg60[0] [31:0];
   wire [31:0] debug_slv_reg60_1 = slv_reg60[1] [31:0];
   wire [31:0] debug_slv_reg60_2 = slv_reg60[2] [31:0];
   wire [31:0] debug_slv_reg60_3 = slv_reg60[3] [31:0];

   wire [15:0] debug_prod_luma_buf0_cnt_0 = prod_luma_buf0_cnt[0][15:0];
   wire [15:0] debug_prod_luma_buf0_cnt_1 = prod_luma_buf0_cnt[1][15:0];
   wire [15:0] debug_prod_luma_buf0_cnt_2 = prod_luma_buf0_cnt[2][15:0];
   wire [15:0] debug_prod_luma_buf0_cnt_3 = prod_luma_buf0_cnt[3][15:0];
   wire [15:0] debug_prod_luma_buf1_cnt_0 = prod_luma_buf1_cnt[0][15:0];
   wire [15:0] debug_prod_luma_buf1_cnt_1 = prod_luma_buf1_cnt[1][15:0];
   wire [15:0] debug_prod_luma_buf1_cnt_2 = prod_luma_buf1_cnt[2][15:0];
   wire [15:0] debug_prod_luma_buf1_cnt_3 = prod_luma_buf1_cnt[3][15:0];
   wire [15:0] debug_prod_luma_buf2_cnt_0 = prod_luma_buf2_cnt[0][15:0];
   wire [15:0] debug_prod_luma_buf2_cnt_1 = prod_luma_buf2_cnt[1][15:0];
   wire [15:0] debug_prod_luma_buf2_cnt_2 = prod_luma_buf2_cnt[2][15:0];
   wire [15:0] debug_prod_luma_buf2_cnt_3 = prod_luma_buf2_cnt[3][15:0];

   wire [15:0] debug_cons_luma_buf0_cnt_0 = cons_luma_buf0_cnt[0][15:0];
   wire [15:0] debug_cons_luma_buf0_cnt_1 = cons_luma_buf0_cnt[1][15:0];
   wire [15:0] debug_cons_luma_buf0_cnt_2 = cons_luma_buf0_cnt[2][15:0];
   wire [15:0] debug_cons_luma_buf0_cnt_3 = cons_luma_buf0_cnt[3][15:0];
   wire [15:0] debug_cons_luma_buf1_cnt_0 = cons_luma_buf1_cnt[0][15:0];
   wire [15:0] debug_cons_luma_buf1_cnt_1 = cons_luma_buf1_cnt[1][15:0];
   wire [15:0] debug_cons_luma_buf1_cnt_2 = cons_luma_buf1_cnt[2][15:0];
   wire [15:0] debug_cons_luma_buf1_cnt_3 = cons_luma_buf1_cnt[3][15:0];
   wire [15:0] debug_cons_luma_buf2_cnt_0 = cons_luma_buf2_cnt[0][15:0];
   wire [15:0] debug_cons_luma_buf2_cnt_1 = cons_luma_buf2_cnt[1][15:0];
   wire [15:0] debug_cons_luma_buf2_cnt_2 = cons_luma_buf2_cnt[2][15:0];
   wire [15:0] debug_cons_luma_buf2_cnt_3 = cons_luma_buf2_cnt[3][15:0];

   wire [19:0] debug_prod_cons_luma_buf0_cnt_0 = prod_cons_luma_buf0_cnt[0][19:0];
   wire [19:0] debug_prod_cons_luma_buf0_cnt_1 = prod_cons_luma_buf0_cnt[1][19:0];
   wire [19:0] debug_prod_cons_luma_buf0_cnt_2 = prod_cons_luma_buf0_cnt[2][19:0];
   wire [19:0] debug_prod_cons_luma_buf0_cnt_3 = prod_cons_luma_buf0_cnt[3][19:0];
   wire [19:0] debug_prod_cons_luma_buf1_cnt_0 = prod_cons_luma_buf1_cnt[0][19:0];
   wire [19:0] debug_prod_cons_luma_buf1_cnt_1 = prod_cons_luma_buf1_cnt[1][19:0];
   wire [19:0] debug_prod_cons_luma_buf1_cnt_2 = prod_cons_luma_buf1_cnt[2][19:0];
   wire [19:0] debug_prod_cons_luma_buf1_cnt_3 = prod_cons_luma_buf1_cnt[3][19:0];
   wire [19:0] debug_prod_cons_luma_buf2_cnt_0 = prod_cons_luma_buf2_cnt[0][19:0];
   wire [19:0] debug_prod_cons_luma_buf2_cnt_1 = prod_cons_luma_buf2_cnt[1][19:0];
   wire [19:0] debug_prod_cons_luma_buf2_cnt_2 = prod_cons_luma_buf2_cnt[2][19:0];
   wire [19:0] debug_prod_cons_luma_buf2_cnt_3 = prod_cons_luma_buf2_cnt[3][19:0];

   wire [15:0] debug_prod_chroma_buf0_cnt_0 = prod_chroma_buf0_cnt[0][15:0];
   wire [15:0] debug_prod_chroma_buf0_cnt_1 = prod_chroma_buf0_cnt[1][15:0];
   wire [15:0] debug_prod_chroma_buf0_cnt_2 = prod_chroma_buf0_cnt[2][15:0];
   wire [15:0] debug_prod_chroma_buf0_cnt_3 = prod_chroma_buf0_cnt[3][15:0];
   wire [15:0] debug_prod_chroma_buf1_cnt_0 = prod_chroma_buf1_cnt[0][15:0];
   wire [15:0] debug_prod_chroma_buf1_cnt_1 = prod_chroma_buf1_cnt[1][15:0];
   wire [15:0] debug_prod_chroma_buf1_cnt_2 = prod_chroma_buf1_cnt[2][15:0];
   wire [15:0] debug_prod_chroma_buf1_cnt_3 = prod_chroma_buf1_cnt[3][15:0];
   wire [15:0] debug_prod_chroma_buf2_cnt_0 = prod_chroma_buf2_cnt[0][15:0];
   wire [15:0] debug_prod_chroma_buf2_cnt_1 = prod_chroma_buf2_cnt[1][15:0];
   wire [15:0] debug_prod_chroma_buf2_cnt_2 = prod_chroma_buf2_cnt[2][15:0];
   wire [15:0] debug_prod_chroma_buf2_cnt_3 = prod_chroma_buf2_cnt[3][15:0];

   wire [15:0] debug_cons_chroma_buf0_cnt_0 = cons_chroma_buf0_cnt[0][15:0];
   wire [15:0] debug_cons_chroma_buf0_cnt_1 = cons_chroma_buf0_cnt[1][15:0];
   wire [15:0] debug_cons_chroma_buf0_cnt_2 = cons_chroma_buf0_cnt[2][15:0];
   wire [15:0] debug_cons_chroma_buf0_cnt_3 = cons_chroma_buf0_cnt[3][15:0];
   wire [15:0] debug_cons_chroma_buf1_cnt_0 = cons_chroma_buf1_cnt[0][15:0];
   wire [15:0] debug_cons_chroma_buf1_cnt_1 = cons_chroma_buf1_cnt[1][15:0];
   wire [15:0] debug_cons_chroma_buf1_cnt_2 = cons_chroma_buf1_cnt[2][15:0];
   wire [15:0] debug_cons_chroma_buf1_cnt_3 = cons_chroma_buf1_cnt[3][15:0];
   wire [15:0] debug_cons_chroma_buf2_cnt_0 = cons_chroma_buf2_cnt[0][15:0];
   wire [15:0] debug_cons_chroma_buf2_cnt_1 = cons_chroma_buf2_cnt[1][15:0];
   wire [15:0] debug_cons_chroma_buf2_cnt_2 = cons_chroma_buf2_cnt[2][15:0];
   wire [15:0] debug_cons_chroma_buf2_cnt_3 = cons_chroma_buf2_cnt[3][15:0];

   wire [19:0] debug_prod_cons_chroma_buf0_cnt_0 = prod_cons_chroma_buf0_cnt[0][19:0];
   wire [19:0] debug_prod_cons_chroma_buf0_cnt_1 = prod_cons_chroma_buf0_cnt[1][19:0];
   wire [19:0] debug_prod_cons_chroma_buf0_cnt_2 = prod_cons_chroma_buf0_cnt[2][19:0];
   wire [19:0] debug_prod_cons_chroma_buf0_cnt_3 = prod_cons_chroma_buf0_cnt[3][19:0];
   wire [19:0] debug_prod_cons_chroma_buf1_cnt_0 = prod_cons_chroma_buf1_cnt[0][19:0];
   wire [19:0] debug_prod_cons_chroma_buf1_cnt_1 = prod_cons_chroma_buf1_cnt[1][19:0];
   wire [19:0] debug_prod_cons_chroma_buf1_cnt_2 = prod_cons_chroma_buf1_cnt[2][19:0];
   wire [19:0] debug_prod_cons_chroma_buf1_cnt_3 = prod_cons_chroma_buf1_cnt[3][19:0];
   wire [19:0] debug_prod_cons_chroma_buf2_cnt_0 = prod_cons_chroma_buf2_cnt[0][19:0];
   wire [19:0] debug_prod_cons_chroma_buf2_cnt_1 = prod_cons_chroma_buf2_cnt[1][19:0];
   wire [19:0] debug_prod_cons_chroma_buf2_cnt_2 = prod_cons_chroma_buf2_cnt[2][19:0];
   wire [19:0] debug_prod_cons_chroma_buf2_cnt_3 = prod_cons_chroma_buf2_cnt[3][19:0];


   //synthesis translate_on
   assign rst = | S_AXI_ARESET;
   // I/O Connections assignments
   assign irq = | int_irq;
   
   assign S_AXI_AWREADY	= axi_awready;
   assign S_AXI_WREADY	= axi_wready;
   assign S_AXI_BRESP	= axi_bresp;
   assign S_AXI_BVALID	= axi_bvalid;
   assign S_AXI_ARREADY	= axi_arready;
   assign S_AXI_RDATA	= axi_rdata;
   assign S_AXI_RRESP	= axi_rresp;
   assign S_AXI_RVALID	= axi_rvalid;
   // Implement axi_awready generation
   // axi_awready is asserted for one S_AXI_ACLK clock cycle when both
   // S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
   // de-asserted when reset is low.

   always @( posedge S_AXI_ACLK )
     begin
	if ( S_AXI_ARESETN == 1'b0 )
	//if ( (|S_AXI_ARESET) == 1'b0 )
        //if (rst == 1'b0)
	  begin
	     axi_awready <= 1'b0;
	     aw_en <= 1'b1;
	  end 
	else
	  begin    
	     if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	       begin
	          // slave is ready to accept write address when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_awready <= 1'b1;
	          aw_en <= 1'b0;
	       end
	     else if (S_AXI_BREADY && axi_bvalid)
	       begin
	          aw_en <= 1'b1;
	          axi_awready <= 1'b0;
	       end
	     else           
	       begin
	          axi_awready <= 1'b0;
	       end
	  end 
     end       

   // Implement axi_awaddr latching
   // This process is used to latch the address when both 
   // S_AXI_AWVALID and S_AXI_WVALID are valid. 

   always @( posedge S_AXI_ACLK)
   //always @( posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
   //always @( posedge S_AXI_ACLK or negedge S_AXI_ARESET)
   //always @( posedge S_AXI_ACLK or negedge rst)
     begin
	if ( S_AXI_ARESETN == 1'b0 )
	//if ( S_AXI_ARESET == 1'b0 )
	//if ( rst == 1'b0 )
	  begin
	     chan_awaddr_valid  <= 0;
	  end 
	else
	  begin    
	     if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	       begin
		  chan_awaddr_valid <= 1;
	       end
	  end 
     end       

   always @( posedge S_AXI_ACLK )
     begin
	if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	  begin
	     // Write Address latching 
	     axi_awaddr <= S_AXI_AWADDR;
	     chan_awaddr <= S_AXI_AWADDR[CHAN_ADDR_LSB +: 2];
	  end
     end 

   // Implement axi_wready generation
   // axi_wready is asserted for one S_AXI_ACLK clock cycle when both
   // S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
   // de-asserted when reset is low. 

   always @( posedge S_AXI_ACLK )
     begin
	if ( S_AXI_ARESETN == 1'b0 )
	//if ( S_AXI_ARESET == 1'b0 )
	//if ( rst == 1'b0 )
	  begin
	     axi_wready <= 1'b0;
	  end 
	else
	  begin    
	     if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
	       begin
	          // slave is ready to accept write data when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_wready <= 1'b1;
	       end
	     else
	       begin
	          axi_wready <= 1'b0;
	       end
	  end 
     end       

   // Implement memory mapped register select and write logic generation
   // The write data is accepted and written to memory mapped registers when
   // axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
   // select byte enables of slave registers while writing.
   // These registers are cleared when reset (active low) is applied.
   // Slave register write enable is asserted when valid address and data are available
   // and the slave is ready to accept the write address and write data.
   assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;
 
 //To generate 0.05ms clock
   always @ (posedge S_AXI_ACLK)
   begin
     if (S_AXI_ARESETN == 1'b0)
     begin
       half_point_one_ms_cnt <= {20{1'b0}};
       half_point_one_ms_clk <= 1'b1;
     end
     else
     begin
       if ( half_point_one_ms_cnt == 20'h 3A98) //0.05ms
       begin
         half_point_one_ms_cnt <= {20{1'b0}};
         half_point_one_ms_clk <= ~half_point_one_ms_clk;
       end
       else
       begin
         half_point_one_ms_cnt <= half_point_one_ms_cnt + 1'b1;
       end
     end
   end



   // Channel-specific registers
   genvar i;
   generate
      for (i=0; i<C_NUM_CHAN;i=i+1) begin: gen_chan_0
   
         assign S_AXI_ARESET[i] = (S_AXI_ARESETN & (~S_AXI_SW_ARESET[i]));//####

         always @ (posedge S_AXI_ACLK)
         begin
           if (S_AXI_ARESETN == 1'b0)
           begin
             int_prod_chroma_frmbuf_addr_done_rg[i] <= 1'b0;
             int_prod_luma_frmbuf_addr_done_rg[i]   <= 1'b0;
             int_cons_chroma_frmbuf_addr_done_rg[i] <= 1'b0;
             int_cons_luma_frmbuf_addr_done_rg[i]   <= 1'b0;
           end
           else
           begin
             int_prod_chroma_frmbuf_addr_done_rg[i] <= int_prod_chroma_frmbuf_addr_done[i];
             int_prod_luma_frmbuf_addr_done_rg[i]   <= int_prod_luma_frmbuf_addr_done[i]  ;
             int_cons_chroma_frmbuf_addr_done_rg[i] <= int_cons_chroma_frmbuf_addr_done[i];
             int_cons_luma_frmbuf_addr_done_rg[i]   <= int_cons_luma_frmbuf_addr_done[i]  ;
           end
         end

         always @ (posedge half_point_one_ms_clk)
         begin
           if (S_AXI_ARESETN == 1'b0)
           begin
	     prod_luma_buf0_cnt[i] <= {16{1'b0}};
           end
           else
           begin
             if (slv_reg3[i][C_FRMBUF_ADDR_WIDTH-32])
             begin
               prod_luma_buf0_cnt[i] <= prod_luma_buf0_cnt[i] + 1'b1;
             end
             else if (~slv_reg3[i][C_FRMBUF_ADDR_WIDTH-32])
             begin
               prod_luma_buf0_cnt[i] <= {16{1'b0}}; 
             end
           end
         end

         always @ (posedge half_point_one_ms_clk)
         begin
           if (S_AXI_ARESETN == 1'b0)
           begin
	     cons_luma_buf0_cnt[i] <= {16{1'b0}};
           end
           else
           begin
             if (slv_reg35[i][C_FRMBUF_ADDR_WIDTH-32])
             begin
               cons_luma_buf0_cnt[i] <= cons_luma_buf0_cnt[i] + 1'b1;
             end
             else if (~slv_reg35[i][C_FRMBUF_ADDR_WIDTH-32])
             begin
               cons_luma_buf0_cnt[i] <= {16{1'b0}}; 
             end
           end
         end

         always @ (posedge S_AXI_ACLK)
         begin
           if (S_AXI_ARESETN == 1'b0)
           begin
	     prod_cons_luma_buf0_cnt[i] <= {20{1'b0}};
           end
           else
           begin
             if ((int_prod_luma_frmbuf_addr_done[i]) & (prod_luma_buf_id[2*i +: 2] == 2'b00))
             begin
               prod_cons_luma_buf0_cnt[i] <= prod_cons_luma_buf0_cnt[i] + 1'b1;
             end
             else if ((int_cons_luma_frmbuf_addr_done[i]) & (cons_luma_buf_id[2*i +: 2] == 2'b00))
             begin
               prod_cons_luma_buf0_cnt[i] <= {16{1'b0}}; 
             end
           end
         end

         always @ (posedge half_point_one_ms_clk)
         begin
           if (S_AXI_ARESETN == 1'b0)
           begin
	     prod_luma_buf1_cnt[i] <= {16{1'b0}};
           end
           else
           begin
             if (slv_reg5[i][C_FRMBUF_ADDR_WIDTH-32])
             begin
               prod_luma_buf1_cnt[i] <= prod_luma_buf1_cnt[i] + 1'b1;
             end
             else if (~slv_reg5[i][C_FRMBUF_ADDR_WIDTH-32])
             begin
               prod_luma_buf1_cnt[i] <= {16{1'b0}}; 
             end
           end
         end

         always @ (posedge half_point_one_ms_clk)
         begin
           if (S_AXI_ARESETN == 1'b0)
           begin
	     cons_luma_buf1_cnt[i] <= {16{1'b0}};
           end
           else
           begin
             if (slv_reg37[i][C_FRMBUF_ADDR_WIDTH-32])
             begin
               cons_luma_buf1_cnt[i] <= cons_luma_buf1_cnt[i] + 1'b1;
             end
             else if (~slv_reg37[i][C_FRMBUF_ADDR_WIDTH-32])
             begin
               cons_luma_buf1_cnt[i] <= {16{1'b0}}; 
             end
           end
         end

         always @ (posedge S_AXI_ACLK)
         begin
           if (S_AXI_ARESETN == 1'b0)
           begin
	     prod_cons_luma_buf1_cnt[i] <= {20{1'b0}};
           end
           else
           begin
             if ((int_prod_luma_frmbuf_addr_done[i]) & (prod_luma_buf_id[2*i +: 2] == 2'b01))
             begin
               prod_cons_luma_buf1_cnt[i] <= prod_cons_luma_buf1_cnt[i] + 1'b1;
             end
             else if ((int_cons_luma_frmbuf_addr_done[i]) & (cons_luma_buf_id[2*i +: 2] == 2'b01))
             begin
               prod_cons_luma_buf1_cnt[i] <= {16{1'b0}}; 
             end
           end
         end

         always @ (posedge half_point_one_ms_clk)
         begin
           if (S_AXI_ARESETN == 1'b0)
           begin
	     prod_luma_buf2_cnt[i] <= {16{1'b0}};
           end
           else
           begin
             if (slv_reg7[i][C_FRMBUF_ADDR_WIDTH-32])
             begin
               prod_luma_buf2_cnt[i] <= prod_luma_buf2_cnt[i] + 1'b1;
             end
             else if (~slv_reg7[i][C_FRMBUF_ADDR_WIDTH-32])
             begin
               prod_luma_buf2_cnt[i] <= {16{1'b0}}; 
             end
           end
         end

         always @ (posedge half_point_one_ms_clk)
         begin
           if (S_AXI_ARESETN == 1'b0)
           begin
	     cons_luma_buf2_cnt[i] <= {16{1'b0}};
           end
           else
           begin
             if (slv_reg39[i][C_FRMBUF_ADDR_WIDTH-32])
             begin
               cons_luma_buf2_cnt[i] <= cons_luma_buf2_cnt[i] + 1'b1;
             end
             else if (~slv_reg39[i][C_FRMBUF_ADDR_WIDTH-32])
             begin
               cons_luma_buf2_cnt[i] <= {16{1'b0}};
             end
           end
         end

         always @ (posedge S_AXI_ACLK)
         begin
           if (S_AXI_ARESETN == 1'b0)
           begin
	     prod_cons_luma_buf2_cnt[i] <= {20{1'b0}};
           end
           else
           begin
             if ((int_prod_luma_frmbuf_addr_done[i]) & (prod_luma_buf_id[2*i +: 2] == 2'b10))
             begin
               prod_cons_luma_buf2_cnt[i] <= prod_cons_luma_buf2_cnt[i] + 1'b1;
             end
             else if ((int_cons_luma_frmbuf_addr_done[i]) & (cons_luma_buf_id[2*i +: 2] == 2'b10))
             begin
               prod_cons_luma_buf2_cnt[i] <= {16{1'b0}}; 
             end
           end
         end

         always @ (posedge half_point_one_ms_clk)
         begin
           if (S_AXI_ARESETN == 1'b0)
           begin
	     prod_chroma_buf0_cnt[i] <= {16{1'b0}};
           end
           else
           begin
             if (slv_reg9[i][C_FRMBUF_ADDR_WIDTH-32])
             begin
               prod_chroma_buf0_cnt[i] <= prod_chroma_buf0_cnt[i] + 1'b1;
             end
             else if (~slv_reg9[i][C_FRMBUF_ADDR_WIDTH-32])
             begin
               prod_chroma_buf0_cnt[i] <= {16{1'b0}}; 
             end
           end
         end

         always @ (posedge half_point_one_ms_clk)
         begin
           if (S_AXI_ARESETN == 1'b0)
           begin
	     cons_chroma_buf0_cnt[i] <= {16{1'b0}};
           end
           else
           begin
             if (slv_reg41[i][C_FRMBUF_ADDR_WIDTH-32])
             begin
               cons_chroma_buf0_cnt[i] <= cons_chroma_buf0_cnt[i] + 1'b1;
             end
             else if (~slv_reg41[i][C_FRMBUF_ADDR_WIDTH-32])
             begin
               cons_chroma_buf0_cnt[i] <= {16{1'b0}}; 
             end
           end
         end

         always @ (posedge S_AXI_ACLK)
         begin
           if (S_AXI_ARESETN == 1'b0)
           begin
	     prod_cons_chroma_buf0_cnt[i] <= {20{1'b0}};
           end
           else
           begin
             if ((int_prod_chroma_frmbuf_addr_done[i]) & (prod_chroma_buf_id[2*i +: 2] == 2'b00))
             begin
               prod_cons_chroma_buf0_cnt[i] <= prod_cons_chroma_buf0_cnt[i] + 1'b1;
             end
             else if ((int_cons_chroma_frmbuf_addr_done[i]) & (cons_chroma_buf_id[2*i +: 2] == 2'b00))
             begin
               prod_cons_chroma_buf0_cnt[i] <= {16{1'b0}}; 
             end
           end
         end

         always @ (posedge half_point_one_ms_clk)
         begin
           if (S_AXI_ARESETN == 1'b0)
           begin
	     prod_chroma_buf1_cnt[i] <= {16{1'b0}};
           end
           else
           begin
             if (slv_reg11[i][C_FRMBUF_ADDR_WIDTH-32])
             begin
               prod_chroma_buf1_cnt[i] <= prod_chroma_buf1_cnt[i] + 1'b1;
             end
             else if (~slv_reg11[i][C_FRMBUF_ADDR_WIDTH-32])
             begin
               prod_chroma_buf1_cnt[i] <= {16{1'b0}}; 
             end
           end
         end

         always @ (posedge half_point_one_ms_clk)
         begin
           if (S_AXI_ARESETN == 1'b0)
           begin
	     cons_chroma_buf1_cnt[i] <= {16{1'b0}};
           end
           else
           begin
             if (slv_reg43[i][C_FRMBUF_ADDR_WIDTH-32])
             begin
               cons_chroma_buf1_cnt[i] <= cons_chroma_buf1_cnt[i] + 1'b1;
             end
             else if (~slv_reg43[i][C_FRMBUF_ADDR_WIDTH-32])
             begin
               cons_chroma_buf1_cnt[i] <= {16{1'b0}}; 
             end
           end
         end

         always @ (posedge S_AXI_ACLK)
         begin
           if (S_AXI_ARESETN == 1'b0)
           begin
	     prod_cons_chroma_buf1_cnt[i] <= {20{1'b0}};
           end
           else
           begin
             if ((int_prod_chroma_frmbuf_addr_done[i]) & (prod_chroma_buf_id[2*i +: 2] == 2'b01))
             begin
               prod_cons_chroma_buf1_cnt[i] <= prod_cons_chroma_buf1_cnt[i] + 1'b1;
             end
             else if ((int_cons_chroma_frmbuf_addr_done[i]) & (cons_chroma_buf_id[2*i +: 2] == 2'b01))
             begin
               prod_cons_chroma_buf1_cnt[i] <= {16{1'b0}}; 
             end
           end
         end

         always @ (posedge half_point_one_ms_clk)
         begin
           if (S_AXI_ARESETN == 1'b0)
           begin
	     prod_chroma_buf2_cnt[i] <= {16{1'b0}};
           end
           else
           begin
             if (slv_reg13[i][C_FRMBUF_ADDR_WIDTH-32])
             begin
               prod_chroma_buf2_cnt[i] <= prod_chroma_buf2_cnt[i] + 1'b1;
             end
             else if (~slv_reg13[i][C_FRMBUF_ADDR_WIDTH-32])
             begin
               prod_chroma_buf2_cnt[i] <= {16{1'b0}}; 
             end
           end
         end

         always @ (posedge half_point_one_ms_clk)
         begin
           if (S_AXI_ARESETN == 1'b0)
           begin
	     cons_chroma_buf2_cnt[i] <= {16{1'b0}};
           end
           else
           begin
             if (slv_reg45[i][C_FRMBUF_ADDR_WIDTH-32])
             begin
               cons_chroma_buf2_cnt[i] <= cons_chroma_buf2_cnt[i] + 1'b1;
             end
             else if (~slv_reg45[i][C_FRMBUF_ADDR_WIDTH-32])
             begin
               cons_chroma_buf2_cnt[i] <= {16{1'b0}};
             end
           end
         end

         always @ (posedge S_AXI_ACLK)
         begin
           if (S_AXI_ARESETN == 1'b0)
           begin
	     prod_cons_chroma_buf2_cnt[i] <= {20{1'b0}};
           end
           else
           begin
             if ((int_prod_chroma_frmbuf_addr_done[i]) & (prod_chroma_buf_id[2*i +: 2] == 2'b10))
             begin
               prod_cons_chroma_buf2_cnt[i] <= prod_cons_chroma_buf2_cnt[i] + 1'b1;
             end
             else if ((int_cons_chroma_frmbuf_addr_done[i]) & (cons_chroma_buf_id[2*i +: 2] == 2'b10))
             begin
               prod_cons_chroma_buf2_cnt[i] <= {16{1'b0}}; 
             end
           end
         end



	 
	 always @( posedge S_AXI_ACLK)
	 //always @( posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	   begin
	      if ( S_AXI_ARESETN == 1'b0 )
		begin
		   slv_reg0[i][0] <= C_DEC_ENC_N;
		   slv_reg0[i][31:1] <= 0;
		   //	     slv_reg1[i] <= 0;
		   slv_reg2[i] <= 0;
		   slv_reg3[i] <= 0;
		   slv_reg4[i] <= 0;
		   slv_reg5[i] <= 0;
		   slv_reg6[i] <= 0;
		   slv_reg7[i] <= 0;
		   slv_reg8[i] <= 0;
		   slv_reg9[i] <= 0;
		   slv_reg10[i] <= 0;
		   slv_reg11[i] <= 0;
		   slv_reg12[i] <= 0;
		   slv_reg13[i] <= 0;
		   slv_reg14[i] <= 0;
		   slv_reg15[i] <= 0;
		   slv_reg16[i] <= 0;
		   slv_reg17[i] <= 0;
		   slv_reg18[i] <= 0;
		   slv_reg19[i] <= 0;
		   slv_reg20[i] <= 0;
		   slv_reg21[i] <= 0;
		   slv_reg22[i] <= 0;
		   slv_reg23[i] <= 0;
		   slv_reg24[i] <= 0;
		   slv_reg25[i] <= 0;
		   slv_reg26[i] <= 0;
		   slv_reg27[i] <= 0;
		   slv_reg28[i] <= 0;
		   slv_reg29[i] <= 0;
		   slv_reg30[i] <= 0;
		   slv_reg31[i] <= 0;
		   slv_reg32[i] <= 0;
		   slv_reg34[i] <= 0;
		   slv_reg35[i] <= 0;
		   slv_reg36[i] <= 0;
		   slv_reg37[i] <= 0;
		   slv_reg38[i] <= 0;
		   slv_reg39[i] <= 0;
		   slv_reg40[i] <= 0;
		   slv_reg41[i] <= 0;
		   slv_reg42[i] <= 0;
		   slv_reg43[i] <= 0;
		   slv_reg44[i] <= 0;
		   slv_reg45[i] <= 0;
		   slv_reg46[i] <= 0;
		   slv_reg47[i] <= 0;
		   slv_reg48[i] <= 0;
		   slv_reg49[i] <= 0;
		   slv_reg50[i] <= 0;
		   slv_reg51[i] <= 0;
		   slv_reg52[i] <= 0;
		   slv_reg53[i] <= 0;
		   slv_reg54[i] <= 0;
		   slv_reg55[i] <= 0;
		   slv_reg56[i] <= 0;
		   slv_reg57[i] <= 0;
		   slv_reg58[i] <= 0;
		   slv_reg59[i] <= 0;
		   slv_reg60[i] <= 0;
		end
	      else if ( S_AXI_SW_ARESET[i] == 1'b1 )
		begin
		   slv_reg0[i][0]    <= C_DEC_ENC_N;
                   slv_reg0[i][2:1]  <= {2{1'b0}};
                   slv_reg0[i][3]    <= (~(srst_cnt[i] == {3{1'b1}}));
		   slv_reg0[i][31:4] <= {29{1'b0}};
		   //	     slv_reg1[i] <= 0;
		   slv_reg2[i] <= 0;
		   slv_reg3[i] <= 0;
		   slv_reg4[i] <= 0;
		   slv_reg5[i] <= 0;
		   slv_reg6[i] <= 0;
		   slv_reg7[i] <= 0;
		   slv_reg8[i] <= 0;
		   slv_reg9[i] <= 0;
		   slv_reg10[i] <= 0;
		   slv_reg11[i] <= 0;
		   slv_reg12[i] <= 0;
		   slv_reg13[i] <= 0;
		   slv_reg14[i] <= 0;
		   slv_reg15[i] <= 0;
		   slv_reg16[i] <= 0;
		   slv_reg17[i] <= 0;
		   slv_reg18[i] <= 0;
		   slv_reg19[i] <= 0;
		   slv_reg20[i] <= 0;
		   slv_reg21[i] <= 0;
		   slv_reg22[i] <= 0;
		   slv_reg23[i] <= 0;
		   slv_reg24[i] <= 0;
		   slv_reg25[i] <= 0;
		   slv_reg26[i] <= 0;
		   slv_reg27[i] <= 0;
		   slv_reg28[i] <= 0;
		   slv_reg29[i] <= 0;
		   slv_reg30[i] <= 0;
		   slv_reg31[i] <= 0;
		   slv_reg32[i] <= 0;
		   slv_reg34[i] <= 0;
		   slv_reg35[i] <= 0;
		   slv_reg36[i] <= 0;
		   slv_reg37[i] <= 0;
		   slv_reg38[i] <= 0;
		   slv_reg39[i] <= 0;
		   slv_reg40[i] <= 0;
		   slv_reg41[i] <= 0;
		   slv_reg42[i] <= 0;
		   slv_reg43[i] <= 0;
		   slv_reg44[i] <= 0;
		   slv_reg45[i] <= 0;
		   slv_reg46[i] <= 0;
		   slv_reg47[i] <= 0;
		   slv_reg48[i] <= 0;
		   slv_reg49[i] <= 0;
		   slv_reg50[i] <= 0;
		   slv_reg51[i] <= 0;
		   slv_reg52[i] <= 0;
		   slv_reg53[i] <= 0;
		   slv_reg54[i] <= 0;
		   slv_reg55[i] <= 0;
		   slv_reg56[i] <= 0;
		   slv_reg57[i] <= 0;
		   slv_reg58[i] <= 0;
		   slv_reg59[i] <= 0;
		   slv_reg60[i] <= 0;
		end
	      else begin
                if ((prod_luma_buf_id[2*i +: 2] == 0) && (int_prod_luma_frmbuf_addr_done[i] == 1))
                  slv_reg3[i][C_FRMBUF_ADDR_WIDTH-32] <= 1'b0;
                if ((prod_luma_buf_id[2*i +: 2] == 1) && (int_prod_luma_frmbuf_addr_done[i] == 1))
                  slv_reg5[i][C_FRMBUF_ADDR_WIDTH-32] <= 1'b0;
                if ((prod_luma_buf_id[2*i +: 2] == 2) && (int_prod_luma_frmbuf_addr_done[i] == 1))
                  slv_reg7[i][C_FRMBUF_ADDR_WIDTH-32] <= 1'b0;
                
                if ((prod_chroma_buf_id[2*i +: 2] == 0) && (int_prod_chroma_frmbuf_addr_done[i] == 1))
                  slv_reg9[i][C_FRMBUF_ADDR_WIDTH-32]  <= 1'b0;
                if ((prod_chroma_buf_id[2*i +: 2] == 1) && (int_prod_chroma_frmbuf_addr_done[i] == 1))
                  slv_reg11[i][C_FRMBUF_ADDR_WIDTH-32] <= 1'b0;
                if ((prod_chroma_buf_id[2*i +: 2] == 2) && (int_prod_chroma_frmbuf_addr_done[i] == 1))
                  slv_reg13[i][C_FRMBUF_ADDR_WIDTH-32] <= 1'b0;

                //For Decoder the consumer done event is set by using the
                //Producer done event
                //if ((cons_luma_buf_id[2*i +: 2] == 0) && (int_cons_luma_frmbuf_addr_done[i] == 1))
                if (((cons_luma_buf_id[2*i +: 2] == 2'b00) && (int_cons_luma_frmbuf_addr_done[i] == 1) && (~C_DEC_ENC_N) ) |
                    ((prod_luma_buf_id[2*i +: 2] == 2'b00) && (int_prod_luma_frmbuf_addr_done[i] == 1) && (C_DEC_ENC_N)))
                  slv_reg35[i][C_FRMBUF_ADDR_WIDTH-32] <= 1'b0;
                //if ((cons_luma_buf_id[2*i +: 2] == 2'b01) && (int_cons_luma_frmbuf_addr_done[i] == 1))
                if (((cons_luma_buf_id[2*i +: 2] == 2'b01) && (int_cons_luma_frmbuf_addr_done[i] == 1) && (~C_DEC_ENC_N)) |
                    ((prod_luma_buf_id[2*i +: 2] == 2'b01) && (int_prod_luma_frmbuf_addr_done[i] == 1) && (C_DEC_ENC_N)))
                  slv_reg37[i][C_FRMBUF_ADDR_WIDTH-32] <= 1'b0;
                //if ((cons_luma_buf_id[2*i +: 2] == 2'b10) && (int_cons_luma_frmbuf_addr_done[i] == 1))
                if (((cons_luma_buf_id[2*i +: 2] == 2'b10) && (int_cons_luma_frmbuf_addr_done[i] == 1) && (~C_DEC_ENC_N)) |
                    ((prod_luma_buf_id[2*i +: 2] == 2'b10) && (int_prod_luma_frmbuf_addr_done[i] == 1) && (C_DEC_ENC_N)))
                  slv_reg39[i][C_FRMBUF_ADDR_WIDTH-32] <= 1'b0;
                
                //if ((cons_chroma_buf_id[2*i +: 2] == 2'b00) && (int_cons_chroma_frmbuf_addr_done[i] == 1))
                if (((cons_chroma_buf_id[2*i +: 2] == 2'b00) && (int_cons_chroma_frmbuf_addr_done[i] == 1) && (~C_DEC_ENC_N)) |
                    ((prod_chroma_buf_id[2*i +: 2] == 2'b00) && (int_prod_chroma_frmbuf_addr_done[i] == 1) && (C_DEC_ENC_N)))
                  slv_reg41[i][C_FRMBUF_ADDR_WIDTH-32]  <= 1'b0;
                //if ((cons_chroma_buf_id[2*i +: 2] == 2'b01) && (int_cons_chroma_frmbuf_addr_done[i] == 1))
                if (((cons_chroma_buf_id[2*i +: 2] == 2'b01) && (int_cons_chroma_frmbuf_addr_done[i] == 1) && (~C_DEC_ENC_N)) |
                    ((prod_chroma_buf_id[2*i +: 2] == 2'b01) && (int_prod_chroma_frmbuf_addr_done[i] == 1) && (C_DEC_ENC_N)))
                  slv_reg43[i][C_FRMBUF_ADDR_WIDTH-32] <= 1'b0;
                //if ((cons_chroma_buf_id[2*i +: 2] == 2'b10) && (int_cons_chroma_frmbuf_addr_done[i] == 1))
                if (((cons_chroma_buf_id[2*i +: 2] == 2'b10) && (int_cons_chroma_frmbuf_addr_done[i] == 1) && (~C_DEC_ENC_N)) |
                    ((prod_chroma_buf_id[2*i +: 2] == 2'b10) && (int_prod_chroma_frmbuf_addr_done[i] == 1) && (C_DEC_ENC_N)))
                  slv_reg45[i][C_FRMBUF_ADDR_WIDTH-32] <= 1'b0;
		 if (slv_reg_wren & chan_awaddr_valid & (chan_awaddr == i) & (axi_awaddr[11:8] < 4'h4))
		   begin
	              case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
			6'h00://0x00 //ctrl reg
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 2
			       if (byte_index == 0)
					   begin
				 slv_reg0[i][1 +: 4] <= S_AXI_WDATA[1 +: 4];
				 slv_reg0[i][5 +: 3] <= {3{1'b0}};
			       end
			       //else
			       //begin
			       //  slv_reg0[i][(byte_index*8)+1 +: 7] <= S_AXI_WDATA[(byte_index*8)+1 +: 7];
			       //end
			    end  
			//	          6'h01://0x04 //ISR
			//	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			//	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
			//	                 // Respective byte enables are asserted as per write strobes 
			//	                 // Slave register 1
			//	                 slv_reg1[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			//	              end  
			6'h02://0x08 //PLB0SAL
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 2
	                       slv_reg2[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			    end  
			6'h03: begin //0x0C //PLB0SAH
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 ) 
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
			       // Respective byte enables are asserted as per write strobes 
			       // Slave register 3
			       //slv_reg3[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
		               if (byte_index == 0) 
			       begin
	                         slv_reg3[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			       end
			       else if (byte_index == 1)
			       begin
			         slv_reg3[i][13:8] <= S_AXI_WDATA[(byte_index*8) +: 5];
				 slv_reg3[i][15:14] <= {3{1'b0}};
			       end
			       else
			       begin
			         slv_reg3[i][(byte_index*8) +: 8] <= {8{1'b0}};
			       end
			    end
			   //if ( cons_luma_buf_id[2*i +: 2] == 0 && int_cons_luma_frmbuf_addr_done[i] == 1) // clear valid bit
			   //  slv_reg3[i][C_FRMBUF_ADDR_WIDTH-32] = 1'b0;
			  end
			6'h04://0x10//PLB1SAL
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 4
	                       slv_reg4[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			    end  
			6'h05: begin//0x14 //PLB1SAH
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 5
	                       //slv_reg5[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			       if (byte_index == 0) 
			       begin
	                         slv_reg5[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			       end
			       else if (byte_index == 1)
			       begin
			         slv_reg5[i][13:8] <= S_AXI_WDATA[(byte_index*8) +: 5];
				 slv_reg5[i][15:14] <= {3{1'b0}};
			       end
			       else
			       begin
			         slv_reg5[i][(byte_index*8) +: 8] <= {8{1'b0}};
			       end
			    end  
			   //if ( cons_luma_buf_id[2*i +: 2] == 1 && int_cons_luma_frmbuf_addr_done[i] == 1) // clear valid bit
			   //  slv_reg5[i][C_FRMBUF_ADDR_WIDTH-32] = 1'b0;
			  end
			6'h06://0x18 //PLB2SAL
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 6
	                       slv_reg6[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			    end  
			6'h07: begin//0x1C //PLB2SAH
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 7
	                       //slv_reg7[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
       		               if (byte_index == 0) 
			       begin
	                         slv_reg7[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			       end
			       else if (byte_index == 1)
			       begin
			         slv_reg7[i][13:8] <= S_AXI_WDATA[(byte_index*8) +: 5];
				 slv_reg7[i][15:14] <= {3{1'b0}};
			       end
			       else
			       begin
			         slv_reg7[i][(byte_index*8) +: 8] <= {8{1'b0}};
			       end
			    end  
			   //if ( cons_luma_buf_id[2*i +: 2] == 2 && int_cons_luma_frmbuf_addr_done[i] == 1) // clear valid bit
			   // slv_reg7[i][C_FRMBUF_ADDR_WIDTH-32] = 1'b0;
			end
			6'h08://0x20 //PCB0SAL
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 8
	                       slv_reg8[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			    end  
			6'h09: begin//0x24 //PCB0SAH
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 9
	                       //slv_reg9[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                               if (byte_index == 0) 
			       begin
	                         slv_reg9[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			       end
			       else if (byte_index == 1)
			       begin
			         slv_reg9[i][13:8] <= S_AXI_WDATA[(byte_index*8) +: 5];
				 slv_reg9[i][15:14] <= {3{1'b0}};
			       end
			       else
			       begin
			         slv_reg9[i][(byte_index*8) +: 8] <= {8{1'b0}};
			       end
			    end  
			   //if ( cons_chroma_buf_id[2*i +: 2] == 0 && int_cons_chroma_frmbuf_addr_done[i] == 1) // clear valid bit
			   //  slv_reg9[i][C_FRMBUF_ADDR_WIDTH-32] = 1'b0;
			end
			6'h0A://0x28//PCB1SAL
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 10
	                       slv_reg10[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			    end  
			6'h0B: begin //0x2C //PCB1SAH
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 11
	                       //slv_reg11[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
		               if (byte_index == 0) 
			       begin
	                         slv_reg11[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			       end
			       else if (byte_index == 1)
			       begin
			         slv_reg11[i][13:8] <= S_AXI_WDATA[(byte_index*8) +: 5];
				 slv_reg11[i][15:14] <= {3{1'b0}};
			       end
			       else
			       begin
			         slv_reg11[i][(byte_index*8) +: 8] <= {8{1'b0}};
			       end
			    end
			   //if ( cons_chroma_buf_id[2*i +: 2] == 1 && int_cons_chroma_frmbuf_addr_done[i] == 1) // clear valid bit
			   //  slv_reg11[i][C_FRMBUF_ADDR_WIDTH-32] = 1'b0;
			end
			6'h0C://0x30 //PCB2SAL
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 12
	                       slv_reg12[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			    end  
			6'h0D: begin//0x34 //PCB2SAH
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 13
	                       //slv_reg13[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
		               if (byte_index == 0) 
			       begin
	                         slv_reg13[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			       end
			       else if (byte_index == 1)
			       begin
			         slv_reg13[i][13:8] <= S_AXI_WDATA[(byte_index*8) +: 5];
				 slv_reg13[i][15:14] <= {3{1'b0}};
			       end
			       else
			       begin
			         slv_reg13[i][(byte_index*8) +: 8] <= {8{1'b0}};
			       end
			    end  
			   //if ( cons_chroma_buf_id[2*i +: 2] == 2 && int_cons_chroma_frmbuf_addr_done[i] == 1) // clear valid bit
			   //  slv_reg13[i][C_FRMBUF_ADDR_WIDTH-32] = 1'b0;
			end
			6'h0E://0x38//PLB0EAL
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 14
	                       slv_reg14[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			    end  
			6'h0F://0x3C //PLB0EAH
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 15
	                       //slv_reg15[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
		             if (byte_index == 0) 
			       begin
	                         slv_reg15[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			       end
			       else if (byte_index == 1)
			       begin
			         slv_reg15[i][12:8] <= S_AXI_WDATA[(byte_index*8) +: 4];
				 slv_reg15[i][15:13] <= {4{1'b0}};
			       end
			       else
			       begin
			         slv_reg15[i][(byte_index*8) +: 8] <= {8{1'b0}};
			       end
			    end  
			6'h10://0x40 //PLB1EAL
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 16
	                       slv_reg16[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			    end  
			6'h11:  //0x44 //PLB1EAH
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 17
	                       //slv_reg17[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
		             if (byte_index == 0) 
			       begin
	                         slv_reg17[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			       end
			       else if (byte_index == 1)
			       begin
			         slv_reg17[i][12:8] <= S_AXI_WDATA[(byte_index*8) +: 4];
				 slv_reg17[i][15:13] <= {4{1'b0}};
			       end
			       else
			       begin
			         slv_reg17[i][(byte_index*8) +: 8] <= {8{1'b0}};
			       end
			    end  
			6'h12: //0x48 //PLB2EAL
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 18
	                       slv_reg18[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			    end  
			6'h13: //0x4C //PLB2EAH
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 19
	                       //slv_reg19[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
		             if (byte_index == 0) 
			       begin
	                         slv_reg19[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			       end
			       else if (byte_index == 1)
			       begin
			         slv_reg19[i][12:8] <= S_AXI_WDATA[(byte_index*8) +: 4];
				 slv_reg19[i][15:13] <= {4{1'b0}};
			       end
			       else
			       begin
			         slv_reg19[i][(byte_index*8) +: 8] <= {8{1'b0}};
			       end
			    end
			6'h14: //0x50 //PCB0EAL
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 20
	                       slv_reg20[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			    end  
			6'h15: //0x54 //PCB0EAH
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 21
	                       //slv_reg21[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
		               if (byte_index == 0) 
			       begin
	                         slv_reg21[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			       end
			       else if (byte_index == 1)
			       begin
			         slv_reg21[i][11:8] <= S_AXI_WDATA[(byte_index*8) +: 5];
				 slv_reg21[i][15:12] <= {3{1'b0}};
			       end
			       else
			       begin
			         slv_reg21[i][(byte_index*8) +: 8] <= {8{1'b0}};
			       end

			    end  
			6'h16: //0x58 //PCB1EAL
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 22
	                      slv_reg22[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			    end  
			6'h17: //0x5C //PCB1EAH
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 23
	                       //slv_reg23[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			       if (byte_index == 0) 
			       begin
	                         slv_reg23[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			       end
			       else if (byte_index == 1)
			       begin
			         slv_reg23[i][11:8] <= S_AXI_WDATA[(byte_index*8) +: 5];
				 slv_reg23[i][15:12] <= {3{1'b0}};
			       end
			       else
			       begin
			         slv_reg23[i][(byte_index*8) +: 8] <= {8{1'b0}};
			       end

			    end  
			6'h18: //0x60 //PCB2EAL
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 24
	                       slv_reg24[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			    end  
			6'h19: //0x64 //PCB2EAH
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 25
	                       //slv_reg25[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
		               if (byte_index == 0) 
			       begin
	                         slv_reg25[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			       end
			       else if (byte_index == 1)
			       begin
			         slv_reg25[i][11:8] <= S_AXI_WDATA[(byte_index*8) +: 5];
				 slv_reg25[i][15:12] <= {3{1'b0}};
			       end
			       else
			       begin
			         slv_reg25[i][(byte_index*8) +: 8] <= {8{1'b0}};
			       end
			    end  
			6'h1A: //0x68 //PLB0M
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 26
	                       slv_reg26[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			    end  
			6'h1B: //0x6C //PLB1M
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 27
	                       slv_reg27[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			    end  
			6'h1C: //0x70 //PLB2M
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 28
	                       slv_reg28[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			    end  
			6'h1D: //0x74 //PCB0M
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 29
	                       slv_reg29[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			    end  
			6'h1E: //0x78 //PCB1M
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 30
	                       slv_reg30[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			    end  
			6'h1F: //0x7C //PCB2M
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 31
	                       slv_reg31[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			    end
			6'h20: //0x80 //IMR
			  for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
			    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
	                       // Slave register 31
	                       //slv_reg32[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
		               if (byte_index == 0) 
			       begin
	                         slv_reg32[i][(byte_index*8) +: 2] <= S_AXI_WDATA[(byte_index*8) +: 2];
                                 slv_reg32[i][4:2]                 <= {3{1'b0}};
                                 slv_reg32[i][7:6]                 <= {2{1'b0}};
				 slv_reg32[i][5]                   <= S_AXI_WDATA[((byte_index*8)+5) +: 1];
			       end
			       else if (byte_index == 1)
			       begin
			         slv_reg32[i][9]     <= S_AXI_WDATA[((byte_index*8)+1) +: 1];
			         slv_reg32[i][13]    <= S_AXI_WDATA[((byte_index*8)+5) +: 1];
				 slv_reg32[i][8]     <= {1{1'b0}};
				 slv_reg32[i][12:10] <= {3{1'b0}};
                                 slv_reg32[i][15:14] <= {2{1'b0}};
			       end
                               else if (byte_index == 2)
                               begin
                                 slv_reg32[i][21:17] <= S_AXI_WDATA[((byte_index*8)+2) +: 5];
                                 slv_reg32[i][16]    <= {1{1'b0}};
                                 slv_reg32[i][23:22] <= {2{1'b0}};
                               end
			       else
			       begin
			         slv_reg32[i][(byte_index*8) +: 8] <= {8{1'b0}};
			       end
			    end
                         6'h22://0x88 //CLB0SAL
                           for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                             if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                       // Respective byte enables are asserted as per write strobes 
                               // Slave register 34
	                       slv_reg34[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			    end 
                        6'h23: //0x8C //CLB0SAH
			  begin
                            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 ) 
                              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                               // Respective byte enables are asserted as per write strobes 
                               // Slave register 35
                               //slv_reg35[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                               if (byte_index == 0) 
                               begin
                                 slv_reg35[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                               end
                               else if (byte_index == 1)
                               begin
                                 slv_reg35[i][13:8] <= S_AXI_WDATA[(byte_index*8) +: 5];
                                 slv_reg35[i][15:14] <= {3{1'b0}};
                               end
                               else
                               begin
                                 slv_reg35[i][(byte_index*8) +: 8] <= {8{1'b0}};
                               end
                             end
                             //if ( cons_luma_buf_id[2*i +: 2] == 0 && int_cons_luma_frmbuf_addr_done[i] == 1) // clear valid bit
                             //  slv_reg35[i][C_FRMBUF_ADDR_WIDTH-32] = 1'b0;
                           end
                         6'h24: //0x8C //CLB0SAH
                           for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                             if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                               // Respective byte enables are asserted as per write strobes 
                               // Slave register36
                               slv_reg36[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                             end  
                   	 6'h25: //0x90 //CLB1SAL
			   begin
                   	     for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                   	       if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                 // Respective byte enables are asserted as per write strobes 
                                 // Slave register37
                                 //slv_reg37[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                 if (byte_index == 0) 
                                 begin
                                   slv_reg37[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                 end
                                 else if (byte_index == 1)
                                 begin
                                   slv_reg37[i][13:8] <= S_AXI_WDATA[(byte_index*8) +: 5];
                   	           slv_reg37[i][15:14] <= {3{1'b0}};
                   	         end
                   	         else
                   	         begin
                   	           slv_reg37[i][(byte_index*8) +: 8] <= {8{1'b0}};
                   	         end
                               end  
                               //if ( cons_luma_buf_id[2*i +: 2] == 1 && int_cons_luma_frmbuf_addr_done[i] == 1) // clear valid bit
                               //  slv_reg37[i][C_FRMBUF_ADDR_WIDTH-32] = 1'b0;
                           end
                         6'h26: //0x94 //CLB1SAH
                           for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                             if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                               // Respective byte enables are asserted as per write strobes 
                               // Slave register38
                               slv_reg38[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                             end  
                         6'h27: begin //0x98 //CLB2SAL
                           for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                             if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                               // Respective byte enables are asserted as per write strobes 
                               // Slave register39
                               //slv_reg39[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                               if (byte_index == 0) 
                               begin
                                 slv_reg39[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                               end
                               else if (byte_index == 1)
                               begin
                                 slv_reg39[i][13:8] <= S_AXI_WDATA[(byte_index*8) +: 5];
                                 slv_reg39[i][15:14] <= {3{1'b0}};
                               end
                               else
                               begin
                                 slv_reg39[i][(byte_index*8) +: 8] <= {8{1'b0}};
                               end
                             end  
                             //if ( cons_luma_buf_id[2*i +: 2] == 2 && int_cons_luma_frmbuf_addr_done[i] == 1) // clear valid bit
                             //  slv_reg39[i][C_FRMBUF_ADDR_WIDTH-32] = 1'b0;
                           end
                         6'h28: //0x9C //CLB2SAH
                           for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                             if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                               // Respective byte enables are asserted as per write strobes 
                               // Slave register40
                               slv_reg40[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                             end  
                         6'h29: //0xA0 //CCB0SAL
                           begin
                             for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                               if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                 // Respective byte enables are asserted as per write strobes 
                                 // Slave register41
                                 // slv_reg41[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                 if (byte_index == 0) 
                                 begin
                                   slv_reg41[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                 end
                                 else if (byte_index == 1)
                                 begin
                                   slv_reg41[i][13:8] <= S_AXI_WDATA[(byte_index*8) +: 5];
                                   slv_reg41[i][15:14] <= {3{1'b0}};
                                 end
                                 else
                                 begin
                                   slv_reg41[i][(byte_index*8) +: 8] <= {8{1'b0}};
                                 end
                               end  
                               //if ( cons_chroma_buf_id[2*i +: 2] == 0 && int_cons_chroma_frmbuf_addr_done[i] == 1) // clear valid bit
                               //  slv_reg41[i][C_FRMBUF_ADDR_WIDTH-32] = 1'b0;
                             end
                         6'h2A: //0xA4 //CCB0SAH
                           for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                             if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                               // Respective byte enables are asserted as per write strobes 
                               // Slave register42
                               slv_reg42[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                             end  
                         6'h2B: //0xA8 //CCB1SAL
                           begin
                             for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                               if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                 //Respective byte enables are asserted as per write strobes 
                                 //Slave register43
                                 //slv_reg43[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                 if (byte_index == 0) 
                                 begin
                                   slv_reg43[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                 end
                                 else if (byte_index == 1)
                                 begin
                                   slv_reg43[i][13:8] <= S_AXI_WDATA[(byte_index*8) +: 5];
                                   slv_reg43[i][15:14] <= {3{1'b0}};
                                 end
                                 else
                                 begin
                                   slv_reg43[i][(byte_index*8) +: 8] <= {8{1'b0}};
                                 end
                               end
                               //if ( cons_chroma_buf_id[2*i +: 2] == 1 && int_cons_chroma_frmbuf_addr_done[i] == 1) // clear valid bit
                               //  slv_reg43[i][C_FRMBUF_ADDR_WIDTH-32] = 1'b0;
                           end
                         6'h2C: //0xAC //CCB1SAH
                           for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                             if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                               // Respective byte enables are asserted as per write strobes 
                               // Slave register44
                               slv_reg44[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                             end  
                         6'h2D: //0xB0 //CCB2SAL
                           begin
                             for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                               if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                 // Respective byte enables are asserted as per write strobes 
                                 // Slave register45
                                 // slv_reg45[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                 if (byte_index == 0) 
                                 begin
                                   slv_reg45[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                                 end
                                 else if (byte_index == 1)
                                 begin
                                   slv_reg45[i][13:8] <= S_AXI_WDATA[(byte_index*8) +: 5];
                                   slv_reg45[i][15:14] <= {3{1'b0}};
                                 end
                                 else
                                 begin
                                   slv_reg45[i][(byte_index*8) +: 8] <= {8{1'b0}};
                                 end
                               end  
                               //if ( cons_chroma_buf_id[2*i +: 2] == 2 && int_cons_chroma_frmbuf_addr_done[i] == 1) // clear valid bit
                               //  slv_reg45[i][C_FRMBUF_ADDR_WIDTH-32] = 1'b0;
                           end
                         6'h2E: //0xB4
                           for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                             if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                               // Respective byte enables are asserted as per write strobes 
                               // Slave register46
                               slv_reg46[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                             end  
                         6'h2F: //0xB8
                           for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                             if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                               // Respective byte enables are asserted as per write strobes 
                               // Slave register47
                               // slv_reg47[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                               if (byte_index == 0) 
                               begin
                                 slv_reg47[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                               end
                               else if (byte_index == 1)
                               begin
                                 slv_reg47[i][12:8] <= S_AXI_WDATA[(byte_index*8) +: 4];
                                 slv_reg47[i][15:13] <= {4{1'b0}};
                               end
                               else
                               begin
                                 slv_reg47[i][(byte_index*8) +: 8] <= {8{1'b0}};
                               end
                             end  
                         6'h30: //0xBC
                           for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                             if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                               // Respective byte enables are asserted as per write strobes 
                               // Slave register48
                               slv_reg48[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                             end  
                         6'h31: //0xC0
                           for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                             if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                               // Respective byte enables are asserted as per write strobes 
                               // Slave register49
                               // slv_reg49[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                               if (byte_index == 0) 
                               begin
                                 slv_reg49[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                               end
                               else if (byte_index == 1)
                               begin
                                 slv_reg49[i][12:8] <= S_AXI_WDATA[(byte_index*8) +: 4];
                                 slv_reg49[i][15:13] <= {4{1'b0}};
                               end
                               else
                               begin
                                 slv_reg49[i][(byte_index*8) +: 8] <= {8{1'b0}};
                               end
                             end  
                         6'h32: //0xC4
                           for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                             if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                               // Respective byte enables are asserted as per write strobes 
                               // Slave register50
                               slv_reg50[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                             end  
                         6'h33: //0xC8
                           for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                             if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                               // Respective byte enables are asserted as per write strobes 
                               // Slave register51
                               // slv_reg51[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                               if (byte_index == 0) 
                               begin
                                 slv_reg51[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                               end
                               else if (byte_index == 1)
                               begin
                                 slv_reg51[i][12:8] <= S_AXI_WDATA[(byte_index*8) +: 4];
                                 slv_reg51[i][15:13] <= {4{1'b0}};
                               end
                               else
                               begin
                                 slv_reg51[i][(byte_index*8) +: 8] <= {8{1'b0}};
                               end
                             end
                         6'h34: //0xCC
                           for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                             if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                               // Respective byte enables are asserted as per write strobes 
                               // Slave register52
                               slv_reg52[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                             end  
                         6'h35: //0xD0
                           for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                             if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                               // Respective byte enables are asserted as per write strobes 
                               // Slave register 53
                               // slv_reg53[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                               if (byte_index == 0) 
                               begin
                                 slv_reg53[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                               end
                               else if (byte_index == 1)
                               begin
                                 slv_reg53[i][11:8] <= S_AXI_WDATA[(byte_index*8) +: 5];
                                 slv_reg53[i][15:12] <= {3{1'b0}};
                               end
                               else
                               begin
                                 slv_reg53[i][(byte_index*8) +: 8] <= {8{1'b0}};
                               end
                             end  
                         6'h36: //0xD4
                           for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                             if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                               // Respective byte enables are asserted as per write strobes 
                               // Slave register 54
                               slv_reg54[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                             end  
                         6'h37: //0xD8
                           for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                             if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                               // Respective byte enables are asserted as per write strobes 
                               // Slave register 55
                               // slv_reg55[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                               if (byte_index == 0) 
                               begin
                                 slv_reg55[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                               end
                               else if (byte_index == 1)
                               begin
                                 slv_reg55[i][11:8] <= S_AXI_WDATA[(byte_index*8) +: 5];
                                 slv_reg55[i][15:12] <= {3{1'b0}};
                               end
                               else
                               begin
                                 slv_reg55[i][(byte_index*8) +: 8] <= {8{1'b0}};
                               end
                            end  
                         6'h38: //0xDC
                           for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                             if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                               // Respective byte enables are asserted as per write strobes 
                               // Slave register 56
                               slv_reg56[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                             end  
                         6'h39: //0xE0
                           for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                             if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                               // Respective byte enables are asserted as per write strobes 
                               // Slave register 57
                               // slv_reg57[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                               if (byte_index == 0) 
                               begin
                                 slv_reg57[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                               end
                               else if (byte_index == 1)
                               begin
                                 slv_reg57[i][11:8] <= S_AXI_WDATA[(byte_index*8) +: 5];
                                 slv_reg57[i][15:12] <= {3{1'b0}};
                               end
                               else
                               begin
                                 slv_reg57[i][(byte_index*8) +: 8] <= {8{1'b0}};
                               end
                            end  
                         6'h3A: //0xE4//####
                           for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                             if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                               // Respective byte enables are asserted as per write strobes 
                               // Slave register 58
                               slv_reg58[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                             end
                         6'h3B: //0xE8//####
                           for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                             if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                               // Respective byte enables are asserted as per write strobes 
                               // Slave register 59
                               slv_reg59[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			     end
                         6'h3C: //0xEC//####
                           for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                             if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                               // Respective byte enables are asserted as per write strobes 
                               // Slave register 60
                               slv_reg60[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			     end
                      endcase // case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
                   end // if (slv_reg_wren & chan_awaddr_valid)
                end // else: !if( S_AXI_ARESETN == 1'b0 )
             end // always @ ( posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
          end // block: gen_chan_0
   endgenerate

   //#### COnsumer specific registor
   always @ ( posedge S_AXI_ACLK)
   //always @ ( posedge S_AXI_ACLK or negedge S_AXI_ARESETN )
   //always @ ( posedge S_AXI_ACLK or negedge S_AXI_ARESET )
   //always @ ( posedge S_AXI_ACLK or negedge rst )
   begin//{
      if (S_AXI_ARESETN == 1'b0)
     //if ((S_AXI_ARESETN == 1'b0)|(S_AXI_SW_ARESET == 1'b1))
     //if (S_AXI_ARESET == 1'b0)
     //if (rst == 1'b0)
     begin//{
       cons_slv_reg0  <= {32{1'b0}};
       cons_slv_reg1  <= {32{1'b0}};
       cons_slv_reg2  <= {32{1'b0}};
       cons_slv_reg3  <= {32{1'b0}};
       cons_slv_reg4  <= {32{1'b0}};
       cons_slv_reg5  <= {32{1'b0}};
       cons_slv_reg6  <= {32{1'b0}};
       cons_slv_reg7  <= {32{1'b0}};
       cons_slv_reg8  <= {32{1'b0}};
       cons_slv_reg9  <= {32{1'b0}};
     end//}
     else
     begin//{
       if (slv_reg_wren)
       begin//{
         case ( axi_awaddr[ADDR_LSB+CONS_REG_ADDR_BITS:ADDR_LSB] )//{
           9'h100: //0x400
             for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
               if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                  // Respective byte enables are asserted as per write strobes 
                  // Slave register 34
                  cons_slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
               end
           9'h101: //0x404
             for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
               if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                  // Respective byte enables are asserted as per write strobes 
                  // Slave register 35
                  cons_slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
               end
           9'h102: //0x408
             for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
               if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                  // Respective byte enables are asserted as per write strobes 
                  // Slave register 36
                  cons_slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
               end
           9'h103: //0x40C
             for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
               if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                  // Respective byte enables are asserted as per write strobes 
                  // Slave register 37
                  cons_slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
               end
           9'h104: //0x410
             for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
               if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                  // Respective byte enables are asserted as per write strobes 
                  // Slave register 38
                  cons_slv_reg4[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
               end
           9'h105: //0x414
             for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
               if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                  // Respective byte enables are asserted as per write strobes 
                  // Slave register 39
                  cons_slv_reg5[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
               end
           9'h106: //0x418
             for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
               if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                  // Respective byte enables are asserted as per write strobes 
                  // Slave register 40
                  cons_slv_reg6[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
               end
           9'h107: //0x41C
             for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
               if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                  // Respective byte enables are asserted as per write strobes 
                  // Slave register 41
                  cons_slv_reg7[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
               end
           9'h108: //0x420 //####
             for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
               if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                  // Respective byte enables are asserted as per write strobes 
                  // Slave register 42
                  cons_slv_reg8[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
               end
           9'h109: //0x424 //####
             for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
               if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                  // Respective byte enables are asserted as per write strobes 
                  // Slave register 43
                  cons_slv_reg9[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
               end
	 endcase//}
       end//}
       if (S_AXI_SW_ARESET[0] == 1'b1)
       begin
         cons_slv_reg0 <= {32{1'b0}};
         cons_slv_reg4 <= {32{1'b0}};
       end
       if (S_AXI_SW_ARESET[1] == 1'b1)
       begin
         cons_slv_reg1 <= {32{1'b0}};
         cons_slv_reg5 <= {32{1'b0}};
       end
       if (S_AXI_SW_ARESET[2] == 1'b1)
       begin
         cons_slv_reg2 <= {32{1'b0}};
         cons_slv_reg6 <= {32{1'b0}};
       end
       if (S_AXI_SW_ARESET[3] == 1'b1)
       begin
         cons_slv_reg3 <= {32{1'b0}};
         cons_slv_reg7 <= {32{1'b0}};
       end
       if ((|S_AXI_SW_ARESET) == 1'b1)
       begin
         cons_slv_reg8 <= {32{1'b0}};
         cons_slv_reg9 <= {32{1'b0}};
       end
     end//}
   end//}
 

   // Implement write response logic generation
   // The write response and response valid signals are asserted by the slave 
   // when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
   // This marks the acceptance of address and indicates the status of 
   // write transaction.
   always @( posedge S_AXI_ACLK )
     begin
	if ( S_AXI_ARESETN == 1'b0 )
	//if ( S_AXI_ARESET == 1'b0 )
	//if ( rst == 1'b0 )
	  begin
	     axi_bvalid  <= 0;
	     axi_bresp   <= 2'b0;
	  end 
	else
	  begin    
	     if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	       begin
	          // indicates a valid write response is available
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response 
	       end                   // work error responses in future
	     else
	       begin
	          if (S_AXI_BREADY && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
	               axi_bvalid <= 1'b0; 
	            end  
	       end
	  end
     end   

   // Implement axi_arready generation
   // axi_arready is asserted for one S_AXI_ACLK clock cycle when
   // S_AXI_ARVALID is asserted. axi_awready is 
   // de-asserted when reset (active low) is asserted. 
   // The read address is also latched when S_AXI_ARVALID is 
   // asserted. axi_araddr is reset to zero on reset assertion.

   always @( posedge S_AXI_ACLK)
   //always @( posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
   //always @( posedge S_AXI_ACLK or negedge S_AXI_ARESET)
   //always @( posedge S_AXI_ACLK or negedge rst)
     begin
	if ( S_AXI_ARESETN == 1'b0 )
	//if ( S_AXI_ARESET == 1'b0 )
	//if ( rst == 1'b0 )
	  begin
	     axi_arready <= 1'b0;
	     chan_araddr_valid <= 1'b0;
	  end 
	else
	  begin    
	     if (~axi_arready && S_AXI_ARVALID)
	       begin
	          // indicates that the slave has acceped the valid read address
	          axi_arready <= 1'b1;
	          // Read address latching
		  chan_araddr_valid <= 1'b1;
	       end
	     else
	       begin
	          axi_arready <= 1'b0;
	       end
	  end 
     end       

   always @( posedge S_AXI_ACLK )
     begin
	if (~axi_arready && S_AXI_ARVALID)
	  begin
	     // Read address latching
	     axi_araddr  <= S_AXI_ARADDR;
	     chan_araddr  <= S_AXI_ARADDR[CHAN_ADDR_LSB +: 2];
	  end
     end       
   
   // Implement axi_arvalid generation
   // axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
   // S_AXI_ARVALID and axi_arready are asserted. The slave registers 
   // data are available on the axi_rdata bus at this instance. The 
   // assertion of axi_rvalid marks the validity of read data on the 
   // bus and axi_rresp indicates the status of read transaction.axi_rvalid 
   // is deasserted on reset (active low). axi_rresp and axi_rdata are 
   // cleared to zero on reset (active low).  
   always @( posedge S_AXI_ACLK )
     begin
	if ( S_AXI_ARESETN == 1'b0 )
	//if ( S_AXI_ARESET == 1'b0 )
	//if ( rst == 1'b0 )
	  begin
	     axi_rvalid <= 0;
	     axi_rresp  <= 0;
	  end 
	else
	  begin    
	     if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	       begin
	          // Valid read data is available at the read data bus
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; // 'OKAY' response
	       end   
	     else if (axi_rvalid && S_AXI_RREADY)
	       begin
	          // Read data is accepted by the master
	          axi_rvalid <= 1'b0;
	       end                
	  end
     end    

   // Implement memory mapped register select and read logic generation
   // Slave register read enable is asserted when valid address is available
   // and the slave is ready to accept the read address.
   assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
   always @(*)
   begin
	// Address decoding for reading registers
     if (axi_araddr[11:8] < 4'd4)
     begin
       case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
         6'h00   : reg_data_out <= slv_reg0[chan_araddr];
         6'h01   : reg_data_out <= slv_reg1[chan_araddr];
         6'h02   : reg_data_out <= slv_reg2[chan_araddr];
         6'h03   : reg_data_out <= slv_reg3[chan_araddr];
         6'h04   : reg_data_out <= slv_reg4[chan_araddr];
         6'h05   : reg_data_out <= slv_reg5[chan_araddr];
         6'h06   : reg_data_out <= slv_reg6[chan_araddr];
         6'h07   : reg_data_out <= slv_reg7[chan_araddr];
         6'h08   : reg_data_out <= slv_reg8[chan_araddr];
         6'h09   : reg_data_out <= slv_reg9[chan_araddr];
         6'h0A   : reg_data_out <= slv_reg10[chan_araddr];
         6'h0B   : reg_data_out <= slv_reg11[chan_araddr];
         6'h0C   : reg_data_out <= slv_reg12[chan_araddr];
         6'h0D   : reg_data_out <= slv_reg13[chan_araddr];
         6'h0E   : reg_data_out <= slv_reg14[chan_araddr];
         6'h0F   : reg_data_out <= slv_reg15[chan_araddr];
         6'h10   : reg_data_out <= slv_reg16[chan_araddr];
         6'h11   : reg_data_out <= slv_reg17[chan_araddr];
         6'h12   : reg_data_out <= slv_reg18[chan_araddr];
         6'h13   : reg_data_out <= slv_reg19[chan_araddr];
         6'h14   : reg_data_out <= slv_reg20[chan_araddr];
         6'h15   : reg_data_out <= slv_reg21[chan_araddr];
         6'h16   : reg_data_out <= slv_reg22[chan_araddr];
         6'h17   : reg_data_out <= slv_reg23[chan_araddr];
         6'h18   : reg_data_out <= slv_reg24[chan_araddr];
         6'h19   : reg_data_out <= slv_reg25[chan_araddr];
         6'h1A   : reg_data_out <= slv_reg26[chan_araddr];
         6'h1B   : reg_data_out <= slv_reg27[chan_araddr];
         6'h1C   : reg_data_out <= slv_reg28[chan_araddr];
         6'h1D   : reg_data_out <= slv_reg29[chan_araddr];
         6'h1E   : reg_data_out <= slv_reg30[chan_araddr];
         6'h1F   : reg_data_out <= slv_reg31[chan_araddr];
         6'h20   : reg_data_out <= slv_reg32[chan_araddr];
         6'h21   : reg_data_out <= slv_reg33[chan_araddr];
         6'h22   : reg_data_out <= slv_reg34[chan_araddr];
         6'h23   : reg_data_out <= slv_reg35[chan_araddr];
         6'h24   : reg_data_out <= slv_reg36[chan_araddr];
         6'h25   : reg_data_out <= slv_reg37[chan_araddr];
         6'h26   : reg_data_out <= slv_reg38[chan_araddr];
         6'h27   : reg_data_out <= slv_reg39[chan_araddr];
         6'h28   : reg_data_out <= slv_reg40[chan_araddr];
         6'h29   : reg_data_out <= slv_reg41[chan_araddr];
         6'h2A   : reg_data_out <= slv_reg42[chan_araddr];
         6'h2B   : reg_data_out <= slv_reg43[chan_araddr];
         6'h2C   : reg_data_out <= slv_reg44[chan_araddr];
         6'h2D   : reg_data_out <= slv_reg45[chan_araddr];
         6'h2E   : reg_data_out <= slv_reg46[chan_araddr];
         6'h2F   : reg_data_out <= slv_reg47[chan_araddr];
         6'h30   : reg_data_out <= slv_reg48[chan_araddr];
         6'h31   : reg_data_out <= slv_reg49[chan_araddr];
         6'h32   : reg_data_out <= slv_reg50[chan_araddr];
         6'h33   : reg_data_out <= slv_reg51[chan_araddr];
         6'h34   : reg_data_out <= slv_reg52[chan_araddr];
         6'h35   : reg_data_out <= slv_reg53[chan_araddr];
         6'h36   : reg_data_out <= slv_reg54[chan_araddr];
         6'h37   : reg_data_out <= slv_reg55[chan_araddr];
         6'h38   : reg_data_out <= slv_reg56[chan_araddr];
         6'h39   : reg_data_out <= slv_reg57[chan_araddr];
         6'h3A   : reg_data_out <= slv_reg58[chan_araddr];
         6'h3B   : reg_data_out <= slv_reg59[chan_araddr];
         6'h3C   : reg_data_out <= slv_reg60[chan_araddr];
         default : reg_data_out <= 0;
       endcase
     end
     else
     begin
       case ( axi_araddr[ADDR_LSB+CONS_REG_ADDR_BITS:ADDR_LSB] )
         9'h100   : reg_data_out <= cons_slv_reg0;
         9'h101   : reg_data_out <= cons_slv_reg1;
         9'h102   : reg_data_out <= cons_slv_reg2;
         9'h103   : reg_data_out <= cons_slv_reg3;
         9'h104   : reg_data_out <= cons_slv_reg4;
         9'h105   : reg_data_out <= cons_slv_reg5;
         9'h106   : reg_data_out <= cons_slv_reg6;
         9'h107   : reg_data_out <= cons_slv_reg7;
         9'h108   : reg_data_out <= cons_slv_reg8; //####
         9'h109   : reg_data_out <= cons_slv_reg9;
         default : reg_data_out <= 0;
       endcase
     end
   end

   // Output register or memory read data
   always @( posedge S_AXI_ACLK )
     begin
	// When there is a valid read address (S_AXI_ARVALID) with 
	// acceptance of read address by the slave (axi_arready), 
	// output the read dada 
	if (slv_reg_rden)
	  begin
	     axi_rdata <= reg_data_out;     // register read data
	  end   
     end    

   // Add user logic here

   //####Consumer specific registers
   always @ (*)
   begin//{
     luma_c0_offset     = cons_slv_reg0;
     luma_c1_offset     = cons_slv_reg1;
     luma_c2_offset     = cons_slv_reg2;
     luma_c3_offset     = cons_slv_reg3;
     chroma_c0_offset   = cons_slv_reg4;
     chroma_c1_offset   = cons_slv_reg5;
     chroma_c2_offset   = cons_slv_reg6;
     chroma_c3_offset   = cons_slv_reg7;
     luma_line_offset   = cons_slv_reg8;
     chroma_line_offset = cons_slv_reg9;
   end//}




   // Control Register
   // ISR
   genvar j;
   generate
      for (j=0;j<C_NUM_CHAN;j=j+1) begin: gen_chan_1

	 pulse_crossing prod_luma_frmbuf_addr_next_sync (.i (prod_luma_frmbuf_addr_next[j]),
					       .i_clk (producer_aclk), 
					       .i_arst_n (producer_aresetn),
					       //.o_arst_n (S_AXI_ARESETN),
					       .o_arst_n (S_AXI_ARESET[j]),
					       //.o_arst_n (rst),
					       .o_clk (S_AXI_ACLK),  
					       .o (int_prod_luma_frmbuf_addr_next[j]));

	 pulse_crossing prod_chroma_frmbuf_addr_next_sync (.i (prod_chroma_frmbuf_addr_next[j]),
					       .i_clk (producer_aclk), 
					       .i_arst_n (producer_aresetn),
					       //.o_arst_n (S_AXI_ARESETN),
					       .o_arst_n (S_AXI_ARESET[j]),
					       //.o_arst_n (rst),
					       .o_clk (S_AXI_ACLK),  
					       .o (int_prod_chroma_frmbuf_addr_next[j]));

	 pulse_crossing prod_luma_frmbuf_addr_done_sync (.i (prod_luma_frmbuf_addr_done[j]),
					       .i_clk (producer_aclk), 
					       .i_arst_n (producer_aresetn),
					       //.o_arst_n (S_AXI_ARESETN),
					       .o_arst_n (S_AXI_ARESET[j]),
					       //.o_arst_n (rst),
					       .o_clk (S_AXI_ACLK),  
					       .o (int_prod_luma_frmbuf_addr_done[j]));

	 pulse_crossing prod_chroma_frmbuf_addr_done_sync (.i (prod_chroma_frmbuf_addr_done[j]),
					       .i_clk (producer_aclk), 
					       .i_arst_n (producer_aresetn),
					       //.o_arst_n (S_AXI_ARESETN),
					       .o_arst_n (S_AXI_ARESET[j]),
					       //.o_arst_n (rst),
					       .o_clk (S_AXI_ACLK),  
					       .o (int_prod_chroma_frmbuf_addr_done[j]));

	 pulse_crossing cons_luma_frmbuf_addr_next_sync (.i (cons_luma_frmbuf_addr_next[j]),
					       .i_clk (consumer_aclk), 
					       .i_arst_n (consumer_aresetn),
					       //.o_arst_n (S_AXI_ARESETN),
					       .o_arst_n (S_AXI_ARESET[j]),
					       //.o_arst_n (rst),
					       .o_clk (S_AXI_ACLK),  
					       .o (int_cons_luma_frmbuf_addr_next[j]));

	 pulse_crossing cons_chroma_frmbuf_addr_next_sync (.i (cons_chroma_frmbuf_addr_next[j]),
					       .i_clk (consumer_aclk), 
					       .i_arst_n (consumer_aresetn),
					       //.o_arst_n (S_AXI_ARESETN),
					       .o_arst_n (S_AXI_ARESET[j]),
					       //.o_arst_n (rst),
					       .o_clk (S_AXI_ACLK),  
					       .o (int_cons_chroma_frmbuf_addr_next[j]));


	 pulse_crossing cons_luma_frmbuf_addr_done_sync (.i (cons_luma_frmbuf_addr_done[j]),
					       .i_clk (consumer_aclk), 
					       .i_arst_n (consumer_aresetn),
					       //.o_arst_n (S_AXI_ARESETN),
					       .o_arst_n (S_AXI_ARESET[j]),
					       //.o_arst_n (rst),
					       .o_clk (S_AXI_ACLK),  
					       .o (int_cons_luma_frmbuf_addr_done[j]));


	 pulse_crossing cons_chroma_frmbuf_addr_done_sync (.i (cons_chroma_frmbuf_addr_done[j]),
					       .i_clk (consumer_aclk), 
					       .i_arst_n (consumer_aresetn),
					       //.o_arst_n (S_AXI_ARESETN),
					       .o_arst_n (S_AXI_ARESET[j]),
					       //.o_arst_n (rst),
					       .o_clk (S_AXI_ACLK),  
					       .o (int_cons_chroma_frmbuf_addr_done[j]));

	 
	 pulse_crossing prod_err_syncfail_sync (.i (prod_err_syncfail[j]),
					       .i_clk (producer_aclk), 
					       .i_arst_n (producer_aresetn),
					       //.o_arst_n (S_AXI_ARESETN),
					       .o_arst_n (S_AXI_ARESET[j]),
					       //.o_arst_n (rst),
					       .o_clk (S_AXI_ACLK),  
					       .o (int_prod_err_syncfail[j]));
	 
	 pulse_crossing prod_err_wdt_sync (.i (prod_err_wdt[j]),
					       .i_clk (producer_aclk), 
					       .i_arst_n (producer_aresetn),
					       //.o_arst_n (S_AXI_ARESETN),
					       .o_arst_n (S_AXI_ARESET[j]),
					       //.o_arst_n (rst),
					       .o_clk (S_AXI_ACLK),  
					       .o (int_prod_err_wdt[j]));

	 pulse_crossing cons_err_syncfail_sync (.i (cons_err_syncfail[j]),
					       .i_clk (consumer_aclk), 
					       .i_arst_n (consumer_aresetn),
					       //.o_arst_n (S_AXI_ARESETN),
					       .o_arst_n (S_AXI_ARESET[j]),
					       //.o_arst_n (rst),
					       .o_clk (S_AXI_ACLK),  
					       .o (int_cons_err_syncfail[j]));
	 
	 pulse_crossing cons_err_wdt_sync (.i (cons_err_wdt[j]),
					       .i_clk (consumer_aclk), 
					       .i_arst_n (consumer_aresetn),
					       //.o_arst_n (S_AXI_ARESETN),
					       .o_arst_n (S_AXI_ARESET[j]),
					       //.o_arst_n (rst),
					       .o_clk (S_AXI_ACLK),  
					       .o (int_cons_err_wdt[j]));

         always @ (posedge S_AXI_ACLK)
         begin
           if (~S_AXI_ARESET[j])
           begin
             en[j]     <= 1'b0;
             irq_en[j] <= 1'b0;
           end
           else
           begin
             en[j]     <= slv_reg0[j][1];
             irq_en[j] <= slv_reg0[j][2];
           end
         end

//       assign en[j] = slv_reg0[j][1];
//       assign irq_en[j] = slv_reg0[j][2];
//Channel enable hardcode to 1 as the software is asserting enable only after
//the addr values are sent. By that time valid pulse is getting deasserted
//- Shreyas edit
//	 assign en[j] = 1'b1;
//	 assign irq_en[j] = 1'b1;
	 
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) 
	 always @(posedge S_AXI_ACLK) 
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESET[j]) 
	 //always @(posedge S_AXI_ACLK or negedge rst) 
	   begin
	      //if (S_AXI_ARESETN == 1'b0)
	      if (S_AXI_ARESET[j] == 1'b0)
		begin
		   slv_reg1[j] <= 0;
		   int_irq[j] <= 1'b0;
		end
	      else if (slv_reg_rden == 1'b1 &&  axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 5'b01 
		       && chan_araddr_valid == 1'b1 && chan_araddr == j)
		begin
		   slv_reg1[j] <= 0;  //RTC
		   int_irq[j] <= 1'b0;

		   // Catch events arriving at the same time
		   //if (~slv_reg32[j][0]) slv_reg1[j][0] <= int_prod_err_syncfail[j] | int_cons_err_syncfail[j];
		   //if (~slv_reg32[j][1]) slv_reg1[j][1] <= int_prod_err_wdt[j] | int_cons_err_wdt[j];
		   if (~slv_reg32[j][0]) slv_reg1[j][0] <= int_prod_err_syncfail[j];
		   if (~slv_reg32[j][20]) slv_reg1[j][20]<= int_cons_err_syncfail[j];
		   if (~slv_reg32[j][1]) slv_reg1[j][1] <= int_prod_err_wdt[j];
		   if (~slv_reg32[j][21]) slv_reg1[j][21]<= int_cons_err_wdt[j];
           slv_reg1[j][3:2]                     <= (int_luma_frmbuf_done[2*j +: 2] & {2{(int_luma_frmbuf_irq[j] == 1)}});
           slv_reg1[j][4]                       <= int_luma_frmbuf_skipped[j] & (int_luma_frmbuf_irq[j] == 1);
           slv_reg1[j][5]                       <= ((int_luma_frmbuf_irq[j] == 1) & (~slv_reg32[j][5]));
           slv_reg1[j][7:6]                     <= int_chroma_frmbuf_done[2*j +: 2] & {2{(int_chroma_frmbuf_irq[j] == 1)}};
           slv_reg1[j][8]                       <= int_chroma_frmbuf_skipped[j] & (int_chroma_frmbuf_irq[j] == 1);
           slv_reg1[j][9]                       <= ((int_chroma_frmbuf_irq[j] == 1) & (~slv_reg32[j][9]));
           if (~C_DEC_ENC_N)
           begin
             slv_reg1[j][11:10]                   <= int_cons_luma_frmbuf_done[2*j +: 2] & {2{(int_cons_luma_frmbuf_irq[j] == 1)}};
             slv_reg1[j][12]                      <= int_cons_luma_frmbuf_skipped[j] & (int_cons_luma_frmbuf_irq[j] == 1);
             slv_reg1[j][13]                      <= ((int_cons_luma_frmbuf_irq[j] == 1) & (~slv_reg32[j][13]));
             slv_reg1[j][15:14]                   <= int_cons_chroma_frmbuf_done[2*j +: 2] & {2{(int_cons_chroma_frmbuf_irq[j] == 1)}};
             slv_reg1[j][16]                      <= int_cons_chroma_frmbuf_skipped[j] & (int_cons_chroma_frmbuf_irq[j] == 1);
             slv_reg1[j][17]                      <= ((int_cons_chroma_frmbuf_irq[j] == 1) & (~slv_reg32[j][17]));
           end
           else
           begin
             slv_reg1[j][11:10]                   <= int_luma_frmbuf_done[2*j +: 2] & {2{(int_luma_frmbuf_irq[j] == 1)}};
             slv_reg1[j][12]                      <= int_luma_frmbuf_skipped[j] & (int_luma_frmbuf_irq[j] == 1);
             slv_reg1[j][13]                      <= ((int_luma_frmbuf_irq[j] == 1) & (~slv_reg32[j][13]));
             slv_reg1[j][15:14]                   <= int_chroma_frmbuf_done[2*j +: 2] & {2{(int_chroma_frmbuf_irq[j] == 1)}};
             slv_reg1[j][16]                      <= int_chroma_frmbuf_skipped[j] & (int_chroma_frmbuf_irq[j] == 1);
             slv_reg1[j][17]                      <= ((int_chroma_frmbuf_irq[j] == 1) & (~slv_reg32[j][17]));
           end
           slv_reg1[j][18]                      <= ((int_luma_buf_diff_err[j] == 1) & (~slv_reg32[j][18]));
           slv_reg1[j][19]                      <= ((int_chroma_buf_diff_err[j] == 1) & (~slv_reg32[j][19]));

		   if (int_luma_frmbuf_irq[j] | int_chroma_frmbuf_irq[j] |
                       int_cons_luma_frmbuf_irq[j] | int_cons_chroma_frmbuf_irq[j]) begin
		      int_irq[j] <= irq_en[j];
		   end
		   
		end
	      else begin
		 //if (~slv_reg32[j][0]) slv_reg1[j][0] <= int_prod_err_syncfail[j] | int_cons_err_syncfail[j] | slv_reg1[j][0];
		 //if (~slv_reg32[j][1]) slv_reg1[j][1] <= int_prod_err_wdt[j] | int_cons_err_wdt[j] | slv_reg1[j][1];
		 if (~slv_reg32[j][0])  slv_reg1[j][0]  <= int_prod_err_syncfail[j]| slv_reg1[j][0];
		 if (~slv_reg32[j][20]) slv_reg1[j][20] <= int_cons_err_syncfail[j] | slv_reg1[j][20];
		 if (~slv_reg32[j][1])  slv_reg1[j][1]  <= int_prod_err_wdt[j] | slv_reg1[j][1];
		 if (~slv_reg32[j][21]) slv_reg1[j][21] <= int_cons_err_wdt[j] | slv_reg1[j][21];
         slv_reg1[j][3:2]                       <= (int_luma_frmbuf_done[2*j +: 2] & {2{(int_luma_frmbuf_irq[j] == 1)}}) | slv_reg1[j][3:2];
         slv_reg1[j][4]                         <= (int_luma_frmbuf_skipped[j] & (int_luma_frmbuf_irq[j] == 1)) | slv_reg1[j][4];
         slv_reg1[j][5]                         <= (((int_luma_frmbuf_irq[j] == 1) & (~slv_reg32[j][5]))) | slv_reg1[j][5];
         slv_reg1[j][7:6]                       <= (int_chroma_frmbuf_done[2*j +: 2] & {2{(int_chroma_frmbuf_irq[j] == 1)}}) | slv_reg1[j][7:6];
         slv_reg1[j][8]                         <= (int_chroma_frmbuf_skipped[j] & (int_chroma_frmbuf_irq[j] == 1)) | slv_reg1[j][8];
         slv_reg1[j][9]                         <= (((int_chroma_frmbuf_irq[j] == 1) & (~slv_reg32[j][9]))) | slv_reg1[j][9];
         if (~C_DEC_ENC_N)
         begin
           slv_reg1[j][11:10]                     <= (int_cons_luma_frmbuf_done[2*j +: 2] & {2{(int_cons_luma_frmbuf_irq[j] == 1)}}) | slv_reg1[j][11:10];
           slv_reg1[j][12]                        <= (int_cons_luma_frmbuf_skipped[j] & (int_cons_luma_frmbuf_irq[j] == 1)) | slv_reg1[j][12];
           slv_reg1[j][13]                        <= (((int_cons_luma_frmbuf_irq[j] == 1) & (~slv_reg32[j][13]))) | slv_reg1[j][13];
           slv_reg1[j][15:14]                     <= (int_cons_chroma_frmbuf_done[2*j +: 2] & {2{(int_cons_chroma_frmbuf_irq[j] == 1)}}) | slv_reg1[j][15:14];
           slv_reg1[j][16]                        <= (int_cons_chroma_frmbuf_skipped[j] & (int_cons_chroma_frmbuf_irq[j] == 1)) | slv_reg1[j][16];
           slv_reg1[j][17]                        <= (((int_cons_chroma_frmbuf_irq[j] == 1) & (~slv_reg32[j][17]))) | slv_reg1[j][17];
         end
         else
         begin
           slv_reg1[j][11:10]                     <= (int_luma_frmbuf_done[2*j +: 2] & {2{(int_luma_frmbuf_irq[j] == 1)}}) | slv_reg1[j][11:10];
           slv_reg1[j][12]                        <= (int_luma_frmbuf_skipped[j] & (int_luma_frmbuf_irq[j] == 1)) | slv_reg1[j][12];
           slv_reg1[j][13]                        <= (((int_luma_frmbuf_irq[j] == 1) & (~slv_reg32[j][13]))) | slv_reg1[j][13];
           slv_reg1[j][15:14]                     <= (int_chroma_frmbuf_done[2*j +: 2] & {2{(int_chroma_frmbuf_irq[j] == 1)}}) | slv_reg1[j][15:14];
           slv_reg1[j][16]                        <= (int_chroma_frmbuf_skipped[j] & (int_chroma_frmbuf_irq[j] == 1)) | slv_reg1[j][16];
           slv_reg1[j][17]                        <= (((int_chroma_frmbuf_irq[j] == 1) & (~slv_reg32[j][17]))) | slv_reg1[j][17];
		 end
         slv_reg1[j][18]                        <= (((int_luma_buf_diff_err[j] == 1) & (~slv_reg32[j][18]))) | slv_reg1[j][18];
         slv_reg1[j][19]                        <= (((int_chroma_buf_diff_err[j] == 1) & (~slv_reg32[j][19]))) | slv_reg1[j][19];

		 if (int_luma_frmbuf_irq[j] | int_chroma_frmbuf_irq[j] |
                     int_cons_luma_frmbuf_irq[j] | int_cons_chroma_frmbuf_irq[j]) begin
		    int_irq[j] <= irq_en[j];
		 end
	      end
	   end // always @ (posedge producer_clk)
	 
	 always @(*) begin
	    
	    //slv_reg2@ 0x8, ...
	    prod_luma_start_addr[0][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] = {slv_reg3[j][C_FRMBUF_ADDR_WIDTH-33:0],slv_reg2[j][31:0]};
	    prod_luma_start_addr[1][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] = {slv_reg5[j][C_FRMBUF_ADDR_WIDTH-33:0],slv_reg4[j][31:0]};
	    prod_luma_start_addr[2][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] = {slv_reg7[j][C_FRMBUF_ADDR_WIDTH-33:0],slv_reg6[j][31:0]};
	    
	    //slv_reg2@ 0x8, ...
	    cons_luma_start_addr[0][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] = {slv_reg35[j][C_FRMBUF_ADDR_WIDTH-33:0],slv_reg34[j][31:0]};
	    cons_luma_start_addr[1][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] = {slv_reg37[j][C_FRMBUF_ADDR_WIDTH-33:0],slv_reg36[j][31:0]};
	    cons_luma_start_addr[2][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] = {slv_reg39[j][C_FRMBUF_ADDR_WIDTH-33:0],slv_reg38[j][31:0]};
	    
	    //slv_reg8@ 0x20, ...
	    prod_chroma_start_addr[0][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] = {slv_reg9[j][C_FRMBUF_ADDR_WIDTH-33:0],slv_reg8[j][31:0]};
	    prod_chroma_start_addr[1][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] = {slv_reg11[j][C_FRMBUF_ADDR_WIDTH-33:0],slv_reg10[j][31:0]};
	    prod_chroma_start_addr[2][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] = {slv_reg13[j][C_FRMBUF_ADDR_WIDTH-33:0],slv_reg12[j][31:0]};

	    //slv_reg8@ 0x20, ...
	    cons_chroma_start_addr[0][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] = {slv_reg41[j][C_FRMBUF_ADDR_WIDTH-33:0],slv_reg40[j][31:0]};
	    cons_chroma_start_addr[1][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] = {slv_reg43[j][C_FRMBUF_ADDR_WIDTH-33:0],slv_reg42[j][31:0]};
	    cons_chroma_start_addr[2][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] = {slv_reg45[j][C_FRMBUF_ADDR_WIDTH-33:0],slv_reg44[j][31:0]};

	    // aggregate all valid bits from address register

	    prod_luma_addr_valid[j][2] = slv_reg7[j][C_FRMBUF_ADDR_WIDTH-32];
	    prod_luma_addr_valid[j][1] = slv_reg5[j][C_FRMBUF_ADDR_WIDTH-32];
	    prod_luma_addr_valid[j][0] = slv_reg3[j][C_FRMBUF_ADDR_WIDTH-32];

	    cons_luma_addr_valid[j][2] = slv_reg39[j][C_FRMBUF_ADDR_WIDTH-32];
	    cons_luma_addr_valid[j][1] = slv_reg37[j][C_FRMBUF_ADDR_WIDTH-32];
	    cons_luma_addr_valid[j][0] = slv_reg35[j][C_FRMBUF_ADDR_WIDTH-32];

	    prod_chroma_addr_valid[j][2] = slv_reg13[j][C_FRMBUF_ADDR_WIDTH-32];
	    prod_chroma_addr_valid[j][1] = slv_reg11[j][C_FRMBUF_ADDR_WIDTH-32];
	    prod_chroma_addr_valid[j][0] = slv_reg9[j][C_FRMBUF_ADDR_WIDTH-32];

	    cons_chroma_addr_valid[j][2] = slv_reg45[j][C_FRMBUF_ADDR_WIDTH-32];
	    cons_chroma_addr_valid[j][1] = slv_reg43[j][C_FRMBUF_ADDR_WIDTH-32];
	    cons_chroma_addr_valid[j][0] = slv_reg41[j][C_FRMBUF_ADDR_WIDTH-32];

	    
	    //slv_reg14@ 0x38, ...
	    prod_luma_end_addr[0][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] = {slv_reg15[j][C_FRMBUF_ADDR_WIDTH-33:0],slv_reg14[j][31:0]};
	    prod_luma_end_addr[1][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] = {slv_reg17[j][C_FRMBUF_ADDR_WIDTH-33:0],slv_reg16[j][31:0]};  
	    prod_luma_end_addr[2][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] = {slv_reg19[j][C_FRMBUF_ADDR_WIDTH-33:0],slv_reg18[j][31:0]}; 
	    cons_luma_end_addr[0][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] = {slv_reg47[j][C_FRMBUF_ADDR_WIDTH-33:0],slv_reg46[j][31:0]};
	    cons_luma_end_addr[1][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] = {slv_reg49[j][C_FRMBUF_ADDR_WIDTH-33:0],slv_reg48[j][31:0]};  
	    cons_luma_end_addr[2][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] = {slv_reg51[j][C_FRMBUF_ADDR_WIDTH-33:0],slv_reg50[j][31:0]}; 
	    prod_luma_addr_offset[C_S_AXI_DATA_WIDTH*j +: C_S_AXI_DATA_WIDTH] = slv_reg58[j]; //####
	    prod_chroma_addr_offset[C_S_AXI_DATA_WIDTH*j +: C_S_AXI_DATA_WIDTH] = slv_reg59[j]; //####
      
	    //slv_reg20@ 0x50, ...
	    prod_chroma_end_addr[0][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] = {slv_reg21[j][C_FRMBUF_ADDR_WIDTH-33:0],slv_reg20[j][31:0]};  
	    prod_chroma_end_addr[1][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] = {slv_reg23[j][C_FRMBUF_ADDR_WIDTH-33:0],slv_reg22[j][31:0]};  
	    prod_chroma_end_addr[2][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] = {slv_reg25[j][C_FRMBUF_ADDR_WIDTH-33:0],slv_reg24[j][31:0]};  
	    cons_chroma_end_addr[0][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] = {slv_reg53[j][C_FRMBUF_ADDR_WIDTH-33:0],slv_reg52[j][31:0]};  
	    cons_chroma_end_addr[1][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] = {slv_reg55[j][C_FRMBUF_ADDR_WIDTH-33:0],slv_reg54[j][31:0]};  
	    cons_chroma_end_addr[2][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] = {slv_reg57[j][C_FRMBUF_ADDR_WIDTH-33:0],slv_reg56[j][31:0]};  

	    //slv_reg26@ 0x68, ...
	    frmbuf_luma_margin[0][32*j +: 32] = {slv_reg26[j][31:0]};
	    frmbuf_luma_margin[1][32*j +: 32] = {slv_reg27[j][31:0]};
	    frmbuf_luma_margin[2][32*j +: 32] = {slv_reg28[j][31:0]};
	    
	    //slv_reg29@ 0x74, ...
	    frmbuf_chroma_margin[0][32*j +: 32] = {slv_reg29[j][31:0]};
	    frmbuf_chroma_margin[1][32*j +: 32] = {slv_reg30[j][31:0]};
	    frmbuf_chroma_margin[2][32*j +: 32] = {slv_reg31[j][31:0]};

	 end // always @ (*)
   

	 //FSM to circle through 3 address buffer
	 ring_addr_buffer_ctrl
	   ring_addr_buffer_ctrl_per_prod_luma_chan
	     (
	      .clk (S_AXI_ACLK),
	      //.aresetn (S_AXI_ARESETN),
	      .aresetn          (S_AXI_ARESET[j]),
	      .addr_valid       (prod_luma_addr_valid[j]),
	      //.frmbuf_addr_next (int_prod_luma_frmbuf_addr_next[j]),
	      .frmbuf_addr_next (int_prod_luma_frmbuf_addr_done_rg[j]),
	      .frmbuf_done      (int_luma_frmbuf_done[2*j +: 2]),
	      .frmbuf_skipped   (int_luma_frmbuf_skipped[j]),
	      .frmbuf_irq       (int_luma_frmbuf_irq[j]),
              .buf_cnt          (int_prod_luma_buf_cnt[32*j +: 32]),  
	      .buf_id           (prod_luma_buf_id[2*j +: 2]),
	      .buf_id_valid     (prod_luma_buf_id_valid[j]),   //pulsed buf_id valid
	      .debug            (prod_luma_fsm_debug[3*j +: 3])
	      );

	 ring_addr_buffer_ctrl
	   ring_addr_buffer_ctrl_per_prod_chroma_chan
	     (
	      .clk              (S_AXI_ACLK),
	      //.aresetn        (S_AXI_ARESETN),
	      .aresetn          (S_AXI_ARESET[j]),
	      .addr_valid       (prod_chroma_addr_valid[j]),
	      //.frmbuf_addr_next (int_prod_chroma_frmbuf_addr_next[j]),
	      .frmbuf_addr_next (int_prod_chroma_frmbuf_addr_done_rg[j]),
	      .frmbuf_done      (int_chroma_frmbuf_done[2*j +: 2]),
	      .frmbuf_skipped   (int_chroma_frmbuf_skipped[j]),
	      .frmbuf_irq       (int_chroma_frmbuf_irq[j]),
              .buf_cnt          (int_prod_chroma_buf_cnt[32*j +: 32]),
	      .buf_id           (prod_chroma_buf_id[2*j +: 2]),
	      .buf_id_valid     (prod_chroma_buf_id_valid[j]) ,  //pulsed buf_id valid
	      .debug            (prod_chroma_fsm_debug[3*j +: 3])
	      
	      );


	 
	 ring_addr_buffer_ctrl
	   ring_addr_buffer_ctrl_per_cons_luma_chan
	     (
	      .clk              (S_AXI_ACLK),
	      //.aresetn        (S_AXI_ARESETN),
	      .aresetn          (S_AXI_ARESET[j]),
	      .addr_valid       (cons_luma_addr_valid[j]),
	      //.frmbuf_addr_next (int_cons_luma_frmbuf_addr_next[j]),
	      .frmbuf_addr_next (int_cons_luma_frmbuf_addr_done_rg[j]),
	      .frmbuf_done      (int_cons_luma_frmbuf_done[2*j +: 2]), //Addition of Consumer frame done
	      .frmbuf_skipped   (int_cons_luma_frmbuf_skipped[j]),
	      .frmbuf_irq       (int_cons_luma_frmbuf_irq[j]),
              .buf_cnt          (int_cons_luma_buf_cnt[32*j +: 32]),  
	      .buf_id           (cons_luma_buf_id[2*j +: 2]),
	      .buf_id_valid     (cons_luma_buf_id_valid[j]) ,  //pulsed buf_id valid
	      .debug            (cons_luma_fsm_debug[3*j +: 3])
	      
	      );

	 ring_addr_buffer_ctrl
	   ring_addr_buffer_ctrl_per_cons_chroma_chan
	     (
	      .clk (S_AXI_ACLK),
	      //.aresetn (S_AXI_ARESETN),
	      .aresetn (S_AXI_ARESET[j]),
	      .addr_valid       (cons_chroma_addr_valid[j]),
	      //.frmbuf_addr_next (int_cons_chroma_frmbuf_addr_next[j]),
	      .frmbuf_addr_next (int_cons_chroma_frmbuf_addr_done_rg[j]),
	      .frmbuf_done      (int_cons_chroma_frmbuf_done[2*j +: 2]),
	      .frmbuf_skipped   (int_cons_chroma_frmbuf_skipped[j]),//#### Addition of Consumer Frame done
	      .frmbuf_irq       (int_cons_chroma_frmbuf_irq[j]),
              .buf_cnt          (int_cons_chroma_buf_cnt[32*j +: 32]),  
	      .buf_id           (cons_chroma_buf_id[2*j +: 2]),
	      .buf_id_valid     (cons_chroma_buf_id_valid[j]),   //pulsed buf_id valid
	      .debug            (cons_chroma_fsm_debug[3*j +: 3])
	      
	      );

         always @ (posedge S_AXI_ACLK)
         //always @ (posedge S_AXI_ACLK or negedge S_AXI_ARESET[j])
         //always @ (posedge S_AXI_ACLK or negedge rst)
         begin
           if (S_AXI_ARESET[j] == 1'b0)
           begin
             int_luma_buf_diff_err[j]   <= 1'b0;
             int_chroma_buf_diff_err[j] <= 1'b0;
           end
           else
           begin
             int_luma_buf_diff_err[j]   <= ( ((int_prod_luma_buf_cnt[C_S_AXI_DATA_WIDTH*j +: C_S_AXI_DATA_WIDTH]) -
	                                      (int_cons_luma_buf_cnt[C_S_AXI_DATA_WIDTH*j +: C_S_AXI_DATA_WIDTH])) > 32'd1);
             int_chroma_buf_diff_err[j] <= ( ((int_prod_chroma_buf_cnt[C_S_AXI_DATA_WIDTH*j +: C_S_AXI_DATA_WIDTH]) -
	                                      (int_cons_chroma_buf_cnt[C_S_AXI_DATA_WIDTH*j +: C_S_AXI_DATA_WIDTH])) > 32'd1);
           end
         end
	 
	 // pulsed prod_frmbuf_addr_valid 
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	 always @(posedge S_AXI_ACLK)
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESET[j])
	 //always @(posedge S_AXI_ACLK or negedge rst)
	   begin
	      //if (S_AXI_ARESETN == 0) begin
	      if (S_AXI_ARESET[j] == 0) begin
		 prod_luma_frmbuf_addr_valid_pulse[j] <= 1'b0;
		 prod_chroma_frmbuf_addr_valid_pulse[j] <= 1'b0;		 
		 cons_luma_frmbuf_addr_valid_pulse[j] <= 1'b0;
		 cons_chroma_frmbuf_addr_valid_pulse[j] <= 1'b0;
		 
	      end
	      else begin
		 prod_luma_frmbuf_addr_valid_pulse[j] <= prod_luma_buf_id_valid[j];
		 prod_chroma_frmbuf_addr_valid_pulse[j] <= prod_chroma_buf_id_valid[j];
		 cons_luma_frmbuf_addr_valid_pulse[j] <= cons_luma_buf_id_valid[j];
		 cons_chroma_frmbuf_addr_valid_pulse[j] <= cons_chroma_buf_id_valid[j];
	      end
	   end

	 // Producer luma address multiplexer
	 always @(posedge S_AXI_ACLK)
         begin
           //if ((S_AXI_ARESETN == 1'b0) | (S_AXI_SW_ARESET == 1'b1))
           if (S_AXI_ARESET[j] == 1'b0)
           begin
             prod_luma_frmbuf_start_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] <= {C_FRMBUF_ADDR_WIDTH{1'b0}};
             prod_luma_frmbuf_end_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH]   <= {C_FRMBUF_ADDR_WIDTH{1'b0}};
             prod_luma_frmbuf_margin[32*j +: 32] <= {32{1'b0}};
           end
           else
           begin
	      if (prod_luma_buf_id_valid[j] == 1)
		case (prod_luma_buf_id[2*j +:2])
		  2'd0: begin
		     prod_luma_frmbuf_start_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] <= prod_luma_start_addr[0][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH];
		     prod_luma_frmbuf_end_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH]   <= prod_luma_end_addr[0][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] - prod_luma_addr_offset[C_S_AXI_DATA_WIDTH*j +: C_S_AXI_DATA_WIDTH];//####
		     prod_luma_frmbuf_margin[32*j +: 32] <= frmbuf_luma_margin[0][32*j +:32];
		  end
		  2'd1: begin
		     prod_luma_frmbuf_start_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] <= prod_luma_start_addr[1][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH];
		     prod_luma_frmbuf_end_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH]   <= prod_luma_end_addr[1][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] - prod_luma_addr_offset[C_S_AXI_DATA_WIDTH*j +: C_S_AXI_DATA_WIDTH];//####
		     prod_luma_frmbuf_margin[32*j +: 32] <= frmbuf_luma_margin[1][32*j +:32];
		  end
		  default: begin
		     prod_luma_frmbuf_start_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] <= prod_luma_start_addr[2][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH];
		     prod_luma_frmbuf_end_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH]   <= prod_luma_end_addr[2][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] - prod_luma_addr_offset[C_S_AXI_DATA_WIDTH*j +: C_S_AXI_DATA_WIDTH];//####;
		     prod_luma_frmbuf_margin[32*j +: 32] <= frmbuf_luma_margin[2][32*j +:32];

		  end
		endcase // case (buf_id)
             end
	   end // always @ (posedge S_AXI_ACLK)
 

	 // Producer chroma address multiplexer
	 always @(posedge S_AXI_ACLK)
         begin
           //if ((S_AXI_ARESETN == 1'b0) | (S_AXI_SW_ARESET == 1'b1))
           if (S_AXI_ARESET[j] == 1'b0)
           begin
             prod_chroma_frmbuf_start_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] <= {C_FRMBUF_ADDR_WIDTH{1'b0}}; 
             prod_chroma_frmbuf_end_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH]   <= {C_FRMBUF_ADDR_WIDTH{1'b0}}; 
             prod_chroma_frmbuf_margin[32*j +: 32] <= {32{1'b0}};
           end
           else
           begin
	      if (prod_chroma_buf_id_valid[j] == 1)
		case (prod_chroma_buf_id[2*j +:2])
		  2'd0: begin
		     prod_chroma_frmbuf_start_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] <= prod_chroma_start_addr[0][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH];
		     prod_chroma_frmbuf_end_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH]   <= prod_chroma_end_addr[0][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] - prod_chroma_addr_offset[C_S_AXI_DATA_WIDTH*j +: C_S_AXI_DATA_WIDTH];//####
		     prod_chroma_frmbuf_margin[32*j +: 32] <= frmbuf_chroma_margin[0][32*j +:32];

		  end
		  2'd1: begin
		     prod_chroma_frmbuf_start_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] <= prod_chroma_start_addr[1][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH];
		     prod_chroma_frmbuf_end_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH]   <= prod_chroma_end_addr[1][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] - prod_chroma_addr_offset[C_S_AXI_DATA_WIDTH*j +: C_S_AXI_DATA_WIDTH];//####
		     prod_chroma_frmbuf_margin[32*j +: 32] <= frmbuf_chroma_margin[1][32*j +:32];
		  end
		  default: begin
		     prod_chroma_frmbuf_start_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] <= prod_chroma_start_addr[2][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH];
		     prod_chroma_frmbuf_end_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH]   <= prod_chroma_end_addr[2][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] - prod_chroma_addr_offset[C_S_AXI_DATA_WIDTH*j +: C_S_AXI_DATA_WIDTH];//####
		     prod_chroma_frmbuf_margin[32*j +: 32] <= frmbuf_chroma_margin[2][32*j +:32];

		  end
		endcase // case (buf_id)
             end
	   end // always @ (posedge S_AXI_ACLK)


	 
	 // Consumer luma address multiplexer
	 always @(posedge S_AXI_ACLK)
         begin
           //if ((S_AXI_ARESETN == 1'b0) | (S_AXI_SW_ARESET == 1'b1))
           if (S_AXI_ARESET[j] == 1'b0)
           begin
             cons_luma_frmbuf_start_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] <= {C_FRMBUF_ADDR_WIDTH{1'b0}};
             cons_luma_frmbuf_end_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH]   <= {C_FRMBUF_ADDR_WIDTH{1'b0}};
             cons_luma_frmbuf_margin[32*j +: 32] <= {32{1'b0}};
           end
           else
           begin
	      if (cons_luma_buf_id_valid[j] == 1)
		case (cons_luma_buf_id[2*j +:2])
		  2'd0: begin
		     cons_luma_frmbuf_start_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] <= cons_luma_start_addr[0][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH];
		     cons_luma_frmbuf_end_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH]   <= cons_luma_end_addr[0][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] + luma_line_offset; //####
		     cons_luma_frmbuf_margin[32*j +: 32] <= frmbuf_luma_margin[0][32*j +:32];

		  end
		  2'd1: begin
		     cons_luma_frmbuf_start_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] <= cons_luma_start_addr[1][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH];
		     cons_luma_frmbuf_end_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH]   <= cons_luma_end_addr[1][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] + luma_line_offset; //####
		     cons_luma_frmbuf_margin[32*j +: 32] <= frmbuf_luma_margin[1][32*j +:32];

		  end
		  default: begin
		     cons_luma_frmbuf_start_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] <= cons_luma_start_addr[2][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH];
		     cons_luma_frmbuf_end_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH]   <= cons_luma_end_addr[2][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] + luma_line_offset; //####
		     cons_luma_frmbuf_margin[32*j +: 32] <= frmbuf_luma_margin[2][32*j +:32];
		  end
		endcase // case (buf_id)
             end
	   end // always @ (posedge S_AXI_ACLK)


         //Consumer chroma address multiplexer
	 always @(posedge S_AXI_ACLK)
         begin
           //if ((S_AXI_ARESETN == 1'b0) | (S_AXI_SW_ARESET == 1'b1))
           if (S_AXI_ARESET[j] == 1'b0)
           begin
             cons_chroma_frmbuf_start_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] <= {C_FRMBUF_ADDR_WIDTH{1'b0}};
             cons_chroma_frmbuf_end_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH]   <= {C_FRMBUF_ADDR_WIDTH{1'b0}};
             cons_chroma_frmbuf_margin[32*j +: 32] <= {32{1'b0}};
           end
           else
           begin
	      if (cons_chroma_buf_id_valid[j] == 1)
		case (cons_chroma_buf_id[2*j +:2])
		  2'd0: begin
		     cons_chroma_frmbuf_start_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] <= cons_chroma_start_addr[0][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH];
		     cons_chroma_frmbuf_end_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH]   <= cons_chroma_end_addr[0][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] + chroma_line_offset;//####
		     cons_chroma_frmbuf_margin[32*j +: 32] <= frmbuf_chroma_margin[0][32*j +:32];

		  end
		  2'd1: begin
		     cons_chroma_frmbuf_start_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] <= cons_chroma_start_addr[1][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH];
		     cons_chroma_frmbuf_end_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH]   <= cons_chroma_end_addr[1][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] + chroma_line_offset;//####
		     cons_chroma_frmbuf_margin[32*j +: 32] <= frmbuf_chroma_margin[1][32*j +:32];

		  end
		  default: begin
		     cons_chroma_frmbuf_start_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] <= cons_chroma_start_addr[2][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH];
		     cons_chroma_frmbuf_end_addr[C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH]   <= cons_chroma_end_addr[2][C_FRMBUF_ADDR_WIDTH*j +: C_FRMBUF_ADDR_WIDTH] + chroma_line_offset;//####
		     cons_chroma_frmbuf_margin[32*j +: 32] <= frmbuf_chroma_margin[2][32*j +:32];
		  end
		endcase // case (buf_id)
             end
	   end // always @ (posedge S_AXI_ACLK)



	 // Debug registers
	 always @(posedge S_AXI_ACLK) 
	   begin
	      //if ((S_AXI_ARESETN == 1'b0) | (S_AXI_SW_ARESET == 1'b1))
	      if (S_AXI_ARESET[j] == 1'b0)
	      begin
	        slv_reg33 [j] [31:0] <= {32{1'b0}};
	      end
	      else
	      begin
	        slv_reg33[j][0 +:3] <= prod_luma_fsm_debug[j*3 +: 3];
	        slv_reg33[j][3 +:3] <= prod_chroma_fsm_debug[j*3 +: 3];
	        slv_reg33[j][6 +:3] <= cons_luma_fsm_debug[j*3 +: 3];
	        slv_reg33[j][9 +:3] <= cons_chroma_fsm_debug[j*3 +: 3];
	        slv_reg33[j][31:12] <= {20{1'b0}};
	      end
	   end

         //Software reset
         always @ (posedge S_AXI_ACLK)
         begin
           if (S_AXI_ARESETN == 1'b0)
           begin
             srst_cnt[j] <= {3{1'b0}};
           end
           else if (S_AXI_SW_ARESET[j])
           begin
	     srst_cnt[j] <= srst_cnt[j] + 1'b1;
           end
         end

         //Buffer read count enable
         always @ (posedge S_AXI_ACLK)
         begin
           if (S_AXI_ARESETN == 1'b0)
           begin
             buf_rd_cnt_en[j] <= 1'b0;
           end
           else
           begin
             buf_rd_cnt_en[j] <= slv_reg0[j][4];
           end
         end
         //assign S_AXI_SW_ARESET = slv_reg0[0][3] | slv_reg0[1][3] | slv_reg0[2][3] | slv_reg0[3][3];
         assign S_AXI_SW_ARESET[j] = slv_reg0[j][3];
	 
      end // block: gen_chan_1
   endgenerate

    
   // User logic ends

endmodule



`timescale 1 ns / 1 ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Xilinx, Inc.
// Engineer: Davy Huang
// 
// Create Date: 04/24/2018 01:24:00 PM
// Design Name: VCU low latency synchronization IP
// Module Name: sync_ip_v1_0_2_S_AXI_MM_P
// Project Name: VCU low latency 
// Target Devices: Zynq UltraScale+ EV
// Tool Versions: Vivado 2018.1
// Description: 
// Producer monitor, and address threshold generation
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
///////////////////////////x///////////////////////////////////////////////////////


module syn_ip_v1_0_S_AXI_MM_P #
  (
   // Users to add parameters here
   parameter integer C_VIDEO_CHAN = 4, // Encoder case: 4,  Decoder case: 2
   parameter integer C_VIDEO_CHAN_ID = 0, // channel ID assigned to this producer port in Encoder case
   parameter integer C_DEC_ENC_N = 0, // Encoder (0) or Decoder (1)
   parameter [2:0]   C_RECONSTRUCTED_FRAME_DETECT = 3'b010, // for decoder case
   parameter [23:0]  C_TIMEOUT = 24'h4C4840, // Timeout in number of clock cycles for worst case start/end address elapse time
   parameter integer C_BUF_CNT_WIDTH = 10,
   parameter integer C_FRMBUF_ADDR_WIDTH = 44, 
   
   // User parameters ends
   // Do not modify the parameters beyond this line

   // Width of ID for for write address, write data, read address and read data
   parameter integer C_S_AXI_ID_WIDTH	= 1,
   // Width of S_AXI data bus
   parameter integer C_S_AXI_DATA_WIDTH	= 128,
   // Width of S_AXI address bus
   parameter integer C_S_AXI_ADDR_WIDTH	= 64,
   // Width of optional user defined signal in write address channel
   parameter integer C_S_AXI_AWUSER_WIDTH	= 0,
   // Width of optional user defined signal in read address channel
   parameter integer C_S_AXI_ARUSER_WIDTH	= 0,
   // Width of optional user defined signal in write data channel
   parameter integer C_S_AXI_WUSER_WIDTH	= 0,
   // Width of optional user defined signal in read data channel
   parameter integer C_S_AXI_RUSER_WIDTH	= 0,
   // Width of optional user defined signal in write response channel
   parameter integer C_S_AXI_BUSER_WIDTH	= 0
   )
   (
    // Users to add ports here
    // These signals are synchronous to ctrl_clk but asynchronous to S_AXI_ACLK
    input wire  ctrl_aclk,
    input wire  ctrl_aresetn,
    (* mark_debug = "true" *) input wire S_AXI_SW_ARESET,
    input wire 	[C_VIDEO_CHAN-1:0] en,
    input wire [C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN-1:0] luma_frmbuf_start_addr,
    input wire [C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN-1:0] luma_frmbuf_end_addr,
    input wire [32*C_VIDEO_CHAN-1:0] luma_frmbuf_margin,
    input wire [C_VIDEO_CHAN-1:0] luma_frmbuf_addr_valid_pulse, // pulse to indicate above three values are valid
    input wire [C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN-1:0] chroma_frmbuf_start_addr,
    input wire [C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN-1:0] chroma_frmbuf_end_addr,
    input wire [32*C_VIDEO_CHAN-1:0] chroma_frmbuf_margin,
    input wire [C_VIDEO_CHAN-1:0] chroma_frmbuf_addr_valid_pulse, // pulse to indicate above three values are valid

   (* mark_debug = "true" *) input wire [2*C_VIDEO_CHAN-1:0] luma_buf_id,
   (* mark_debug = "true" *) input wire [2*C_VIDEO_CHAN-1:0] chroma_buf_id,

    // these signals are synchronous to producer clock domain
   (* mark_debug = "true" *) output wire [C_VIDEO_CHAN-1:0] luma_frmbuf_addr_next,  // pulse to indicate done processing current address, move to the next frame buffer address    
   (* mark_debug = "true" *) output wire [C_VIDEO_CHAN*C_FRMBUF_ADDR_WIDTH-1:0]  luma_frmbuf_addr_outthres,
   (* mark_debug = "true" *) output wire [C_VIDEO_CHAN-1:0] luma_frmbuf_addr_outthres_valid_pulse,
   (* mark_debug = "true" *) output wire [C_VIDEO_CHAN-1:0] luma_frmbuf_addr_done,
   (* mark_debug = "true" *) output wire [C_VIDEO_CHAN-1:0] luma_frmbuf_c0_addr_done, //####
   (* mark_debug = "true" *) output wire [C_VIDEO_CHAN-1:0] luma_frmbuf_c1_addr_done, //####
   (* mark_debug = "true" *) output wire [C_VIDEO_CHAN-1:0] luma_frmbuf_c2_addr_done, //####
   (* mark_debug = "true" *) output wire [C_VIDEO_CHAN-1:0] luma_frmbuf_c3_addr_done, //####
   (* mark_debug = "true" *) output wire [C_VIDEO_CHAN-1:0] chroma_frmbuf_addr_next,  // pulse to indicate done processing current address, move to the next frame buffer address
   (* mark_debug = "true" *) output wire [C_VIDEO_CHAN*C_FRMBUF_ADDR_WIDTH-1:0]  chroma_frmbuf_addr_outthres,
   (* mark_debug = "true" *) output wire [C_VIDEO_CHAN-1:0] chroma_frmbuf_addr_outthres_valid_pulse,
   (* mark_debug = "true" *) output wire [C_VIDEO_CHAN-1:0] chroma_frmbuf_addr_done,
   (* mark_debug = "true" *) output wire [C_VIDEO_CHAN-1:0] chroma_frmbuf_c0_addr_done, //####
   (* mark_debug = "true" *) output wire [C_VIDEO_CHAN-1:0] chroma_frmbuf_c1_addr_done, //####
   (* mark_debug = "true" *) output wire [C_VIDEO_CHAN-1:0] chroma_frmbuf_c2_addr_done, //####
   (* mark_debug = "true" *) output wire [C_VIDEO_CHAN-1:0] chroma_frmbuf_c3_addr_done, //####

    
    output wire [C_VIDEO_CHAN-1:0] luma_timeout,  // errors
    output reg  [C_VIDEO_CHAN-1:0] outofrange,    // encoder out of range error

    output wire [C_VIDEO_CHAN-1:0] chroma_timeout,
    //output reg  [C_VIDEO_CHAN-1:0] chroma_outofrange,

      input wire [31:0] luma_c0_offset, //####
      input wire [31:0] luma_c1_offset, //####
      input wire [31:0] luma_c2_offset, //####
      input wire [31:0] luma_c3_offset, //####
      input wire [31:0] chroma_c0_offset, //####
      input wire [31:0] chroma_c1_offset, //####
      input wire [31:0] chroma_c2_offset, //####
      input wire [31:0] chroma_c3_offset, //####

    // User ports ends
    // Do not modify the ports beyond this line

    // Global Clock Signal
    input wire  S_AXI_ACLK,
    // Global Reset Signal. This Signal is Active LOW
    input wire  S_AXI_ARESETN,
    // Write Address ID
   (* mark_debug = "true" *) input wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_AWID,
    // Write address
   (* mark_debug = "true" *) input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    // Burst length. The burst length gives the exact number of transfers in a burst
   (* mark_debug = "true" *) input wire [7 : 0] S_AXI_AWLEN,
    // Burst size. This signal indicates the size of each transfer in the burst
   (* mark_debug = "true" *) input wire [2 : 0] S_AXI_AWSIZE,
    // Burst type. The burst type and the size information, 
    // determine how the address for each transfer within the burst is calculated.
   (* mark_debug = "true" *) input wire [1 : 0] S_AXI_AWBURST,
    // Lock type. Provides additional information about the
    // atomic characteristics of the transfer.
    input wire  S_AXI_AWLOCK,
    // Memory type. This signal indicates how transactions
    // are required to progress through a system.
    input wire [3 : 0] S_AXI_AWCACHE,
    // Protection type. This signal indicates the privilege
    // and security level of the transaction, and whether
    // the transaction is a data access or an instruction access.
    input wire [2 : 0] S_AXI_AWPROT,
    // Quality of Service, QoS identifier sent for each
    // write transaction.
    input wire [3 : 0] S_AXI_AWQOS,
    // Region identifier. Permits a single physical interface
    // on a slave to be used for multiple logical interfaces.
    input wire [3 : 0] S_AXI_AWREGION,
    // Optional User-defined signal in the write address channel.
    input wire [C_S_AXI_AWUSER_WIDTH-1 : 0] S_AXI_AWUSER,
    // Write address valid. This signal indicates that
    // the channel is signaling valid write address and
    // control information.
   (* mark_debug = "true" *) input wire  S_AXI_AWVALID,
    // Write address ready. This signal indicates that
    // the slave is ready to accept an address and associated
    // control signals.
   (* mark_debug = "true" *) input wire  S_AXI_AWREADY,
    // Write Data
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    // Write strobes. This signal indicates which byte
    // lanes hold valid data. There is one write strobe
    // bit for each eight bits of the write data bus.
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    // Write last. This signal indicates the last transfer
    // in a write burst.
    input wire  S_AXI_WLAST,
    // Optional User-defined signal in the write data channel.
    input wire [C_S_AXI_WUSER_WIDTH-1 : 0] S_AXI_WUSER,
    // Write valid. This signal indicates that valid write
    // data and strobes are available.
    input wire  S_AXI_WVALID,
    // Write ready. This signal indicates that the slave
    // can accept the write data.
    input wire  S_AXI_WREADY,
    // Response ID tag. This signal is the ID tag of the
    // write response.
   (* mark_debug = "true" *) input wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_BID,
    // Write response. This signal indicates the status
    // of the write transaction.
    input wire [1 : 0] S_AXI_BRESP,
    // Optional User-defined signal in the write response channel.
    input wire [C_S_AXI_BUSER_WIDTH-1 : 0] S_AXI_BUSER,
    // Write response valid. This signal indicates that the
    // channel is signaling a valid write response.
    input wire  S_AXI_BVALID,
    // Response ready. This signal indicates that the master
    // can accept a write response.
    input wire  S_AXI_BREADY,
    // Read address ID. This signal is the identification
    // tag for the read address group of signals.
   (* mark_debug = "true" *) input wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_ARID,
    // Read address. This signal indicates the initial
    // address of a read burst transaction.
   (* mark_debug = "true" *) input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    // Burst length. The burst length gives the exact number of transfers in a burst
   (* mark_debug = "true" *) input wire [7 : 0] S_AXI_ARLEN,
    // Burst size. This signal indicates the size of each transfer in the burst
   (* mark_debug = "true" *) input wire [2 : 0] S_AXI_ARSIZE,
    // Burst type. The burst type and the size information, 
    // determine how the address for each transfer within the burst is calculated.
   (* mark_debug = "true" *) input wire [1 : 0] S_AXI_ARBURST,
    // Lock type. Provides additional information about the
    // atomic characteristics of the transfer.
    input wire  S_AXI_ARLOCK,
    // Memory type. This signal indicates how transactions
    // are required to progress through a system.
    input wire [3 : 0] S_AXI_ARCACHE,
    // Protection type. This signal indicates the privilege
    // and security level of the transaction, and whether
    // the transaction is a data access or an instruction access.
    input wire [2 : 0] S_AXI_ARPROT,
    // Quality of Service, QoS identifier sent for each
    // read transaction.
    input wire [3 : 0] S_AXI_ARQOS,
    // Region identifier. Permits a single physical interface
    // on a slave to be used for multiple logical interfaces.
    input wire [3 : 0] S_AXI_ARREGION,
    // Optional User-defined signal in the read address channel.
    input wire [C_S_AXI_ARUSER_WIDTH-1 : 0] S_AXI_ARUSER,
    // Write address valid. This signal indicates that
    // the channel is signaling valid read address and
    // control information.
   (* mark_debug = "true" *) input wire  S_AXI_ARVALID,
    // Read address ready. This signal indicates that
    // the slave is ready to accept an address and associated
    // control signals.
   (* mark_debug = "true" *) input wire  S_AXI_ARREADY,
    // Read ID tag. This signal is the identification tag
    // for the read data group of signals generated by the slave.
   (* mark_debug = "true" *) input wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_RID,
    // Read Data
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    // Read response. This signal indicates the status of
    // the read transfer.
   (* mark_debug = "true" *) input wire [1 : 0] S_AXI_RRESP,
    // Read last. This signal indicates the last transfer
    // in a read burst.
   (* mark_debug = "true" *) input wire  S_AXI_RLAST,
    // Optional User-defined signal in the read address channel.
    input wire [C_S_AXI_RUSER_WIDTH-1 : 0] S_AXI_RUSER,
    // Read valid. This signal indicates that the channel
    // is signaling the required read data.
   (* mark_debug = "true" *) input wire  S_AXI_RVALID,
    // Read ready. This signal indicates that the master can
    // accept the read data and response information.
   (* mark_debug = "true" *) input wire  S_AXI_RREADY
    );

  (* mark_debug = "true" *) reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_axaddr;
  (* mark_debug = "true" *) reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_axaddr_next;
  (* mark_debug = "true" *) reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_axaddr_burst_len;
   wire [C_S_AXI_ADDR_WIDTH-1 : 0] axi_axlen =  S_AXI_AWLEN;  // expand bit width

  (* mark_debug = "true" *) reg 				   axi_axaddr_load;
  (* mark_debug = "true" *) reg 				   axi_axaddr_load_p;
 (* mark_debug = "true" *)  wire [C_VIDEO_CHAN-1:0] 	   int_en;

   
  (* mark_debug = "true" *) reg 				   axi_bresp_ok;
  (* mark_debug = "true" *) reg 				   axi_bresp_valid;
				   
   (* ASYNC_REG = "TRUE" *) reg [C_FRMBUF_ADDR_WIDTH-1:0] i_luma_frmbuf_start_addr [C_VIDEO_CHAN-1:0];
   (* ASYNC_REG = "TRUE" *) reg [C_FRMBUF_ADDR_WIDTH-1:0] i_luma_frmbuf_end_addr [C_VIDEO_CHAN-1:0];
   (* ASYNC_REG = "TRUE" *) reg [31:0] i_luma_frmbuf_margin [C_VIDEO_CHAN-1:0];
  (* mark_debug = "true" *) wire [C_VIDEO_CHAN-1:0] 	   i_luma_frmbuf_addr_valid_pulse;
   
  (* mark_debug = "true" *) reg [C_VIDEO_CHAN*C_FRMBUF_ADDR_WIDTH-1:0]   int_luma_frmbuf_addr_start;
  (* mark_debug = "true" *) reg [C_VIDEO_CHAN*C_FRMBUF_ADDR_WIDTH-1:0]   int_luma_frmbuf_addr_end;
  (* mark_debug = "true" *) wire [C_VIDEO_CHAN*C_FRMBUF_ADDR_WIDTH-1:0]   cons_c0_luma_frmbuf_addr_end;//####
  (* mark_debug = "true" *) wire [C_VIDEO_CHAN*C_FRMBUF_ADDR_WIDTH-1:0]   cons_c1_luma_frmbuf_addr_end;//####
  (* mark_debug = "true" *) wire [C_VIDEO_CHAN*C_FRMBUF_ADDR_WIDTH-1:0]   cons_c2_luma_frmbuf_addr_end;//####
  (* mark_debug = "true" *) wire [C_VIDEO_CHAN*C_FRMBUF_ADDR_WIDTH-1:0]   cons_c3_luma_frmbuf_addr_end;//####

   reg [C_VIDEO_CHAN*32-1:0] 	   int_luma_frmbuf_addr_margin;
  (* mark_debug = "true" *) reg [C_VIDEO_CHAN-1:0] 	   int_luma_frmbuf_addr_valid;
  (* mark_debug = "true" *) reg [C_VIDEO_CHAN-1:0] 	   int_luma_frmbuf_addr_valid_pulse;
   

   (* ASYNC_REG = "TRUE" *) reg [C_FRMBUF_ADDR_WIDTH-1:0] i_chroma_frmbuf_start_addr [C_VIDEO_CHAN-1:0];
   (* ASYNC_REG = "TRUE" *) reg [C_FRMBUF_ADDR_WIDTH-1:0] i_chroma_frmbuf_end_addr [C_VIDEO_CHAN-1:0];
   (* ASYNC_REG = "TRUE" *) reg [31:0] i_chroma_frmbuf_margin [C_VIDEO_CHAN-1:0];
  (* mark_debug = "true" *) wire [C_VIDEO_CHAN-1:0] 	   i_chroma_frmbuf_addr_valid_pulse;
   
  (* mark_debug = "true" *) reg [C_VIDEO_CHAN*C_FRMBUF_ADDR_WIDTH-1:0] int_chroma_frmbuf_addr_start;
  (* mark_debug = "true" *) reg [C_VIDEO_CHAN*C_FRMBUF_ADDR_WIDTH-1:0] int_chroma_frmbuf_addr_end;
  (* mark_debug = "true" *) wire [C_VIDEO_CHAN*C_FRMBUF_ADDR_WIDTH-1:0] cons_c0_chroma_frmbuf_addr_end;//####
  (* mark_debug = "true" *) wire [C_VIDEO_CHAN*C_FRMBUF_ADDR_WIDTH-1:0] cons_c1_chroma_frmbuf_addr_end;//####
  (* mark_debug = "true" *) wire [C_VIDEO_CHAN*C_FRMBUF_ADDR_WIDTH-1:0] cons_c2_chroma_frmbuf_addr_end;//####
  (* mark_debug = "true" *) wire [C_VIDEO_CHAN*C_FRMBUF_ADDR_WIDTH-1:0] cons_c3_chroma_frmbuf_addr_end;//####
   reg [C_VIDEO_CHAN*32-1:0] 		      int_chroma_frmbuf_addr_margin;
  (* mark_debug = "true" *) reg [C_VIDEO_CHAN-1:0] 	   int_chroma_frmbuf_addr_valid;
  (* mark_debug = "true" *) reg [C_VIDEO_CHAN-1:0] 	   int_chroma_frmbuf_addr_valid_pulse;

   reg 				   axi_axaddr_luma_inrange;
   reg 				   axi_axaddr_chroma_inrange;

  //(* mark_debug = "true" *) reg [3:0] 			   luma_chan_dec;
  //(* mark_debug = "true" *) reg [3:0] 			   chroma_chan_dec;

  (* mark_debug = "true" *) reg [2:0] 			   S_AXI_AW_LUMA_CHANID;
  (* mark_debug = "true" *) reg [2:0] 			   S_AXI_AW_CHROMA_CHANID;
   
  (* mark_debug = "true" *) reg                             luma_chan_active;
  (* mark_debug = "true" *) reg 				   chroma_chan_active;

  (* mark_debug = "true" *) reg [2:0] 			   luma_chan_id;
  (* mark_debug = "true" *) reg [2:0] 			   chroma_chan_id;
   
  
  (* mark_debug = "true" *) wire  int_s_axi_sw_areset;
  (* mark_debug = "true" *) wire  S_AXI_ARESET;

  (* mark_debug = "true" *) reg  [C_VIDEO_CHAN -1:0] luma_outofrange; 
  (* mark_debug = "true" *) reg  [C_VIDEO_CHAN -1:0] chroma_outofrange;
  (* mark_debug = "true" *) reg  [C_BUF_CNT_WIDTH-1:0] luma_buf_cnt;
  (* mark_debug = "true" *) reg  [C_BUF_CNT_WIDTH-1:0] chroma_buf_cnt;

  (* mark_debug = "true" *) wire prod_luma_ch0_inrange;
  (* mark_debug = "true" *) wire prod_luma_ch1_inrange;
  (* mark_debug = "true" *) wire prod_luma_ch2_inrange;
  (* mark_debug = "true" *) wire prod_luma_ch3_inrange;
  (* mark_debug = "true" *) wire prod_chroma_ch0_inrange;
  (* mark_debug = "true" *) wire prod_chroma_ch1_inrange;
  (* mark_debug = "true" *) wire prod_chroma_ch2_inrange;
  (* mark_debug = "true" *) wire prod_chroma_ch3_inrange;
  (* mark_debug = "true" *) reg [C_VIDEO_CHAN-1:0] luma_chan_dec;
  (* mark_debug = "true" *) reg [C_VIDEO_CHAN-1:0] chroma_chan_dec;


   integer i;

   dff_sync sw_rst_sync (.i(S_AXI_SW_ARESET),
                         .clk (S_AXI_ACLK),
                         .o(int_s_axi_sw_areset));
 
   assign S_AXI_ARESET = S_AXI_ARESETN & (~ int_s_axi_sw_areset);

  
   genvar  c;
   generate
      for (c=0;c<C_VIDEO_CHAN;c=c+1) begin : gen_video_chan
	 
	 
	 // Clock domain crossing
	 //-----------------------------

	 pulse_crossing luma_addr_valid_sync (.i (luma_frmbuf_addr_valid_pulse[c]),
					      .i_clk (ctrl_aclk), // This is S_AXI_CTL clock
					      .i_arst_n (ctrl_aresetn),
					      //.o_arst_n (S_AXI_ARESETN),
					      .o_arst_n (S_AXI_ARESET),
					      .o_clk (S_AXI_ACLK),   // This is producer clock
					      .o (i_luma_frmbuf_addr_valid_pulse[c]));
	 
	 pulse_crossing chroma_addr_valid_sync (.i (chroma_frmbuf_addr_valid_pulse[c]),
						.i_clk (ctrl_aclk), // This is S_AXI_CTL clock
						.i_arst_n (ctrl_aresetn),
						//.o_arst_n (S_AXI_ARESETN),
						.o_arst_n (S_AXI_ARESET),
						.o_clk (S_AXI_ACLK),   // This is producer clock
						.o (i_chroma_frmbuf_addr_valid_pulse[c]));

	 dff_sync en_sync (.i(en[c]),
			   .clk (S_AXI_ACLK),
			   .o(int_en[c]));
	 
   
	 // Register frame buffer addresses in different clock domain
	 // --------------------
	 always @(posedge S_AXI_ACLK)
	   begin
	      if (int_en[c]) begin
		 i_luma_frmbuf_start_addr[c] <= luma_frmbuf_start_addr[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH];
		 i_luma_frmbuf_end_addr[c] <= luma_frmbuf_end_addr[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH];
		 i_luma_frmbuf_margin[c] <= luma_frmbuf_margin[c*32 +: 32];
		 
		 i_chroma_frmbuf_start_addr[c] <= chroma_frmbuf_start_addr[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH];
		 i_chroma_frmbuf_end_addr[c] <= chroma_frmbuf_end_addr[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH];
		 i_chroma_frmbuf_margin[c] <= chroma_frmbuf_margin[c*32 +: 32];
		 
	      end
	   end // always @ (posedge S_AXI_ACLK)


	 // Start/end address domain crossing
	 // -----------------------------
 
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESET)
	 always @(posedge S_AXI_ACLK)
	   begin
	      //if (S_AXI_ARESETN == 0) begin
	      if (S_AXI_ARESET == 0) begin
		 int_luma_frmbuf_addr_valid[c] <= 0;
	      end
	      else if (luma_frmbuf_addr_next[c]) begin   // clear by address monitor FSM
		 int_luma_frmbuf_addr_valid[c] <= 1'b0;
	      end
	      else if (i_luma_frmbuf_addr_valid_pulse[c]) begin  // set by ring buffer control
		 int_luma_frmbuf_addr_valid[c] <= 1'b1;
	      end
	   end

	 always @(posedge S_AXI_ACLK)
	   begin
	      if (i_luma_frmbuf_addr_valid_pulse[c]) begin
		 int_luma_frmbuf_addr_start[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH] <= i_luma_frmbuf_start_addr[c];
		 int_luma_frmbuf_addr_end[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH] <= i_luma_frmbuf_end_addr[c];
		 int_luma_frmbuf_addr_margin[c*32 +: 32] <= i_luma_frmbuf_margin[c]; 
	      end
	      int_luma_frmbuf_addr_valid_pulse[c] <= i_luma_frmbuf_addr_valid_pulse[c];
	      
	   end
	 
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESET)
	 always @(posedge S_AXI_ACLK)
	   begin
	      //if (S_AXI_ARESETN == 0) begin
	      if (S_AXI_ARESET == 0) begin
		 int_chroma_frmbuf_addr_valid[c] <= 0;
	      end
	      else if (chroma_frmbuf_addr_next[c]) begin   // clear by address monitor FSM
		 int_chroma_frmbuf_addr_valid[c] <= 1'b0;
	      end
	      else if (i_chroma_frmbuf_addr_valid_pulse[c]) begin  // set by ring buffer control
		 int_chroma_frmbuf_addr_valid[c] <= 1'b1;
	      end
	   end
	 
	 always @(posedge S_AXI_ACLK)
	   begin
	      if (i_chroma_frmbuf_addr_valid_pulse[c]) begin
		 int_chroma_frmbuf_addr_start[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH] <= i_chroma_frmbuf_start_addr[c];
		 int_chroma_frmbuf_addr_end[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH] <= i_chroma_frmbuf_end_addr[c];
		 int_chroma_frmbuf_addr_margin[c*32 +: 32] <= i_chroma_frmbuf_margin[c]; 
	      end
	      int_chroma_frmbuf_addr_valid_pulse[c] <= i_chroma_frmbuf_addr_valid_pulse[c];

	   end

        assign cons_c0_luma_frmbuf_addr_end[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH] = int_luma_frmbuf_addr_end[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH] - luma_c0_offset; //####
        assign cons_c1_luma_frmbuf_addr_end[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH] = int_luma_frmbuf_addr_end[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH] - luma_c1_offset; //####
        assign cons_c2_luma_frmbuf_addr_end[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH] = int_luma_frmbuf_addr_end[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH] - luma_c2_offset; //####
        assign cons_c3_luma_frmbuf_addr_end[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH] = int_luma_frmbuf_addr_end[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH] - luma_c3_offset; //####
        assign cons_c0_chroma_frmbuf_addr_end[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH] = int_chroma_frmbuf_addr_end[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH] - chroma_c0_offset; //####
        assign cons_c1_chroma_frmbuf_addr_end[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH] = int_chroma_frmbuf_addr_end[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH] - chroma_c1_offset; //####
        assign cons_c2_chroma_frmbuf_addr_end[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH] = int_chroma_frmbuf_addr_end[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH] - chroma_c2_offset; //####
        assign cons_c3_chroma_frmbuf_addr_end[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH] = int_chroma_frmbuf_addr_end[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH] - chroma_c3_offset; //####

      end // block: gen_video_chan
   endgenerate
   

   always @(posedge S_AXI_ACLK)
   begin
     if (~S_AXI_ARESET)
     begin
       luma_buf_cnt   <= {C_BUF_CNT_WIDTH{1'b0}};
       chroma_buf_cnt <= {C_BUF_CNT_WIDTH{1'b0}};
     end
     else
     begin
       luma_buf_cnt   <= luma_buf_cnt   + luma_frmbuf_addr_done[C_VIDEO_CHAN_ID];
       chroma_buf_cnt <= chroma_buf_cnt + chroma_frmbuf_addr_done[C_VIDEO_CHAN_ID];
     end
   end

   // Pipeline
   // ----------------------
   //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
   //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESET)
   always @(posedge S_AXI_ACLK)
     begin
	//if (S_AXI_ARESETN == 0) begin
	if (S_AXI_ARESET == 0) begin
	   axi_axaddr_load_p <= 1'b0;
	end
	else begin
	   axi_axaddr_load_p <= axi_axaddr_load;
	end
     end
	

   assign prod_luma_ch0_inrange   = ((S_AXI_AWADDR >= int_luma_frmbuf_addr_start[0 +: C_FRMBUF_ADDR_WIDTH]) && 
                                     (S_AXI_AWADDR <= int_luma_frmbuf_addr_end  [0 +: C_FRMBUF_ADDR_WIDTH]) &&
                                     (int_luma_frmbuf_addr_valid[0]) && 
                                     (S_AXI_AWID == 1'b0));
   assign prod_luma_ch1_inrange   = ((S_AXI_AWADDR >= int_luma_frmbuf_addr_start[(1*C_FRMBUF_ADDR_WIDTH) +: C_FRMBUF_ADDR_WIDTH]) &&
                                     (S_AXI_AWADDR <= int_luma_frmbuf_addr_end  [(1*C_FRMBUF_ADDR_WIDTH) +: C_FRMBUF_ADDR_WIDTH]) &&
                                     (int_luma_frmbuf_addr_valid[1]) &&
                                     (S_AXI_AWID == 1'b0));
   assign prod_luma_ch2_inrange   = ((S_AXI_AWADDR >= int_luma_frmbuf_addr_start[(2*C_FRMBUF_ADDR_WIDTH) +: C_FRMBUF_ADDR_WIDTH]) &&
                                     (S_AXI_AWADDR <= int_luma_frmbuf_addr_end  [(2*C_FRMBUF_ADDR_WIDTH) +: C_FRMBUF_ADDR_WIDTH]) &&
                                     (int_luma_frmbuf_addr_valid[2]) &&
                                     (S_AXI_AWID == 1'b0));
   assign prod_luma_ch3_inrange   = ((S_AXI_AWADDR >= int_luma_frmbuf_addr_start[(3*C_FRMBUF_ADDR_WIDTH) +: C_FRMBUF_ADDR_WIDTH]) &&
                                     (S_AXI_AWADDR <= int_luma_frmbuf_addr_end  [(3*C_FRMBUF_ADDR_WIDTH) +: C_FRMBUF_ADDR_WIDTH]) &&
                                     (int_luma_frmbuf_addr_valid[3]) &&
                                     (S_AXI_AWID == 1'b0));
   assign prod_chroma_ch0_inrange = ((S_AXI_AWADDR >= int_chroma_frmbuf_addr_start[0 +: C_FRMBUF_ADDR_WIDTH]) && 
                                     (S_AXI_AWADDR <= int_chroma_frmbuf_addr_end  [0 +: C_FRMBUF_ADDR_WIDTH]) &&
                                     (int_chroma_frmbuf_addr_valid[0]) && 
                                     (S_AXI_AWID == 1'b0));
   assign prod_chroma_ch1_inrange = ((S_AXI_AWADDR >= int_chroma_frmbuf_addr_start[(1*C_FRMBUF_ADDR_WIDTH) +: C_FRMBUF_ADDR_WIDTH]) &&
                                     (S_AXI_AWADDR <= int_chroma_frmbuf_addr_end  [(1*C_FRMBUF_ADDR_WIDTH) +: C_FRMBUF_ADDR_WIDTH]) &&
                                     (int_chroma_frmbuf_addr_valid[1]) &&
                                     (S_AXI_AWID == 1'b0));
   assign prod_chroma_ch2_inrange = ((S_AXI_AWADDR >= int_chroma_frmbuf_addr_start[(2*C_FRMBUF_ADDR_WIDTH) +: C_FRMBUF_ADDR_WIDTH]) &&
                                     (S_AXI_AWADDR <= int_chroma_frmbuf_addr_end  [(2*C_FRMBUF_ADDR_WIDTH) +: C_FRMBUF_ADDR_WIDTH]) &&
                                     (int_chroma_frmbuf_addr_valid[2]) &&
                                     (S_AXI_AWID == 1'b0));
   assign prod_chroma_ch3_inrange = ((S_AXI_AWADDR >= int_chroma_frmbuf_addr_start[(3*C_FRMBUF_ADDR_WIDTH) +: C_FRMBUF_ADDR_WIDTH]) &&
                                     (S_AXI_AWADDR <= int_chroma_frmbuf_addr_end  [(3*C_FRMBUF_ADDR_WIDTH) +: C_FRMBUF_ADDR_WIDTH]) &&
                                     (int_chroma_frmbuf_addr_valid[3]) &&
                                     (S_AXI_AWID == 1'b0));



   //Address decoding to check in-range and identify video channel ID
   //-----------------------------------------
   generate
      if (C_DEC_ENC_N == 0) begin: gen_enc_chan_decode

        always @ (*)
        begin
          luma_chan_dec  = {prod_luma_ch3_inrange,prod_luma_ch2_inrange,
                            prod_luma_ch1_inrange,prod_luma_ch0_inrange};
           case (luma_chan_dec)
             4'b0001:
               S_AXI_AW_LUMA_CHANID = 3'b000;
             4'b0010:
               S_AXI_AW_LUMA_CHANID = 3'b001;
             4'b0100:
               S_AXI_AW_LUMA_CHANID = 3'b010;
             4'b1000:
               S_AXI_AW_LUMA_CHANID = 3'b011;
             4'b0000:
               S_AXI_AW_LUMA_CHANID = 3'b100;
             default:
               begin
                 S_AXI_AW_LUMA_CHANID = 3'b100;
               end
           endcase // case (chan_dec)
        end

        always @ (*)
        begin
          chroma_chan_dec  = {prod_chroma_ch3_inrange,prod_chroma_ch2_inrange,
                              prod_chroma_ch1_inrange,prod_chroma_ch0_inrange};
           case (chroma_chan_dec)
             4'b0001:
               S_AXI_AW_CHROMA_CHANID = 3'b000;
             4'b0010:
               S_AXI_AW_CHROMA_CHANID = 3'b001;
             4'b0100:
               S_AXI_AW_CHROMA_CHANID = 3'b010;
             4'b1000:
               S_AXI_AW_CHROMA_CHANID = 3'b011;
             4'b0000:
               S_AXI_AW_CHROMA_CHANID = 3'b100;
             default:
               begin
                 S_AXI_AW_CHROMA_CHANID = 3'b100;
               end
           endcase // case (chan_dec)
        end


	// always @(*) begin
        //   if ((S_AXI_AWADDR >= int_luma_frmbuf_addr_start[C_VIDEO_CHAN_ID*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH]) &&
        //       (S_AXI_AWADDR <= int_luma_frmbuf_addr_end[C_VIDEO_CHAN_ID*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH]) &&
        //       (int_luma_frmbuf_addr_valid[C_VIDEO_CHAN_ID] == 1) &&
        //       (S_AXI_AWID == 1'b0))
	//      S_AXI_AW_LUMA_CHANID = C_VIDEO_CHAN_ID;
	//    else
	//      S_AXI_AW_LUMA_CHANID = 3'b100;
	// end

	// always @(*) begin
	//    
	//    if ((S_AXI_AWADDR >= int_chroma_frmbuf_addr_start[C_VIDEO_CHAN_ID*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH]) &&
        //        (S_AXI_AWADDR <= int_chroma_frmbuf_addr_end[C_VIDEO_CHAN_ID*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH]) &&
        //        (int_chroma_frmbuf_addr_valid[C_VIDEO_CHAN_ID] == 1) &&
        //        (S_AXI_AWID == 1'b0))
	//      S_AXI_AW_CHROMA_CHANID = C_VIDEO_CHAN_ID;
	//    else
	//      S_AXI_AW_CHROMA_CHANID = 3'b100;

	// end

      end

      else begin: gen_dec_chan_decode
	 
	 always @(*) begin
	    luma_chan_dec[3:0] = 4'b0000;
	    
	    for (i=0;i<C_VIDEO_CHAN;i=i+1)
	      if (S_AXI_AWID[2:0] == C_RECONSTRUCTED_FRAME_DETECT )
                luma_chan_dec[i] = ((S_AXI_AWADDR >= int_luma_frmbuf_addr_start[i*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH]) &&
                                    (S_AXI_AWADDR <= int_luma_frmbuf_addr_end[i*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH]) &&
                                    (int_luma_frmbuf_addr_valid[i] == 1));
	      else
		luma_chan_dec[i] = 1'b0;
	    
	    case (luma_chan_dec)
	      4'b0001:
		S_AXI_AW_LUMA_CHANID = 3'b000;
	      4'b0010:
		S_AXI_AW_LUMA_CHANID = 3'b001;
	      4'b0100:
		S_AXI_AW_LUMA_CHANID = 3'b010;
	      4'b1000:
		S_AXI_AW_LUMA_CHANID = 3'b011;
	      4'b0000:
		S_AXI_AW_LUMA_CHANID = 3'b100;
	      default:
		begin
		   S_AXI_AW_LUMA_CHANID = 3'b100;
		   //synthesis translate_off
		   //if (syn_ip_test_sim.init_done === 1'b1) begin
		      $display ("[%m:%0t] ERROR: AXI address decoding error. Cannot match it to any video channel address range. Addr=h%0x, chan_dec=b%0b,luma_frmbuf_addr_start[0]=h%0x,luma_frmbuf_addr_end[0]=h%0x,luma_frmbuf_addr_start[1]=h%0x,luma_frmbuf_addr_end[1]=h%0x",
				$time, S_AXI_AWADDR, luma_chan_dec,
				int_luma_frmbuf_addr_start[0 +: C_FRMBUF_ADDR_WIDTH],
				int_luma_frmbuf_addr_end[0 +: C_FRMBUF_ADDR_WIDTH],
				int_luma_frmbuf_addr_start[C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH],
				int_luma_frmbuf_addr_end[C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH]);
		      

		     // $stop;
		   //end
		   //synthesis translate_on
		end
	    endcase // case (chan_dec)
	 end // always @ (*)
	 
	 
	 always @(*) begin
	    chroma_chan_dec[3:0] = 4'b0000;
	    
	    for (i=0;i<C_VIDEO_CHAN;i=i+1)
	      if (S_AXI_AWID[2:0] == C_RECONSTRUCTED_FRAME_DETECT )
		chroma_chan_dec[i] = ((S_AXI_AWADDR >= int_chroma_frmbuf_addr_start[i*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH]) &&
                                      (S_AXI_AWADDR <= int_chroma_frmbuf_addr_end[i*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH]) &&
                                      (int_chroma_frmbuf_addr_valid[i] == 1));
	      else
		chroma_chan_dec[i] = 1'b0;
	    
	    case (chroma_chan_dec)
	      4'b0001:
		S_AXI_AW_CHROMA_CHANID = 3'b000;
	      4'b0010:
		S_AXI_AW_CHROMA_CHANID = 3'b001;
	      4'b0100:
		S_AXI_AW_CHROMA_CHANID = 3'b010;
	      4'b1000:
		S_AXI_AW_CHROMA_CHANID = 3'b011;
	      4'b0000:
		S_AXI_AW_CHROMA_CHANID = 3'b100;
	      default:
		begin
		   S_AXI_AW_CHROMA_CHANID = 3'b100;
		   //synthesis translate_off
		   //if (syn_ip_test_sim.init_done === 1'b1) begin
		      $display ("[%m:%0t] ERROR: AXI address decoding error. Cannot match it to any video channel address range. Addr=h%0x, chan_dec=b%0b,chroma_frmbuf_addr_start[0]=h%0x,chroma_frmbuf_addr_end[0]=h%0x",
				$time, S_AXI_AWADDR, chroma_chan_dec,int_chroma_frmbuf_addr_start[0 +: C_FRMBUF_ADDR_WIDTH],
				int_chroma_frmbuf_addr_end[0 +: C_FRMBUF_ADDR_WIDTH]);
		      //$stop;
		   //end
		   //synthesis translate_on
		end
	    endcase // case (chan_dec)
	 end // always @ (*)

      end // block: gen_dec_chan_decode
   endgenerate


   // AXI address and transaction monitor
   // ---------------------

   //always @( posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
   //always @( posedge S_AXI_ACLK or negedge S_AXI_ARESET)
   always @( posedge S_AXI_ACLK)
     begin
	//if ( S_AXI_ARESETN == 1'b0 )
	if ( S_AXI_ARESET == 1'b0 )
	  begin
	     axi_axaddr_load <= 1'b0;
	     luma_chan_active <= 1'b0;
	     chroma_chan_active <= 1'b0;
	     luma_chan_id <= 3'b100;
	     chroma_chan_id <= 3'b100;
	  end 
	else
	  begin    
	     if ( S_AXI_AWREADY & S_AXI_AWVALID & (|int_en) )
	       begin
		  axi_axaddr_load <= 1'b1;
		  luma_chan_active <= S_AXI_AW_LUMA_CHANID != 3'b100;
		  chroma_chan_active <= S_AXI_AW_CHROMA_CHANID != 3'b100;
		  luma_chan_id <= S_AXI_AW_LUMA_CHANID;
		  chroma_chan_id <= S_AXI_AW_CHROMA_CHANID;
	       end   
	     else
	       begin
		  axi_axaddr_load <= 1'b0;
	       end
	  end 
     end

   //always @( posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
   //always @( posedge S_AXI_ACLK or negedge S_AXI_ARESET)
   always @( posedge S_AXI_ACLK)
     begin
	//if ( S_AXI_ARESETN == 1'b0 )
	if ( S_AXI_ARESET == 1'b0 )
	  begin
	     axi_bresp_ok <= 1'b0;
	     axi_bresp_valid <= 1'b0;
	  end 
	else
	  begin    
	     if (S_AXI_BREADY & S_AXI_BVALID & (|int_en) )
	       begin
		  if (C_DEC_ENC_N == 1) 
		    axi_bresp_valid <= ((S_AXI_BID[2:0] == C_RECONSTRUCTED_FRAME_DETECT) & 
                                        ((|int_luma_frmbuf_addr_valid) | (|int_chroma_frmbuf_addr_valid)));//####
		  else
		    //axi_bresp_valid <= 1'b1;//####
                    axi_bresp_valid <= ((|int_luma_frmbuf_addr_valid) | (|int_chroma_frmbuf_addr_valid));
		  
		  if (S_AXI_BRESP[1:0] == 0)
		    axi_bresp_ok <= 1'b1;
		  else begin
		     //synthesis translate_off
		     $display ("[%m:%0t] ERROR:  BRESP returned with error (%0h)", $time, S_AXI_BRESP);
		     $stop;
		     //synthesis translate_on
		     axi_bresp_ok <= 1'b0;
		  end
	       end   
	     else
	       begin
		  axi_bresp_valid <= 1'b0;
		  axi_bresp_ok <= 1'b0;
	       end
	  end 
     end // always @ ( posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
   
   // axi_axaddr_next = current AWADDR + (AWLEN + 1) << AWSIZE
   always @( posedge S_AXI_ACLK )
     begin
	if (S_AXI_AWREADY & S_AXI_AWVALID & (|int_en))
	  begin
	     axi_axaddr <= S_AXI_AWADDR[C_S_AXI_ADDR_WIDTH - 1:0];
	     axi_axaddr_burst_len <= (axi_axlen+1) << S_AXI_AWSIZE[2:0];
	  end   
	     
	
	if (axi_axaddr_load) begin
	   axi_axaddr_next <= axi_axaddr + axi_axaddr_burst_len;
	end
     end // always @ ( posedge S_AXI_ACLK )



   // Detect AXADDR in range
   // ------------------------
   
   //always @( posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
   //always @( posedge S_AXI_ACLK or negedge S_AXI_ARESET)
   always @( posedge S_AXI_ACLK)
   begin
     //if ( S_AXI_ARESETN == 1'b0 )
     if ( S_AXI_ARESET == 1'b0 )
     begin
       axi_axaddr_luma_inrange <= 1'b0;
       luma_outofrange <= {C_VIDEO_CHAN{1'b0}};
     end 
     else
     begin
       //axi_axaddr_luma_inrange <= 1'b0;
       luma_outofrange[C_VIDEO_CHAN_ID] <= 1'b0;
       if (  (S_AXI_AWREADY & S_AXI_AWVALID)  & (|int_en) )
       begin
         if (S_AXI_AW_LUMA_CHANID != 3'b100)
           axi_axaddr_luma_inrange <= 1'b1;
         else if ((C_DEC_ENC_N == 0) &&
                  (S_AXI_AW_LUMA_CHANID == 3'b100) &&
                  (int_luma_frmbuf_addr_valid[C_VIDEO_CHAN_ID] == 1'b1))  // In encoder case, out-of-range is illegal
           luma_outofrange[C_VIDEO_CHAN_ID] <= 1'b1;
       end 
       else if (~ (|int_en))
       begin
         axi_axaddr_luma_inrange <= 1'b0;
       end
     end 
   end // always @ ( posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
   

   //always @( posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
   //always @( posedge S_AXI_ACLK or negedge S_AXI_ARESET)
   always @( posedge S_AXI_ACLK)
   begin 
     //if ( S_AXI_ARESETN == 1'b0 )
     if ( S_AXI_ARESET == 1'b0 )
     begin
       axi_axaddr_chroma_inrange <= 1'b0;
       chroma_outofrange <= {C_VIDEO_CHAN{1'b0}};
     end 
     else
     begin
       //axi_axaddr_chroma_inrange <= 1'b0;
       chroma_outofrange[C_VIDEO_CHAN_ID] <= 1'b0;
	     
       if ((S_AXI_AWREADY & S_AXI_AWVALID)  & (|int_en) )
       begin
         if (S_AXI_AW_CHROMA_CHANID != 3'b100)
           axi_axaddr_chroma_inrange <= 1'b1;
         else if ((C_DEC_ENC_N == 0) &&
                  (S_AXI_AW_CHROMA_CHANID == 3'b100) &&
                  (int_chroma_frmbuf_addr_valid[C_VIDEO_CHAN_ID] == 1'b1))
           chroma_outofrange[C_VIDEO_CHAN_ID] <= 1'b1;
       end   
       else if (~ (|int_en))
       begin
         axi_axaddr_chroma_inrange <= 1'b0;
       end
     end 
   end // always @ ( posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
   
   always @ (*)
   begin
     outofrange = luma_outofrange[C_VIDEO_CHAN_ID] & chroma_outofrange[C_VIDEO_CHAN_ID];
   end
   
   // Address Monitor FSM
   // -----------------------------------
   
   addr_thres_ctrl #( .C_VIDEO_CHAN (C_VIDEO_CHAN),
		      .C_VIDEO_CHAN_ID (C_VIDEO_CHAN_ID),
		      .C_S_AXI_ADDR_WIDTH (C_S_AXI_ADDR_WIDTH),
		      .C_FRMBUF_ADDR_WIDTH (C_FRMBUF_ADDR_WIDTH),
		      .C_DEC_ENC_N(C_DEC_ENC_N),
		      .C_TIMEOUT (C_TIMEOUT))
   addr_thres_ctrl_luma
     (
      .aclk (S_AXI_ACLK),
      //.aresetn (S_AXI_ARESETN),
      .aresetn (S_AXI_ARESET),
      .en (|int_en),

      .buf_id   (luma_buf_id),
		
      .axi_axaddr_valid (axi_axaddr_load),
      .axi_axaddr_inrange (axi_axaddr_luma_inrange),
      .axi_axaddr (axi_axaddr), // current addr
      .chan_active (luma_chan_active),
      .chan_id (luma_chan_id),

      .axi_axaddr_next_valid (axi_axaddr_load_p),
      .axi_axaddr_next (axi_axaddr_next), // next addr

      .axi_bresp_valid (axi_bresp_valid), //
      .axi_bresp_ok (axi_bresp_ok),

      .int_frmbuf_addr_valid_pulse (int_luma_frmbuf_addr_valid_pulse),
      .int_frmbuf_addr_valid (int_luma_frmbuf_addr_valid),
      .int_frmbuf_addr_margin (int_luma_frmbuf_addr_margin),
      .int_frmbuf_addr_start (int_luma_frmbuf_addr_start),
      .int_frmbuf_addr_end (int_luma_frmbuf_addr_end),
      .c0_frmbuf_addr_end (cons_c0_luma_frmbuf_addr_end), //####
      .c1_frmbuf_addr_end (cons_c1_luma_frmbuf_addr_end), //####
      .c2_frmbuf_addr_end (cons_c2_luma_frmbuf_addr_end), //####
      .c3_frmbuf_addr_end (cons_c3_luma_frmbuf_addr_end), //####

      .frmbuf_addr_next (luma_frmbuf_addr_next),
      .frmbuf_addr_done (luma_frmbuf_addr_done),
      .frmbuf_c0_addr_done (luma_frmbuf_c0_addr_done), //####
      .frmbuf_c1_addr_done (luma_frmbuf_c1_addr_done), //####
      .frmbuf_c2_addr_done (luma_frmbuf_c2_addr_done), //####
      .frmbuf_c3_addr_done (luma_frmbuf_c3_addr_done), //####
      .frmbuf_addr_outthres (luma_frmbuf_addr_outthres),
      .frmbuf_addr_outthres_valid_pulse (luma_frmbuf_addr_outthres_valid_pulse),

      .err_timeout    (luma_timeout)

      );
   
   addr_thres_ctrl #( .C_VIDEO_CHAN (C_VIDEO_CHAN),
		      .C_VIDEO_CHAN_ID (C_VIDEO_CHAN_ID),
		      .C_S_AXI_ADDR_WIDTH (C_S_AXI_ADDR_WIDTH),
		      .C_FRMBUF_ADDR_WIDTH (C_FRMBUF_ADDR_WIDTH),
		      .C_DEC_ENC_N(C_DEC_ENC_N),
		      .C_TIMEOUT (C_TIMEOUT))
   addr_thres_ctrl_chroma
     (
      .aclk (S_AXI_ACLK),
      //.aresetn (S_AXI_ARESETN),
      .aresetn (S_AXI_ARESET),
      .en (|int_en),

      .buf_id (chroma_buf_id),
		
      .axi_axaddr_valid (axi_axaddr_load),
      .axi_axaddr_inrange (axi_axaddr_chroma_inrange),
      .axi_axaddr (axi_axaddr), // current addr
      .chan_active (chroma_chan_active),
      .chan_id (chroma_chan_id),

      .axi_axaddr_next_valid (axi_axaddr_load_p),
      .axi_axaddr_next (axi_axaddr_next), // next addr

      .axi_bresp_valid (axi_bresp_valid), //
      .axi_bresp_ok (axi_bresp_ok),

      .int_frmbuf_addr_valid_pulse (int_chroma_frmbuf_addr_valid_pulse),
      .int_frmbuf_addr_valid (int_chroma_frmbuf_addr_valid),
      .int_frmbuf_addr_margin (int_chroma_frmbuf_addr_margin),
      .int_frmbuf_addr_start (int_chroma_frmbuf_addr_start),
      .int_frmbuf_addr_end (int_chroma_frmbuf_addr_end),
      .c0_frmbuf_addr_end (cons_c0_chroma_frmbuf_addr_end), //####
      .c1_frmbuf_addr_end (cons_c1_chroma_frmbuf_addr_end), //####
      .c2_frmbuf_addr_end (cons_c2_chroma_frmbuf_addr_end), //####
      .c3_frmbuf_addr_end (cons_c3_chroma_frmbuf_addr_end), //####
      
      .frmbuf_addr_next (chroma_frmbuf_addr_next),
      .frmbuf_addr_done (chroma_frmbuf_addr_done),
      .frmbuf_c0_addr_done (chroma_frmbuf_c0_addr_done), //####
      .frmbuf_c1_addr_done (chroma_frmbuf_c1_addr_done), //####
      .frmbuf_c2_addr_done (chroma_frmbuf_c2_addr_done), //####
      .frmbuf_c3_addr_done (chroma_frmbuf_c3_addr_done), //####
      .frmbuf_addr_outthres (chroma_frmbuf_addr_outthres),
      .frmbuf_addr_outthres_valid_pulse (chroma_frmbuf_addr_outthres_valid_pulse),

      .err_timeout (chroma_timeout)

      );
   
endmodule


`timescale 1 ns / 1 ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Xilinx, Inc.
// Engineer: Davy Huang
// 
// Create Date: 04/24/2018 01:24:00 PM
// Design Name: VCU low latency synchronization IP
// Module Name: sync_ip_v1_0_2_S_AXI_MM
// Project Name: VCU low latency 
// Target Devices: Zynq UltraScale+ EV
// Tool Versions: Vivado 2018.1
// Description: 
// Consumer transaction monitor and responder
//  Each AXI port for the consumer handles two encoder cores or one decoder core
//  using one or two separate transaction FIFOs.
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//Shreyas Edit 
/////////////////////////////////ports/////////////////////////////////////////////////

(* DONT_TOUCH = "TRUE" *)
module syn_ip_v1_0_S_AXI_MM #
  (
   // Users to add parameters here
   parameter integer C_VIDEO_CHAN = 4,
   parameter integer C_VIDEO_CHAN_ID = 0, // video channel ID in decode-display case
   parameter integer C_CONSUMER_CHAN = 2, // consumer channel per consumer port: Encoder (2), Decoder(1)
   parameter integer C_DEC_ENC_N = 0, // Encoder (0) or Decoder (1)
   parameter [2:0]   C_SRC_FRAME_DETECT = 3'b000, // for Encoder 
   parameter integer C_FRMBUF_ADDR_WIDTH = 44,
   parameter [23:0]  C_TIMEOUT = 24'h4C4840,
   parameter [31:0]  C_LUMA_LENGTH = 32'h7F8000, //(3840*2160) shreyas
   parameter [31:0]  C_CHROMA_LENGTH = 32'h3FC000,
   parameter integer C_RD_BUF_CNT_WIDTH = 32,
   parameter integer C_BUF_CNT_WIDTH    = 10,
   parameter integer C_BL_WIDTH         = 10,

   // User parameters ends
   // Do not modify the parameters beyond this line
  
   // Width of ID for for write address, write data, read address and read data
   parameter integer C_S_AXI_ID_WIDTH	= 4,
   // Width of S_AXI data bus
   parameter integer C_S_AXI_DATA_WIDTH	= 128,
   // Width of S_AXI address bus
   parameter integer C_S_AXI_ADDR_WIDTH	= 64,
   // Width of optional user defined signal in write address channel
   parameter integer C_S_AXI_AWUSER_WIDTH	= 0,
   // Width of optional user defined signal in read address channel
   parameter integer C_S_AXI_ARUSER_WIDTH	= 0,
   // Width of optional user defined signal in write data channel
   parameter integer C_S_AXI_WUSER_WIDTH	= 0,
   // Width of optional user defined signal in read data channel
   parameter integer C_S_AXI_RUSER_WIDTH	= 0,
   // Width of optional user defined signal in write response channel
   parameter integer C_S_AXI_BUSER_WIDTH	= 0
   )
   (
    // Users to add ports here
   (* DONT_TOUCH = "TRUE" *) input wire [C_VIDEO_CHAN-1:0] S_AXI_SW_ARESET,
   (* DONT_TOUCH = "TRUE" *) input wire [C_VIDEO_CHAN-1:0] buf_rd_cnt_en,
   (* DONT_TOUCH = "TRUE" *) input wire producer_aclk,
   (* DONT_TOUCH = "TRUE" *) input wire producer_aresetn,
   (* DONT_TOUCH = "TRUE" *) input wire [C_VIDEO_CHAN-1:0] prod_luma_frmbuf_addr_done, // flush command from producer
   (* DONT_TOUCH = "TRUE" *) input wire [C_VIDEO_CHAN-1:0] prod_luma_frmbuf_c0_addr_done, // flush command from producer//####
   (* DONT_TOUCH = "TRUE" *) input wire [C_VIDEO_CHAN-1:0] prod_luma_frmbuf_c1_addr_done, // flush command from producer//####
   (* DONT_TOUCH = "TRUE" *) input wire [C_VIDEO_CHAN-1:0] prod_luma_frmbuf_c2_addr_done, // flush command from producer//####
   (* DONT_TOUCH = "TRUE" *) input wire [C_VIDEO_CHAN-1:0] prod_luma_frmbuf_c3_addr_done, // flush command from producer//####
   (* DONT_TOUCH = "TRUE" *) input wire [C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN-1:0] prod_luma_frmbuf_addr_outthres,
   (* DONT_TOUCH = "TRUE" *) input wire [C_VIDEO_CHAN-1:0] prod_luma_frmbuf_addr_outthres_valid_pulse,
   (* DONT_TOUCH = "TRUE" *) input wire [C_VIDEO_CHAN-1:0] prod_chroma_frmbuf_addr_done,
   (* DONT_TOUCH = "TRUE" *) input wire [C_VIDEO_CHAN-1:0] prod_chroma_frmbuf_c0_addr_done,//####
   (* DONT_TOUCH = "TRUE" *) input wire [C_VIDEO_CHAN-1:0] prod_chroma_frmbuf_c1_addr_done,//####
   (* DONT_TOUCH = "TRUE" *) input wire [C_VIDEO_CHAN-1:0] prod_chroma_frmbuf_c2_addr_done,//####
   (* DONT_TOUCH = "TRUE" *) input wire [C_VIDEO_CHAN-1:0] prod_chroma_frmbuf_c3_addr_done,//####
   (* DONT_TOUCH = "TRUE" *) input wire [C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN-1:0] prod_chroma_frmbuf_addr_outthres,
   (* DONT_TOUCH = "TRUE" *) input wire [C_VIDEO_CHAN-1:0] prod_chroma_frmbuf_addr_outthres_valid_pulse,

   (* DONT_TOUCH = "TRUE" *) input wire [2*C_VIDEO_CHAN-1:0] 			  prod_luma_buf_id, //#### Inclusion of Buff id signals to get done_keep for per buffer
   (* DONT_TOUCH = "TRUE" *) input wire [2*C_VIDEO_CHAN-1:0] 			  prod_chroma_buf_id,
   (* DONT_TOUCH = "TRUE" *) input wire [2*C_VIDEO_CHAN-1:0] 			  cons_luma_buf_id,
   (* DONT_TOUCH = "TRUE" *) input wire [2*C_VIDEO_CHAN-1:0] 			  cons_chroma_buf_id,
   
   (* DONT_TOUCH = "TRUE" *) input wire  ctrl_aclk,
   (* DONT_TOUCH = "TRUE" *) input wire  ctrl_aresetn,
   (* DONT_TOUCH = "TRUE" *) input wire 	[C_VIDEO_CHAN-1:0] en,
   (* DONT_TOUCH = "TRUE" *) input wire [C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN-1:0] luma_frmbuf_start_addr,
   (* DONT_TOUCH = "TRUE" *) input wire [C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN-1:0] luma_frmbuf_end_addr,
   (* DONT_TOUCH = "TRUE" *) input wire [C_VIDEO_CHAN-1:0]    luma_frmbuf_addr_valid_pulse,
   (* DONT_TOUCH = "TRUE" *) input wire [C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN-1:0] chroma_frmbuf_start_addr,
   (* DONT_TOUCH = "TRUE" *) input wire [C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN-1:0] chroma_frmbuf_end_addr,
   (* DONT_TOUCH = "TRUE" *) input wire [C_VIDEO_CHAN-1:0]    chroma_frmbuf_addr_valid_pulse,


    // in consumer clock domain
   (* DONT_TOUCH = "TRUE" *) input wire [C_VIDEO_CHAN*C_RD_BUF_CNT_WIDTH-1:0] cons_luma_buf_rd_cnt_in,
   (* DONT_TOUCH = "TRUE" *) input wire [C_VIDEO_CHAN*C_RD_BUF_CNT_WIDTH-1:0] cons_chroma_buf_rd_cnt_in,
   (* DONT_TOUCH = "TRUE" *) output reg [C_VIDEO_CHAN*C_RD_BUF_CNT_WIDTH-1:0] cons_luma_buf_rd_cnt_out,
   (* DONT_TOUCH = "TRUE" *) output reg [C_VIDEO_CHAN*C_RD_BUF_CNT_WIDTH-1:0] cons_chroma_buf_rd_cnt_out,
   (* DONT_TOUCH = "TRUE" *) input wire [C_VIDEO_CHAN-1:0] cons_luma_frmbuf_addr_done_in,
   (* DONT_TOUCH = "TRUE" *) input wire [C_VIDEO_CHAN-1:0] cons_chroma_frmbuf_addr_done_in,
  (* DONT_TOUCH = "TRUE" *)  output reg [C_VIDEO_CHAN-1:0]   luma_frmbuf_addr_next,
  (* DONT_TOUCH = "TRUE" *)  output wire [C_VIDEO_CHAN-1:0]   luma_frmbuf_addr_done,
  (* DONT_TOUCH = "TRUE" *)  output reg [C_VIDEO_CHAN-1:0]   chroma_frmbuf_addr_next,
  (* DONT_TOUCH = "TRUE" *)  output wire [C_VIDEO_CHAN-1:0]   chroma_frmbuf_addr_done,

    //Error conditions
  (* DONT_TOUCH = "TRUE" *)  output wire [C_VIDEO_CHAN-1:0]    luma_outofrange,
  (* DONT_TOUCH = "TRUE" *)  output wire [C_VIDEO_CHAN-1:0]    chroma_outofrange,
  (* DONT_TOUCH = "TRUE" *)  output reg [C_VIDEO_CHAN-1:0]    luma_timeout,
  (* DONT_TOUCH = "TRUE" *)  output reg [C_VIDEO_CHAN-1:0]    chroma_timeout,
    
  (* DONT_TOUCH = "TRUE" *)  output wire [3:0] m_axi_arid,
  (* DONT_TOUCH = "TRUE" *)  output wire [63:0] m_axi_araddr,
  (* DONT_TOUCH = "TRUE" *)  output wire [7:0] m_axi_arlen,
  (* DONT_TOUCH = "TRUE" *)  output wire [2:0] m_axi_arsize,
  (* DONT_TOUCH = "TRUE" *)  output wire [1:0] m_axi_arburst,
  (* DONT_TOUCH = "TRUE" *)  output wire [0:0] m_axi_arlock,
  (* DONT_TOUCH = "TRUE" *)  output wire [3:0] m_axi_arcache,
  (* DONT_TOUCH = "TRUE" *)  output wire [2:0] m_axi_arprot,
 (* DONT_TOUCH = "TRUE" *)   output wire [3:0] m_axi_arregion,
  (* DONT_TOUCH = "TRUE" *)  output wire [3:0] m_axi_arqos,
  (* DONT_TOUCH = "TRUE" *)  output wire       m_axi_arvalid,
  (* DONT_TOUCH = "TRUE" *)  input wire 	      m_axi_arready,
  (* DONT_TOUCH = "TRUE" *)  input wire [3:0]  m_axi_rid,
  (* DONT_TOUCH = "TRUE" *)  input wire [127:0] m_axi_rdata,
  (* DONT_TOUCH = "TRUE" *)  input wire [1:0]  m_axi_rresp,
  (* DONT_TOUCH = "TRUE" *)  input wire 	      m_axi_rlast,
  (* DONT_TOUCH = "TRUE" *)  input wire 	      m_axi_rvalid,
  (* DONT_TOUCH = "TRUE" *)  output wire       m_axi_rready,
   
  (* DONT_TOUCH = "TRUE" *)  output wire [3:0] m_axi_awid,
  (* DONT_TOUCH = "TRUE" *)  output wire [63:0] m_axi_awaddr,
  (* DONT_TOUCH = "TRUE" *)  output wire [7:0] m_axi_awlen,
  (* DONT_TOUCH = "TRUE" *)  output wire [2:0] m_axi_awsize,
  (* DONT_TOUCH = "TRUE" *)  output wire [1:0] m_axi_awburst,
  (* DONT_TOUCH = "TRUE" *)  output wire       m_axi_awlock,
  (* DONT_TOUCH = "TRUE" *)  output wire [3:0] m_axi_awcache,
  (* DONT_TOUCH = "TRUE" *)  output wire [2:0] m_axi_awprot,
  (* DONT_TOUCH = "TRUE" *)  output wire [3:0] m_axi_awregion,
  (* DONT_TOUCH = "TRUE" *)  output wire [3:0] m_axi_awqos,
  (* DONT_TOUCH = "TRUE" *)  output wire       m_axi_awvalid,
  (* DONT_TOUCH = "TRUE" *)  input wire        m_axi_awready,
  (* DONT_TOUCH = "TRUE" *)  output wire [127:0] m_axi_wdata,
  (* DONT_TOUCH = "TRUE" *) output wire [15:0] m_axi_wstrb,
  (* DONT_TOUCH = "TRUE" *)  output wire       m_axi_wlast,
  (* DONT_TOUCH = "TRUE" *)  output wire       m_axi_wvalid,
  (* DONT_TOUCH = "TRUE" *)  input wire        m_axi_wready,
  (* DONT_TOUCH = "TRUE" *)  input wire [3:0]  m_axi_bid,
  (* DONT_TOUCH = "TRUE" *) input wire [1:0]  m_axi_bresp,
  (* DONT_TOUCH = "TRUE" *)  input wire        m_axi_bvalid,
  (* DONT_TOUCH = "TRUE" *)  output wire       m_axi_bready,

  (* DONT_TOUCH = "TRUE" *)  input wire [31:0]  luma_c0_offset,
  (* DONT_TOUCH = "TRUE" *)  input wire [31:0]  luma_c1_offset,
  (* DONT_TOUCH = "TRUE" *)  input wire [31:0]  luma_c2_offset,
  (* DONT_TOUCH = "TRUE" *)  input wire [31:0]  luma_c3_offset,
  (* DONT_TOUCH = "TRUE" *)  input wire [31:0]  chroma_c0_offset,
  (* DONT_TOUCH = "TRUE" *)  input wire [31:0]  chroma_c1_offset,
  (* DONT_TOUCH = "TRUE" *)  input wire [31:0]  chroma_c2_offset,
  (* DONT_TOUCH = "TRUE" *)  input wire [31:0]  chroma_c3_offset,



    // User ports ends
    // Do not modify the ports beyond this line

    // Global Clock Signal
  (* DONT_TOUCH = "TRUE" *)  input wire  S_AXI_ACLK,
    // Global Reset Signal. This Signal is Active LOW
  (* DONT_TOUCH = "TRUE" *)  input wire  S_AXI_ARESETN,
    // Write Address ID
  (* DONT_TOUCH = "TRUE" *)  input wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_AWID,
    // Write address
  (* DONT_TOUCH = "TRUE" *)  input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    // Burst length. The burst length gives the exact number of transfers in a burst
  (* DONT_TOUCH = "TRUE" *)  input wire [7 : 0] S_AXI_AWLEN,
    // Burst size. This signal indicates the size of each transfer in the burst
  (* DONT_TOUCH = "TRUE" *)  input wire [2 : 0] S_AXI_AWSIZE,
    // Burst type. The burst type and the size information, 
    // determine how the address for each transfer within the burst is calculated.
  (* DONT_TOUCH = "TRUE" *)  input wire [1 : 0] S_AXI_AWBURST,
    // Lock type. Provides additional information about the
    // atomic characteristics of the transfer.
  (* DONT_TOUCH = "TRUE" *)  input wire  S_AXI_AWLOCK,
    // Memory type. This signal indicates how transactions
    // are required to progress through a system.
  (* DONT_TOUCH = "TRUE" *)  input wire [3 : 0] S_AXI_AWCACHE,
    // Protection type. This signal indicates the privilege
    // and security level of the transaction, and whether
    // the transaction is a data access or an instruction access.
  (* DONT_TOUCH = "TRUE" *)  input wire [2 : 0] S_AXI_AWPROT,
    // Quality of Service, QoS identifier sent for each
    // write transaction.
  (* DONT_TOUCH = "TRUE" *)  input wire [3 : 0] S_AXI_AWQOS,
    // Region identifier. Permits a single physical interface
    // on a slave to be used for multiple logical interfaces.
  (* DONT_TOUCH = "TRUE" *)  input wire [3 : 0] S_AXI_AWREGION,
    // Optional User-defined signal in the write address channel.
  (* DONT_TOUCH = "TRUE" *)  input wire [C_S_AXI_AWUSER_WIDTH-1 : 0] S_AXI_AWUSER,
    // Write address valid. This signal indicates that
    // the channel is signaling valid write address and
    // control information.
  (* DONT_TOUCH = "TRUE" *)  input wire  S_AXI_AWVALID,
    // Write address ready. This signal indicates that
    // the slave is ready to accept an address and associated
    // control signals.
 (* DONT_TOUCH = "TRUE" *)   output wire  S_AXI_AWREADY,
    // Write Data
  (* DONT_TOUCH = "TRUE" *)  input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    // Write strobes. This signal indicates which byte
    // lanes hold valid data. There is one write strobe
    // bit for each eight bits of the write data bus.
  (* DONT_TOUCH = "TRUE" *)  input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    // Write last. This signal indicates the last transfer
    // in a write burst.
  (* DONT_TOUCH = "TRUE" *)  input wire  S_AXI_WLAST,
    // Optional User-defined signal in the write data channel.
  (* DONT_TOUCH = "TRUE" *)  input wire [C_S_AXI_WUSER_WIDTH-1 : 0] S_AXI_WUSER,
    // Write valid. This signal indicates that valid write
    // data and strobes are available.
  (* DONT_TOUCH = "TRUE" *)  input wire  S_AXI_WVALID,
    // Write ready. This signal indicates that the slave
    // can accept the write data.
  (* DONT_TOUCH = "TRUE" *)  output wire  S_AXI_WREADY,
    // Response ID tag. This signal is the ID tag of the
    // write response.
  (* DONT_TOUCH = "TRUE" *)  output wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_BID,
    // Write response. This signal indicates the status
    // of the write transaction.
  (* DONT_TOUCH = "TRUE" *)  output wire [1 : 0] S_AXI_BRESP,
    // Optional User-defined signal in the write response channel.
  (* DONT_TOUCH = "TRUE" *)  output wire [C_S_AXI_BUSER_WIDTH-1 : 0] S_AXI_BUSER,
    // Write response valid. This signal indicates that the
    // channel is signaling a valid write response.
  (* DONT_TOUCH = "TRUE" *)  output wire  S_AXI_BVALID,
    // Response ready. This signal indicates that the master
    // can accept a write response.
  (* DONT_TOUCH = "TRUE" *)  input wire  S_AXI_BREADY,
    // Read address ID. This signal is the identification
    // tag for the read address group of signals.
  (* DONT_TOUCH = "TRUE" *)  input wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_ARID,
    // Read address. This signal indicates the initial
    // address of a read burst transaction.
  (* DONT_TOUCH = "TRUE" *)  input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    // Burst length. The burst length gives the exact number of transfers in a burst
  (* DONT_TOUCH = "TRUE" *)  input wire [7 : 0] S_AXI_ARLEN,
    // Burst size. This signal indicates the size of each transfer in the burst
  (* DONT_TOUCH = "TRUE" *)  input wire [2 : 0] S_AXI_ARSIZE,
    // Burst type. The burst type and the size information, 
    // determine how the address for each transfer within the burst is calculated.
  (* DONT_TOUCH = "TRUE" *)  input wire [1 : 0] S_AXI_ARBURST,
    // Lock type. Provides additional information about the
    // atomic characteristics of the transfer.
  (* DONT_TOUCH = "TRUE" *)  input wire  S_AXI_ARLOCK,
    // Memory type. This signal indicates how transactions
    // are required to progress through a system.
  (* DONT_TOUCH = "TRUE" *)  input wire [3 : 0] S_AXI_ARCACHE,
    // Protection type. This signal indicates the privilege
    // and security level of the transaction, and whether
    // the transaction is a data access or an instruction access.
  (* DONT_TOUCH = "TRUE" *)  input wire [2 : 0] S_AXI_ARPROT,
    // Quality of Service, QoS identifier sent for each
    // read transaction.
  (* DONT_TOUCH = "TRUE" *)  input wire [3 : 0] S_AXI_ARQOS,
    // Region identifier. Permits a single physical interface
    // on a slave to be used for multiple logical interfaces.
  (* DONT_TOUCH = "TRUE" *)  input wire [3 : 0] S_AXI_ARREGION,
    // Optional User-defined signal in the read address channel.
  (* DONT_TOUCH = "TRUE" *)  input wire [C_S_AXI_ARUSER_WIDTH-1 : 0] S_AXI_ARUSER,
    // Write address valid. This signal indicates that
    // the channel is signaling valid read address and
    // control information.
  (* DONT_TOUCH = "TRUE" *)  input wire  S_AXI_ARVALID,
    // Read address ready. This signal indicates that
    // the slave is ready to accept an address and associated
    // control signals.
  (* DONT_TOUCH = "TRUE" *)  output wire  S_AXI_ARREADY,
    // Read ID tag. This signal is the identification tag
    // for the read data group of signals generated by the slave.
  (* DONT_TOUCH = "TRUE" *)  output wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_RID,
    // Read Data
  (* DONT_TOUCH = "TRUE" *)  output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    // Read response. This signal indicates the status of
    // the read transfer.
  (* DONT_TOUCH = "TRUE" *)  output wire [1 : 0] S_AXI_RRESP,
    // Read last. This signal indicates the last transfer
    // in a read burst.
  (* DONT_TOUCH = "TRUE" *)  output wire  S_AXI_RLAST,
    // Optional User-defined signal in the read address channel.
  (* DONT_TOUCH = "TRUE" *)  output wire [C_S_AXI_RUSER_WIDTH-1 : 0] S_AXI_RUSER,
    // Read valid. This signal indicates that the channel
    // is signaling the required read data.
  (* DONT_TOUCH = "TRUE" *)  output wire  S_AXI_RVALID,
    // Read ready. This signal indicates that the master can
    // accept the read data and response information.
  (* DONT_TOUCH = "TRUE" *)  input wire  S_AXI_RREADY
    );

  localparam integer XPM_FIFO_DWIDTH = (C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN) +  //Outthreshold 
                                       (C_VIDEO_CHAN*2) +                    //Bufid
                                       (C_VIDEO_CHAN*2) +                    //Producer Frame done + outthreshold valid
                                       (C_VIDEO_CHAN*4) ;                    //Producer luma cores done 

   // Declaration
   // -----------------------------------
 (* DONT_TOUCH = "TRUE" *)  wire [3:0] 	s_axi_arid_0;
 (* DONT_TOUCH = "TRUE" *)  wire [63:0]	s_axi_araddr_0;
 (* DONT_TOUCH = "TRUE" *)  wire [7:0] 	s_axi_arlen_0;
 (* DONT_TOUCH = "TRUE" *)  wire [2:0] 	s_axi_arsize_0;
 (* DONT_TOUCH = "TRUE" *)  wire [1:0] 	s_axi_arburst_0;
 (* DONT_TOUCH = "TRUE" *)  wire [0:0] 	s_axi_arlock_0;
 (* DONT_TOUCH = "TRUE" *)  wire [3:0] 	s_axi_arcache_0;
 (* DONT_TOUCH = "TRUE" *)  wire [2:0] 	s_axi_arprot_0;
 (* DONT_TOUCH = "TRUE" *)  wire [3:0] 	s_axi_arqos_0;
 (* DONT_TOUCH = "TRUE" *)  wire [5:0] 	s_axi_aruser_0;
 (* DONT_TOUCH = "TRUE" *)  wire [3:0] 	s_axi_arregion_0;
 (* DONT_TOUCH = "TRUE" *)  wire [0:0] 	s_axi_arvalid_0;
 (* DONT_TOUCH = "TRUE" *)  wire [0:0] 	s_axi_arready_0;


 (* DONT_TOUCH = "TRUE" *)  wire [3:0] 	s_axi_arid_1;
 (* DONT_TOUCH = "TRUE" *)  wire [63:0]	s_axi_araddr_1;
 (* DONT_TOUCH = "TRUE" *)  wire [7:0] 	s_axi_arlen_1;
 (* DONT_TOUCH = "TRUE" *)  wire [2:0] 	s_axi_arsize_1;
 (* DONT_TOUCH = "TRUE" *)  wire [1:0] 	s_axi_arburst_1;
 (* DONT_TOUCH = "TRUE" *)  wire [0:0] 	s_axi_arlock_1;
 (* DONT_TOUCH = "TRUE" *)  wire [3:0] 	s_axi_arcache_1;
 (* DONT_TOUCH = "TRUE" *)  wire [2:0] 	s_axi_arprot_1;
 (* DONT_TOUCH = "TRUE" *)  wire [3:0] 	s_axi_arqos_1;
 (* DONT_TOUCH = "TRUE" *)  wire [5:0] 	s_axi_aruser_1;
 (* DONT_TOUCH = "TRUE" *)  wire [3:0] 	s_axi_arregion_1;
 (* DONT_TOUCH = "TRUE" *)  wire [0:0] 	s_axi_arvalid_1;
 (* DONT_TOUCH = "TRUE" *)  wire [0:0] 	s_axi_arready_1;

 (* DONT_TOUCH = "TRUE" *)  wire [3:0] 	f1_s_axi_arid_1;
 (* DONT_TOUCH = "TRUE" *)  wire [63:0]	f1_s_axi_araddr_1;
 (* DONT_TOUCH = "TRUE" *)  wire [7:0] 	f1_s_axi_arlen_1;
 (* DONT_TOUCH = "TRUE" *)  wire [2:0] 	f1_s_axi_arsize_1;
 (* DONT_TOUCH = "TRUE" *)  wire [1:0] 	f1_s_axi_arburst_1;
 (* DONT_TOUCH = "TRUE" *)  wire [0:0] 	f1_s_axi_arlock_1;
 (* DONT_TOUCH = "TRUE" *)  wire [3:0] 	f1_s_axi_arcache_1;
 (* DONT_TOUCH = "TRUE" *)  wire [2:0] 	f1_s_axi_arprot_1;
 (* DONT_TOUCH = "TRUE" *)  wire [3:0] 	f1_s_axi_arqos_1;
 (* DONT_TOUCH = "TRUE" *)  wire [49:0] f1_s_axi_aruser_1;
 (* DONT_TOUCH = "TRUE" *)  wire [3:0] 	f1_s_axi_arregion_1;
 (* DONT_TOUCH = "TRUE" *)  wire [0:0] 	f1_s_axi_arvalid_1;
 (* DONT_TOUCH = "TRUE" *)  wire [0:0] 	f1_s_axi_arready_1;

 (* DONT_TOUCH = "TRUE" *)  wire [3:0] 	s_axi_arid_2;
 (* DONT_TOUCH = "TRUE" *)  wire [63:0]	s_axi_araddr_2;
 (* DONT_TOUCH = "TRUE" *)  wire [7:0] 	s_axi_arlen_2;
 (* DONT_TOUCH = "TRUE" *)  wire [2:0] 	s_axi_arsize_2;
 (* DONT_TOUCH = "TRUE" *)  wire [1:0] 	s_axi_arburst_2;
 (* DONT_TOUCH = "TRUE" *)  wire [0:0] 	s_axi_arlock_2;
 (* DONT_TOUCH = "TRUE" *)  wire [3:0] 	s_axi_arcache_2;
 (* DONT_TOUCH = "TRUE" *)  wire [2:0] 	s_axi_arprot_2;
 (* DONT_TOUCH = "TRUE" *)  wire [3:0] 	s_axi_arqos_2;
 (* DONT_TOUCH = "TRUE" *)  wire [5:0] 	s_axi_aruser_2;
 (* DONT_TOUCH = "TRUE" *)  wire [3:0] 	s_axi_arregion_2;
 (* DONT_TOUCH = "TRUE" *)  wire [0:0] 	s_axi_arvalid_2;
 (* DONT_TOUCH = "TRUE" *)  wire [0:0] 	s_axi_arready_2;

 (* DONT_TOUCH = "TRUE" *)  wire [3:0] 	f2_s_axi_arid_2;
 (* DONT_TOUCH = "TRUE" *)  wire [63:0]	f2_s_axi_araddr_2;
 (* DONT_TOUCH = "TRUE" *)  wire [7:0] 	f2_s_axi_arlen_2;
 (* DONT_TOUCH = "TRUE" *)  wire [2:0] 	f2_s_axi_arsize_2;
 (* DONT_TOUCH = "TRUE" *)  wire [1:0] 	f2_s_axi_arburst_2;
 (* DONT_TOUCH = "TRUE" *)  wire [0:0] 	f2_s_axi_arlock_2;
 (* DONT_TOUCH = "TRUE" *)  wire [3:0] 	f2_s_axi_arcache_2;
 (* DONT_TOUCH = "TRUE" *)  wire [2:0] 	f2_s_axi_arprot_2;
 (* DONT_TOUCH = "TRUE" *)  wire [3:0] 	f2_s_axi_arqos_2;
 (* DONT_TOUCH = "TRUE" *)  wire [49:0]	f2_s_axi_aruser_2;
 (* DONT_TOUCH = "TRUE" *)  wire [3:0] 	f2_s_axi_arregion_2;
 (* DONT_TOUCH = "TRUE" *)  wire [0:0] 	f2_s_axi_arvalid_2;
 (* DONT_TOUCH = "TRUE" *)  wire [0:0] 	f2_s_axi_arready_2;



   //output of stream 0 (REG_SLICE)
 (* DONT_TOUCH = "TRUE" *)  wire s_axis_tvalid_0;
 (* DONT_TOUCH = "TRUE" *)  wire s_axis_tready_0;
 (* DONT_TOUCH = "TRUE" *)  wire [63:0] s_tdata_0;
 (* DONT_TOUCH = "TRUE" *)  wire [7:0] s_axis_tkeep_0;
 (* DONT_TOUCH = "TRUE" *)  wire s_axis_tlast_0;
 (* DONT_TOUCH = "TRUE" *)  wire [2:0] s_axis_tid_0;

   //Output of stream 1 (FIFO 1)
 (* DONT_TOUCH = "TRUE" *)  wire s_axis_tvalid_1;
 (* DONT_TOUCH = "TRUE" *)  wire s_axis_tready_1;
 (* DONT_TOUCH = "TRUE" *)  wire [63:0] s_tdata_1;
 (* DONT_TOUCH = "TRUE" *)  wire [7:0] s_axis_tkeep_1;
 (* DONT_TOUCH = "TRUE" *)  wire s_axis_tlast_1;
 (* DONT_TOUCH = "TRUE" *)  wire [2:0] s_axis_tid_1;

   //output of stream 2 (FIFO 2)
 (* DONT_TOUCH = "TRUE" *)  wire s_axis_tvalid_2;
 (* DONT_TOUCH = "TRUE" *)  wire s_axis_tready_2;
 (* DONT_TOUCH = "TRUE" *)   wire [63:0] s_tdata_2;
 (* DONT_TOUCH = "TRUE" *)  wire [7:0] s_axis_tkeep_2;
 (* DONT_TOUCH = "TRUE" *)  wire s_axis_tlast_2;
 (* DONT_TOUCH = "TRUE" *)  wire [2:0] s_axis_tid_2;

 (* DONT_TOUCH = "TRUE" *)  wire m_axis_tvalid;
 (* DONT_TOUCH = "TRUE" *)  wire m_axis_tready;
 (* DONT_TOUCH = "TRUE" *)  wire [63:0] m_axis_tdata;
 (* DONT_TOUCH = "TRUE" *)  wire [7:0] m_axis_tkeep;
 (* DONT_TOUCH = "TRUE" *)  wire m_axis_tlast;
 (* DONT_TOUCH = "TRUE" *)  wire [2:0] m_axis_tid;

   
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] luma_frmbuf_addr_done_i;
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] chroma_frmbuf_addr_done_i;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] luma_frmbuf_addr_done_p;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] chroma_frmbuf_addr_done_p;
   

 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_luma_frmbuf_addr_done;
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_luma_frmbuf_c0_addr_done;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_luma_frmbuf_c1_addr_done;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_luma_frmbuf_c2_addr_done;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_luma_frmbuf_c3_addr_done;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_luma_frmbuf_addr_done_buf0;
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_luma_frmbuf_c0_addr_done_buf0;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_luma_frmbuf_c1_addr_done_buf0;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_luma_frmbuf_c2_addr_done_buf0;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_luma_frmbuf_c3_addr_done_buf0;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_luma_frmbuf_addr_done_buf1;
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_luma_frmbuf_c0_addr_done_buf1;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_luma_frmbuf_c1_addr_done_buf1;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_luma_frmbuf_c2_addr_done_buf1;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_luma_frmbuf_c3_addr_done_buf1;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_luma_frmbuf_addr_done_buf2;
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_luma_frmbuf_c0_addr_done_buf2;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_luma_frmbuf_c1_addr_done_buf2;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_luma_frmbuf_c2_addr_done_buf2;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_luma_frmbuf_c3_addr_done_buf2;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_luma_frmbuf_c0_addr_done_w;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_luma_frmbuf_c1_addr_done_w;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_luma_frmbuf_c2_addr_done_w;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_luma_frmbuf_c3_addr_done_w;//####
 (* DONT_TOUCH = "TRUE" *)  reg  [C_VIDEO_CHAN-1:0] int_prod_luma_frmbuf_c0_addr_done_rg;//####
 (* DONT_TOUCH = "TRUE" *)  reg  [C_VIDEO_CHAN-1:0] int_prod_luma_frmbuf_c1_addr_done_rg;//####
 (* DONT_TOUCH = "TRUE" *)  reg  [C_VIDEO_CHAN-1:0] int_prod_luma_frmbuf_c2_addr_done_rg;//####
 (* DONT_TOUCH = "TRUE" *)  reg  [C_VIDEO_CHAN-1:0] int_prod_luma_frmbuf_c3_addr_done_rg;//####
   (* ASYNC_REG = "true" *) reg [C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN-1:0] i_prod_luma_frmbuf_addr_outthres;
 (* DONT_TOUCH = "TRUE" *)  reg [C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN-1:0] int_prod_luma_frmbuf_addr_outthres;
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] 		      i_prod_luma_frmbuf_addr_outthres_valid_pulse;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 		      int_prod_luma_frmbuf_addr_outthres_valid;
   
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_chroma_frmbuf_addr_done;
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_chroma_frmbuf_c0_addr_done;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_chroma_frmbuf_c1_addr_done;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_chroma_frmbuf_c2_addr_done;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_chroma_frmbuf_c3_addr_done;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_chroma_frmbuf_c0_addr_done_w;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_chroma_frmbuf_c1_addr_done_w;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_chroma_frmbuf_c2_addr_done_w;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_chroma_frmbuf_c3_addr_done_w;//####
 (* DONT_TOUCH = "TRUE" *)  reg  [C_VIDEO_CHAN-1:0] int_prod_chroma_frmbuf_c0_addr_done_rg;//####
 (* DONT_TOUCH = "TRUE" *)  reg  [C_VIDEO_CHAN-1:0] int_prod_chroma_frmbuf_c1_addr_done_rg;//####
 (* DONT_TOUCH = "TRUE" *)  reg  [C_VIDEO_CHAN-1:0] int_prod_chroma_frmbuf_c2_addr_done_rg;//####
 (* DONT_TOUCH = "TRUE" *)  reg  [C_VIDEO_CHAN-1:0] int_prod_chroma_frmbuf_c3_addr_done_rg;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_chroma_frmbuf_addr_done_buf0;
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_chroma_frmbuf_c0_addr_done_buf0;//#### 
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_chroma_frmbuf_c1_addr_done_buf0;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_chroma_frmbuf_c2_addr_done_buf0;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_chroma_frmbuf_c3_addr_done_buf0;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_chroma_frmbuf_addr_done_buf1;
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_chroma_frmbuf_c0_addr_done_buf1;//#### 
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_chroma_frmbuf_c1_addr_done_buf1;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_chroma_frmbuf_c2_addr_done_buf1;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_chroma_frmbuf_c3_addr_done_buf1;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_chroma_frmbuf_addr_done_buf2;
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_chroma_frmbuf_c0_addr_done_buf2;//#### 
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_chroma_frmbuf_c1_addr_done_buf2;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_chroma_frmbuf_c2_addr_done_buf2;//####
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_prod_chroma_frmbuf_c3_addr_done_buf2;//####
   (* ASYNC_REG = "true" *) reg [C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN-1:0] i_prod_chroma_frmbuf_addr_outthres;
 (* DONT_TOUCH = "TRUE" *)  reg [C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN-1:0] int_prod_chroma_frmbuf_addr_outthres;
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] 		      i_prod_chroma_frmbuf_addr_outthres_valid_pulse;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 		      int_prod_chroma_frmbuf_addr_outthres_valid;
 
   
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_en;
   (* ASYNC_REG = "true" *)  reg  [C_FRMBUF_ADDR_WIDTH-1:0] i_luma_frmbuf_start_addr  [0:C_VIDEO_CHAN-1];
   (* ASYNC_REG = "true" *)  reg  [C_FRMBUF_ADDR_WIDTH-1:0] i_luma_frmbuf_end_addr    [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  reg [C_FRMBUF_ADDR_WIDTH-1:0] int_luma_frmbuf_start_addr  [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  reg [C_FRMBUF_ADDR_WIDTH-1:0] int_luma_frmbuf_end_addr    [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  wire[C_FRMBUF_ADDR_WIDTH-1:0] calc_luma_frmbuf_end_addr_1 [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  wire[C_FRMBUF_ADDR_WIDTH-1:0] calc_luma_frmbuf_end_addr_2 [0:C_VIDEO_CHAN-1];

   (* ASYNC_REG = "true" *)  reg  [C_FRMBUF_ADDR_WIDTH-1:0] i_chroma_frmbuf_start_addr  [0:C_VIDEO_CHAN-1];
   (* ASYNC_REG = "true" *)  reg  [C_FRMBUF_ADDR_WIDTH-1:0] i_chroma_frmbuf_end_addr    [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  reg [C_FRMBUF_ADDR_WIDTH-1:0] int_chroma_frmbuf_start_addr  [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  reg [C_FRMBUF_ADDR_WIDTH-1:0] int_chroma_frmbuf_end_addr    [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  wire[C_FRMBUF_ADDR_WIDTH-1:0] calc_chroma_frmbuf_end_addr_1 [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  wire[C_FRMBUF_ADDR_WIDTH-1:0] calc_chroma_frmbuf_end_addr_2 [0:C_VIDEO_CHAN-1];
   
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0]   i_luma_frmbuf_addr_valid_pulse;
 (* DONT_TOUCH = "TRUE" *)  reg  [C_VIDEO_CHAN-1:0]   i_luma_frmbuf_addr_valid_pulse_rg;
 (* DONT_TOUCH = "TRUE" *)  reg  [C_VIDEO_CHAN-1:0]   int_luma_frmbuf_addr_valid;
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0]   i_chroma_frmbuf_addr_valid_pulse;
 (* DONT_TOUCH = "TRUE" *)  reg  [C_VIDEO_CHAN-1:0]   i_chroma_frmbuf_addr_valid_pulse_rg;
 (* DONT_TOUCH = "TRUE" *)  reg  [C_VIDEO_CHAN-1:0]   int_chroma_frmbuf_addr_valid;

   
 (* DONT_TOUCH = "TRUE" *)  wire 		   S_AXI_ARREADY_0, S_AXI_ARREADY_1, S_AXI_ARREADY_2;
 (* DONT_TOUCH = "TRUE" *)  reg 			   read_en_0, fifo_read_en_1, fifo_read_en_2;
 (* DONT_TOUCH = "TRUE" *)  reg 			   fifo_read_en_1_rg, fifo_read_en_2_rg;
 (* DONT_TOUCH = "TRUE" *)  reg 			   idle_insert_0, idle_insert_1, idle_insert_2;

 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0]  luma_frmbuf_addr_done_0;
  (* DONT_TOUCH = "TRUE" *) reg [C_VIDEO_CHAN-1:0]  luma_frmbuf_addr_done_1;
  (* DONT_TOUCH = "TRUE" *) reg [C_VIDEO_CHAN-1:0]  luma_frmbuf_addr_done_1_new;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0]  luma_frmbuf_addr_done_2;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0]  luma_frmbuf_addr_done_2_new;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0]  chroma_frmbuf_addr_done_0;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0]  chroma_frmbuf_addr_done_1;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0]  chroma_frmbuf_addr_done_1_new; 
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0]  chroma_frmbuf_addr_done_2;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0]  chroma_frmbuf_addr_done_2_new;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0]  int_luma_frmbuf_addr_done_0;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0]  int_luma_frmbuf_addr_done_1;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0]  int_luma_frmbuf_addr_done_2;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0]  int_chroma_frmbuf_addr_done_0;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0]  int_chroma_frmbuf_addr_done_1;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0]  int_chroma_frmbuf_addr_done_2;
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0]  int_luma_frmbuf_addr_done_1_buf0;
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0]  int_luma_frmbuf_addr_done_2_buf0;
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0]  int_chroma_frmbuf_addr_done_1_buf0;
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0]  int_chroma_frmbuf_addr_done_2_buf0;
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0]  int_luma_frmbuf_addr_done_1_buf1;
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0]  int_luma_frmbuf_addr_done_2_buf1;
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0]  int_chroma_frmbuf_addr_done_1_buf1;
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0]  int_chroma_frmbuf_addr_done_2_buf1;
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0]  int_luma_frmbuf_addr_done_1_buf2;
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0]  int_luma_frmbuf_addr_done_2_buf2;
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0]  int_chroma_frmbuf_addr_done_1_buf2;
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0]  int_chroma_frmbuf_addr_done_2_buf2;
   
 (* DONT_TOUCH = "TRUE" *)  reg [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR_r;
 (* DONT_TOUCH = "TRUE" *)  reg 				S_AXI_ARVALID_r;
 (* DONT_TOUCH = "TRUE" *)  reg                          S_AXI_ARREADY_0_r;
 (* DONT_TOUCH = "TRUE" *)  reg                          S_AXI_ARREADY_1_r;
 (* DONT_TOUCH = "TRUE" *)  reg                          S_AXI_ARREADY_2_r;
 (* DONT_TOUCH = "TRUE" *)  reg [2:0] 			S_AXI_AR_LUMA_CHANID_0_r;
 (* DONT_TOUCH = "TRUE" *)  reg [2:0] 			S_AXI_AR_LUMA_CHANID_1_r;
 (* DONT_TOUCH = "TRUE" *)  reg [2:0] 			S_AXI_AR_LUMA_CHANID_2_r;
 (* DONT_TOUCH = "TRUE" *)  reg [2:0] 			S_AXI_AR_LUMA_CHANID;

  (* DONT_TOUCH = "TRUE" *) reg [2:0] 			S_AXI_AR_CHROMA_CHANID_0_r;
 (* DONT_TOUCH = "TRUE" *)  reg [2:0] 			S_AXI_AR_CHROMA_CHANID_1_r;
 (* DONT_TOUCH = "TRUE" *)  reg [2:0] 			S_AXI_AR_CHROMA_CHANID_2_r;
 (* DONT_TOUCH = "TRUE" *)  reg [2:0] 			S_AXI_AR_CHROMA_CHANID;
   
 (* DONT_TOUCH = "TRUE" *)  reg [3:0] 			luma_chan_dec;
 (* DONT_TOUCH = "TRUE" *)  reg [3:0] 			chroma_chan_dec;
   
 (* DONT_TOUCH = "TRUE" *)  reg [23:0] 			luma_timeout_counter [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 	luma_timeout_en;
 (* DONT_TOUCH = "TRUE" *)  reg [23:0] 			chroma_timeout_counter [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 	chroma_timeout_en;

 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] 	luma_outofrange_c;
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] 	chroma_outofrange_c;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 	luma_outofrange_p;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 	chroma_outofrange_p;

 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 	luma_outofrange_0;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 	chroma_outofrange_0;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 	luma_outofrange_1;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 	chroma_outofrange_1;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 	luma_outofrange_2;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 	chroma_outofrange_2;

 (* DONT_TOUCH = "TRUE" *)  wire [C_S_AXI_ADDR_WIDTH-1 : 0] axi_axlen_0 = s_axi_arlen_0;
 (* DONT_TOUCH = "TRUE" *)  wire [C_S_AXI_ADDR_WIDTH-1 : 0] axi_axlen_1 = s_axi_arlen_1;
 (* DONT_TOUCH = "TRUE" *)  wire [C_S_AXI_ADDR_WIDTH-1 : 0] axi_axlen_2 = s_axi_arlen_2;
 (* DONT_TOUCH = "TRUE" *)  wire [C_BL_WIDTH-1 : 0] axi_axaddr_burst_len = (S_AXI_ARLEN[7:0]+1) << S_AXI_ARSIZE[2:0];
 (* DONT_TOUCH = "TRUE" *)  wire [C_BL_WIDTH-1 : 0] s_axi_axaddr_burst_len_0;
 (* DONT_TOUCH = "TRUE" *)  wire [C_BL_WIDTH-1 : 0] s_axi_axaddr_burst_len_1;
 (* DONT_TOUCH = "TRUE" *)  wire [C_BL_WIDTH-1 : 0] s_axi_axaddr_burst_len_2;

 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 	   int_prod_luma_frmbuf_addr_done_keep_0;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 	   int_prod_luma_frmbuf_addr_done_keep_1;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 	   int_prod_luma_frmbuf_addr_done_keep_1_buf0;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 	   int_prod_luma_frmbuf_addr_done_keep_1_buf1;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 	   int_prod_luma_frmbuf_addr_done_keep_1_buf2;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 	   int_prod_luma_frmbuf_addr_done_keep_2;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 	   int_prod_luma_frmbuf_addr_done_keep_2_buf0;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 	   int_prod_luma_frmbuf_addr_done_keep_2_buf1;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 	   int_prod_luma_frmbuf_addr_done_keep_2_buf2;

 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 	   int_prod_chroma_frmbuf_addr_done_keep_0;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 	   int_prod_chroma_frmbuf_addr_done_keep_1;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 	   int_prod_chroma_frmbuf_addr_done_keep_1_buf0;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 	   int_prod_chroma_frmbuf_addr_done_keep_1_buf1;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 	   int_prod_chroma_frmbuf_addr_done_keep_1_buf2;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 	   int_prod_chroma_frmbuf_addr_done_keep_2;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 	   int_prod_chroma_frmbuf_addr_done_keep_2_buf0;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 	   int_prod_chroma_frmbuf_addr_done_keep_2_buf1;
 (* DONT_TOUCH = "TRUE" *)  reg [C_VIDEO_CHAN-1:0] 	   int_prod_chroma_frmbuf_addr_done_keep_2_buf2;
   
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] int_s_axi_sw_areset;
 (* DONT_TOUCH = "TRUE" *)  wire [C_VIDEO_CHAN-1:0] S_AXI_ARESET;
 (* DONT_TOUCH = "TRUE" *)  wire rst;
 (* DONT_TOUCH = "TRUE" *)  wire f1_rst;
 (* DONT_TOUCH = "TRUE" *)  wire f2_rst;

   //##### Addition of register base fifo to overcome pulse sync issue
   //reg [C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN-1:0] ot_luma_fifo [0:3];
   //reg [2:0] luma_wptr;
   //reg [2:0] luma_rptr;
   wire      luma_empty;
   wire      luma_full;
   wire [C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN-1:0] luma_frmbuf_addr_outthres;
   wire [C_VIDEO_CHAN-1:0] luma_frmbuf_addr_outthres_valid;
 
   //reg [C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN-1:0] ot_chroma_fifo [0:3];
   //reg [2:0] chroma_wptr;
   //reg [2:0] chroma_rptr;
   wire      chroma_empty;
   wire      chroma_full;
   wire [C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN-1:0] chroma_frmbuf_addr_outthres;
   wire [C_VIDEO_CHAN-1:0] chroma_frmbuf_addr_outthres_valid;
 (* DONT_TOUCH = "TRUE" *)  reg [1:0] ot_luma_buf_id_0;
 (* DONT_TOUCH = "TRUE" *)  reg [1:0] ot_chroma_buf_id_0;
 (* DONT_TOUCH = "TRUE" *)  reg [1:0] ot_luma_buf_id_1;
 (* DONT_TOUCH = "TRUE" *)  reg [1:0] ot_chroma_buf_id_1;
 (* DONT_TOUCH = "TRUE" *)  reg [1:0] ot_luma_buf_id_2;
 (* DONT_TOUCH = "TRUE" *)  reg [1:0] ot_chroma_buf_id_2;
 (* DONT_TOUCH = "TRUE" *)  wire                         luma_xpm_wen;
 (* DONT_TOUCH = "TRUE" *)  wire                         chroma_xpm_wen;
 (* DONT_TOUCH = "TRUE" *)  wire                         luma_xpm_ren;
 (* DONT_TOUCH = "TRUE" *)  wire                         chroma_xpm_ren;
 (* DONT_TOUCH = "TRUE" *)  wire [(XPM_FIFO_DWIDTH-1):0] luma_xpm_wdata;
 (* DONT_TOUCH = "TRUE" *)  wire [(XPM_FIFO_DWIDTH-1):0] chroma_xpm_wdata;
 (* DONT_TOUCH = "TRUE" *)  wire [(XPM_FIFO_DWIDTH-1):0] luma_xpm_rdata;
 (* DONT_TOUCH = "TRUE" *)  wire [(XPM_FIFO_DWIDTH-1):0] chroma_xpm_rdata;
 (* DONT_TOUCH = "TRUE" *)  wire                         luma_xpm_rvld;
 (* DONT_TOUCH = "TRUE" *)  wire                         chroma_xpm_rvld;
 (* DONT_TOUCH = "TRUE" *)  wire [(C_VIDEO_CHAN-1):0] prod_luma_xpm_frmbuf_addr_done;
 (* DONT_TOUCH = "TRUE" *)  wire [(C_VIDEO_CHAN-1):0] prod_luma_xpm_frmbuf_addr_done_w;
 (* DONT_TOUCH = "TRUE" *)  reg  [(C_VIDEO_CHAN-1):0] prod_luma_xpm_frmbuf_addr_done_rg;
 (* DONT_TOUCH = "TRUE" *)  wire [(C_VIDEO_CHAN-1):0] prod_luma_xpm_addr_outthreshold_vld;
 (* DONT_TOUCH = "TRUE" *)  wire [2*C_VIDEO_CHAN-1:0] prod_luma_xpm_buf_id;
 (* DONT_TOUCH = "TRUE" *)  wire [(C_VIDEO_CHAN-1):0] prod_chroma_xpm_frmbuf_addr_done;
 (* DONT_TOUCH = "TRUE" *)  wire [(C_VIDEO_CHAN-1):0] prod_chroma_xpm_frmbuf_addr_done_w;
 (* DONT_TOUCH = "TRUE" *)  reg  [(C_VIDEO_CHAN-1):0] prod_chroma_xpm_frmbuf_addr_done_rg;
 (* DONT_TOUCH = "TRUE" *)  wire [(C_VIDEO_CHAN-1):0] prod_chroma_xpm_addr_outthreshold_vld;
 (* DONT_TOUCH = "TRUE" *)  wire [2*C_VIDEO_CHAN-1:0] prod_chroma_xpm_buf_id;
 (* DONT_TOUCH = "TRUE" *)  reg  [C_RD_BUF_CNT_WIDTH-1:0] luma_total_buf_rd_cnt_rg         [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  reg  [C_RD_BUF_CNT_WIDTH-1:0] chroma_total_buf_rd_cnt_rg       [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  wire [C_RD_BUF_CNT_WIDTH-1:0] luma_total_buf_rd_cnt            [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  wire [C_RD_BUF_CNT_WIDTH-1:0] chroma_total_buf_rd_cnt          [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  reg  [C_RD_BUF_CNT_WIDTH-1:0] luma_buf_rd_cnt0                 [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  reg  [C_RD_BUF_CNT_WIDTH-1:0] chroma_buf_rd_cnt0               [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  reg  [C_RD_BUF_CNT_WIDTH-1:0] luma_buf_rd_cnt1                 [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  reg  [C_RD_BUF_CNT_WIDTH-1:0] chroma_buf_rd_cnt1               [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  reg  [C_RD_BUF_CNT_WIDTH-1:0] luma_buf_rd_cnt2                 [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  reg  [C_RD_BUF_CNT_WIDTH-1:0] chroma_buf_rd_cnt2               [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  reg  [C_RD_BUF_CNT_WIDTH-1:0] calc_luma_total_buf_rd_cnt1_rg   [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  reg  [C_RD_BUF_CNT_WIDTH-1:0] calc_luma_total_buf_rd_cnt2_rg   [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  reg  [C_RD_BUF_CNT_WIDTH-1:0] calc_chroma_total_buf_rd_cnt1_rg [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  reg  [C_RD_BUF_CNT_WIDTH-1:0] calc_chroma_total_buf_rd_cnt2_rg [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  reg  [C_RD_BUF_CNT_WIDTH-1:0] luma_buf_rd_cnt3                 [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  reg  [C_RD_BUF_CNT_WIDTH-1:0] chroma_buf_rd_cnt3               [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  reg  [C_RD_BUF_CNT_WIDTH-1:0] luma_buf_rd_cnt                  [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  reg  [C_RD_BUF_CNT_WIDTH-1:0] chroma_buf_rd_cnt                [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  wire [C_RD_BUF_CNT_WIDTH-1:0] calc_luma_total_buf_rd_cnt1      [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  wire [C_RD_BUF_CNT_WIDTH-1:0] calc_luma_total_buf_rd_cnt2      [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  wire [C_RD_BUF_CNT_WIDTH-1:0] calc_chroma_total_buf_rd_cnt1    [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  wire [C_RD_BUF_CNT_WIDTH-1:0] calc_chroma_total_buf_rd_cnt2    [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  reg  [C_BUF_CNT_WIDTH-1:0] luma_buf_cnt                     [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  reg  [C_BUF_CNT_WIDTH-1:0] chroma_buf_cnt                   [0:C_VIDEO_CHAN-1];
 (* DONT_TOUCH = "TRUE" *)  wire cons_luma_ch0_inrange;
 (* DONT_TOUCH = "TRUE" *)  wire cons_luma_ch1_inrange;
 (* DONT_TOUCH = "TRUE" *)  wire cons_luma_ch2_inrange;
 (* DONT_TOUCH = "TRUE" *)  wire cons_luma_ch3_inrange;
 (* DONT_TOUCH = "TRUE" *)  wire cons_chroma_ch0_inrange;
 (* DONT_TOUCH = "TRUE" *)  wire cons_chroma_ch1_inrange;
 (* DONT_TOUCH = "TRUE" *)  wire cons_chroma_ch2_inrange;
 (* DONT_TOUCH = "TRUE" *)  wire cons_chroma_ch3_inrange;

   integer 			i,j,k;

   //synthesis translate_off
   wire [C_FRMBUF_ADDR_WIDTH-1:0] debug_calc_luma_frmbuf_end_addr_1_0   = calc_luma_frmbuf_end_addr_1[0];
   wire [C_FRMBUF_ADDR_WIDTH-1:0] debug_calc_luma_frmbuf_end_addr_1_1   = calc_luma_frmbuf_end_addr_1[1];
   wire [C_FRMBUF_ADDR_WIDTH-1:0] debug_calc_luma_frmbuf_end_addr_1_2   = calc_luma_frmbuf_end_addr_1[2];
   wire [C_FRMBUF_ADDR_WIDTH-1:0] debug_calc_luma_frmbuf_end_addr_1_3   = calc_luma_frmbuf_end_addr_1[3];
   wire [C_FRMBUF_ADDR_WIDTH-1:0] debug_calc_luma_frmbuf_end_addr_2_0   = calc_luma_frmbuf_end_addr_2[0];
   wire [C_FRMBUF_ADDR_WIDTH-1:0] debug_calc_luma_frmbuf_end_addr_2_1   = calc_luma_frmbuf_end_addr_2[1];
   wire [C_FRMBUF_ADDR_WIDTH-1:0] debug_calc_luma_frmbuf_end_addr_2_2   = calc_luma_frmbuf_end_addr_2[2];
   wire [C_FRMBUF_ADDR_WIDTH-1:0] debug_calc_luma_frmbuf_end_addr_2_3   = calc_luma_frmbuf_end_addr_2[3];
   wire [C_FRMBUF_ADDR_WIDTH-1:0] debug_calc_chroma_frmbuf_end_addr_1_0 = calc_chroma_frmbuf_end_addr_1[0];
   wire [C_FRMBUF_ADDR_WIDTH-1:0] debug_calc_chroma_frmbuf_end_addr_1_1 = calc_chroma_frmbuf_end_addr_1[1];
   wire [C_FRMBUF_ADDR_WIDTH-1:0] debug_calc_chroma_frmbuf_end_addr_1_2 = calc_chroma_frmbuf_end_addr_1[2];
   wire [C_FRMBUF_ADDR_WIDTH-1:0] debug_calc_chroma_frmbuf_end_addr_1_3 = calc_chroma_frmbuf_end_addr_1[3];
   wire [C_FRMBUF_ADDR_WIDTH-1:0] debug_calc_chroma_frmbuf_end_addr_2_0 = calc_chroma_frmbuf_end_addr_2[0];
   wire [C_FRMBUF_ADDR_WIDTH-1:0] debug_calc_chroma_frmbuf_end_addr_2_1 = calc_chroma_frmbuf_end_addr_2[1];
   wire [C_FRMBUF_ADDR_WIDTH-1:0] debug_calc_chroma_frmbuf_end_addr_2_2 = calc_chroma_frmbuf_end_addr_2[2];
   wire [C_FRMBUF_ADDR_WIDTH-1:0] debug_calc_chroma_frmbuf_end_addr_2_3 = calc_chroma_frmbuf_end_addr_2[3];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_luma_total_buf_rd_cnt_0         = luma_total_buf_rd_cnt[0];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_luma_total_buf_rd_cnt_1         = luma_total_buf_rd_cnt[1];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_luma_total_buf_rd_cnt_2         = luma_total_buf_rd_cnt[2];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_luma_total_buf_rd_cnt_3         = luma_total_buf_rd_cnt[3];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_chroma_total_buf_rd_cnt_0       = chroma_total_buf_rd_cnt[0];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_chroma_total_buf_rd_cnt_1       = chroma_total_buf_rd_cnt[1];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_chroma_total_buf_rd_cnt_2       = chroma_total_buf_rd_cnt[2];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_chroma_total_buf_rd_cnt_3       = chroma_total_buf_rd_cnt[3];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_luma_buf_rd_cnt_0               = luma_buf_rd_cnt[0];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_luma_buf_rd_cnt_1               = luma_buf_rd_cnt[1];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_luma_buf_rd_cnt_2               = luma_buf_rd_cnt[2];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_luma_buf_rd_cnt_3               = luma_buf_rd_cnt[3];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_chroma_buf_rd_cnt_0             = chroma_buf_rd_cnt[0];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_chroma_buf_rd_cnt_1             = chroma_buf_rd_cnt[1];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_chroma_buf_rd_cnt_2             = chroma_buf_rd_cnt[2];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_chroma_buf_rd_cnt_3             = chroma_buf_rd_cnt[3];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_luma_buf_rd_cnt0_0              = luma_buf_rd_cnt0[0];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_luma_buf_rd_cnt0_1              = luma_buf_rd_cnt0[1];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_luma_buf_rd_cnt0_2              = luma_buf_rd_cnt0[2];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_luma_buf_rd_cnt0_3              = luma_buf_rd_cnt0[3];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_chroma_buf_rd_cnt0_0            = chroma_buf_rd_cnt0[0];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_chroma_buf_rd_cnt0_1            = chroma_buf_rd_cnt0[1];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_chroma_buf_rd_cnt0_2            = chroma_buf_rd_cnt0[2];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_chroma_buf_rd_cnt0_3            = chroma_buf_rd_cnt0[3];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_luma_buf_rd_cnt1_0              = luma_buf_rd_cnt1[0];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_luma_buf_rd_cnt1_1              = luma_buf_rd_cnt1[1];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_luma_buf_rd_cnt1_2              = luma_buf_rd_cnt1[2];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_luma_buf_rd_cnt1_3              = luma_buf_rd_cnt1[3];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_chroma_buf_rd_cnt1_0            = chroma_buf_rd_cnt1[0];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_chroma_buf_rd_cnt1_1            = chroma_buf_rd_cnt1[1];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_chroma_buf_rd_cnt1_2            = chroma_buf_rd_cnt1[2];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_chroma_buf_rd_cnt1_3            = chroma_buf_rd_cnt1[3];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_luma_buf_rd_cnt2_0              = luma_buf_rd_cnt2[0];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_luma_buf_rd_cnt2_1              = luma_buf_rd_cnt2[1];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_luma_buf_rd_cnt2_2              = luma_buf_rd_cnt2[2];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_luma_buf_rd_cnt2_3              = luma_buf_rd_cnt2[3];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_chroma_buf_rd_cnt2_0            = chroma_buf_rd_cnt2[0];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_chroma_buf_rd_cnt2_1            = chroma_buf_rd_cnt2[1];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_chroma_buf_rd_cnt2_2            = chroma_buf_rd_cnt2[2];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_chroma_buf_rd_cnt2_3            = chroma_buf_rd_cnt2[3];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_luma_buf_rd_cnt3_0              = luma_buf_rd_cnt3[0];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_luma_buf_rd_cnt3_1              = luma_buf_rd_cnt3[1];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_luma_buf_rd_cnt3_2              = luma_buf_rd_cnt3[2];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_luma_buf_rd_cnt3_3              = luma_buf_rd_cnt3[3];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_chroma_buf_rd_cnt3_0            = chroma_buf_rd_cnt3[0];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_chroma_buf_rd_cnt3_1            = chroma_buf_rd_cnt3[1];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_chroma_buf_rd_cnt3_2            = chroma_buf_rd_cnt3[2];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_chroma_buf_rd_cnt3_3            = chroma_buf_rd_cnt3[3];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_calc_luma_total_buf_rd_cnt1_0   = calc_luma_total_buf_rd_cnt1[0];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_calc_luma_total_buf_rd_cnt1_1   = calc_luma_total_buf_rd_cnt1[1];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_calc_luma_total_buf_rd_cnt1_2   = calc_luma_total_buf_rd_cnt1[2];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_calc_luma_total_buf_rd_cnt1_3   = calc_luma_total_buf_rd_cnt1[3];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_calc_chroma_total_buf_rd_cnt1_0 = calc_chroma_total_buf_rd_cnt1[0];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_calc_chroma_total_buf_rd_cnt1_1 = calc_chroma_total_buf_rd_cnt1[1];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_calc_chroma_total_buf_rd_cnt1_2 = calc_chroma_total_buf_rd_cnt1[2];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_calc_chroma_total_buf_rd_cnt1_3 = calc_chroma_total_buf_rd_cnt1[3];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_calc_luma_total_buf_rd_cnt2_0   = calc_luma_total_buf_rd_cnt2[0];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_calc_luma_total_buf_rd_cnt2_1   = calc_luma_total_buf_rd_cnt2[1];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_calc_luma_total_buf_rd_cnt2_2   = calc_luma_total_buf_rd_cnt2[2];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_calc_luma_total_buf_rd_cnt2_3   = calc_luma_total_buf_rd_cnt2[3];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_calc_chroma_total_buf_rd_cnt2_0 = calc_chroma_total_buf_rd_cnt2[0];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_calc_chroma_total_buf_rd_cnt2_1 = calc_chroma_total_buf_rd_cnt2[1];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_calc_chroma_total_buf_rd_cnt2_2 = calc_chroma_total_buf_rd_cnt2[2];
   wire [C_RD_BUF_CNT_WIDTH-1:0] debug_calc_chroma_total_buf_rd_cnt2_3 = calc_chroma_total_buf_rd_cnt2[3];
   //synthesis translate_on

   //dff_sync en_sw_rst_0 (.i(S_AXI_SW_ARESET[0]),
   //                      .clk (S_AXI_ACLK),
   //                      .o(int_s_axi_sw_areset[0]));

   //assign S_AXI_ARESET[0] = S_AXI_ARESETN & (~int_s_axi_sw_areset[0]);

   //dff_sync en_sw_rst_1 (.i(S_AXI_SW_ARESET[1]),
   //                      .clk (S_AXI_ACLK),
   //                      .o(int_s_axi_sw_areset[1]));

   //assign S_AXI_ARESET[1] = S_AXI_ARESETN & (~int_s_axi_sw_areset[1]);

   assign rst    = ((|S_AXI_ARESET[1:0]) & (C_VIDEO_CHAN_ID == 0))|
                   ((|S_AXI_ARESET[3:2]) & (C_VIDEO_CHAN_ID == 1));

   assign f1_rst = ((S_AXI_ARESET[0]) & (C_VIDEO_CHAN_ID == 0))|
                   ((S_AXI_ARESET[2]) & (C_VIDEO_CHAN_ID == 1));

   assign f2_rst = ((S_AXI_ARESET[1]) & (C_VIDEO_CHAN_ID == 0))|
                   ((S_AXI_ARESET[3]) & (C_VIDEO_CHAN_ID == 1));

   // pipelines
   always @(posedge S_AXI_ACLK) begin
      S_AXI_ARADDR_r <= S_AXI_ARADDR;
      S_AXI_ARVALID_r <= S_AXI_ARVALID;
   end
   //######
   //luma outthreshold fifo
//   always @ (posedge producer_aclk)
//   begin//{
//     if (~producer_aresetn)
//     begin//{
//       luma_wptr <= {3{1'b0}};
//     end//}
//     else
//     begin//{
//       luma_wptr <= luma_wptr +  (|prod_luma_frmbuf_addr_outthres_valid_pulse);
//       ot_luma_fifo[luma_wptr[1:0]] <= prod_luma_frmbuf_addr_outthres;
//     end//}
//   end//}
//
//   always @ (posedge S_AXI_ACLK)
//   begin//{
//     if (~rst)
//     begin//{
//       luma_rptr <= {3{1'b0}};
//     end//}
//     else
//     begin//{
//       luma_rptr <= luma_rptr + (~luma_empty);
//       luma_frmbuf_addr_outthres <= ot_luma_fifo[luma_rptr[1:0]];
//     end//}
//   end//}
//
//   assign luma_empty = (luma_wptr == luma_rptr);
//   assign luma_full  = (luma_wptr[1:0] == luma_rptr[1:0]) && (luma_wptr[2] != luma_rptr[2]);

   assign luma_xpm_wen   = ( (|prod_luma_frmbuf_c0_addr_done) |
                             (|prod_luma_frmbuf_c1_addr_done) |
                             (|prod_luma_frmbuf_c2_addr_done) |
                             (|prod_luma_frmbuf_c3_addr_done) |
                             (|prod_luma_frmbuf_addr_outthres_valid_pulse) |
                             (|prod_luma_frmbuf_addr_done) );

   assign luma_xpm_ren   = (~(luma_empty));

   assign luma_xpm_wdata = {prod_luma_frmbuf_c0_addr_done,
                            prod_luma_frmbuf_c1_addr_done,
                            prod_luma_frmbuf_c2_addr_done,
                            prod_luma_frmbuf_c3_addr_done,
                            prod_luma_frmbuf_addr_done,
                            prod_luma_frmbuf_addr_outthres_valid_pulse,
                            prod_luma_buf_id,
                            prod_luma_frmbuf_addr_outthres};


   xpm_fifo_async # (
                     .FIFO_MEMORY_TYPE    ("auto"), //string; "auto", "block", or "distributed";
                     .ECC_MODE            ("no_ecc"), //string; "no_ecc" or "en_ecc";
                     .RELATED_CLOCKS      (0), //positive integer; 0 or 1
                     .FIFO_WRITE_DEPTH    (32), //positive integer
                     .WRITE_DATA_WIDTH    (XPM_FIFO_DWIDTH), //positive integer
                     .WR_DATA_COUNT_WIDTH (6), //positive integer
                     .PROG_FULL_THRESH    (16), //positive integer
                     .FULL_RESET_VALUE    (0), //positive integer; 0 or 1
                     //.USE_ADV_FEATURES  ("0707"), //string; "0000" to "1F1F";
                     .USE_ADV_FEATURES    ("1000"), //string; "0000" to "1F1F";
                     .READ_MODE           ("fwft"), //string; "std" or "fwft";
                     .FIFO_READ_LATENCY   (1), //positive integer;
                     .READ_DATA_WIDTH     (XPM_FIFO_DWIDTH), //positive integer
                     .RD_DATA_COUNT_WIDTH (6), //positive integer
                     .PROG_EMPTY_THRESH   (5), //positive integer
                     .DOUT_RESET_VALUE    ("0"), //string
                     .CDC_SYNC_STAGES     (2), //positive integer
                     .WAKEUP_TIME         (0) //positive integer; 0 or 2;
                    ) 
      luma_outthrehold_fifo_inst (
                                  .rst           (~rst),
                                  .wr_clk        (producer_aclk),
                                  //.wr_en         ((|prod_luma_frmbuf_addr_outthres_valid_pulse)|(|prod_luma_frmbuf_addr_done) ),
                                  .wr_en         (luma_xpm_wen),
                                  //.din           (prod_luma_frmbuf_addr_outthres ),
                                  .din           (luma_xpm_wdata ),
                                  .prog_full     (luma_full),
                                  .rd_clk        (S_AXI_ACLK ),
                                  .rd_en         ((~luma_empty) ),
                                  //.dout          (luma_frmbuf_addr_outthres ),
                                  .dout          (luma_xpm_rdata ),
                                  .empty         (luma_empty ),
                                  .sleep         (1'b0 ),
                                  .injectsbiterr (1'b0 ),
                                  .injectdbiterr (1'b0 ),
                                  .sbiterr       (),
                                  .dbiterr       (),
                                  .full          (),
                                  .overflow      (),
                                  .wr_rst_busy   (),
                                  .underflow     (),
                                  .rd_rst_busy   (),
                                  .wr_data_count (),
                                  .prog_empty    (),
                                  .rd_data_count (),
                                  .almost_full   (),
                                  .wr_ack        (),
                                  .almost_empty  (),
                                  .data_valid    (luma_xpm_rvld)
                                 );


     assign int_prod_luma_frmbuf_c0_addr_done_w = (luma_xpm_rdata[((C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN)+(7*C_VIDEO_CHAN)) +: C_VIDEO_CHAN] & ({C_VIDEO_CHAN{luma_xpm_rvld}}));
     assign int_prod_luma_frmbuf_c1_addr_done_w = (luma_xpm_rdata[((C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN)+(6*C_VIDEO_CHAN)) +: C_VIDEO_CHAN] & ({C_VIDEO_CHAN{luma_xpm_rvld}}));
     assign int_prod_luma_frmbuf_c2_addr_done_w = (luma_xpm_rdata[((C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN)+(5*C_VIDEO_CHAN)) +: C_VIDEO_CHAN] & ({C_VIDEO_CHAN{luma_xpm_rvld}}));
     assign int_prod_luma_frmbuf_c3_addr_done_w = (luma_xpm_rdata[((C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN)+(4*C_VIDEO_CHAN)) +: C_VIDEO_CHAN] & ({C_VIDEO_CHAN{luma_xpm_rvld}}));
     assign prod_luma_xpm_frmbuf_addr_done_w    = (luma_xpm_rdata[((C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN)+(3*C_VIDEO_CHAN)) +: C_VIDEO_CHAN] & ({C_VIDEO_CHAN{luma_xpm_rvld}}));
     assign prod_luma_xpm_addr_outthreshold_vld = (luma_xpm_rdata[((C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN)+(2*C_VIDEO_CHAN)) +: C_VIDEO_CHAN] & ({C_VIDEO_CHAN{luma_xpm_rvld}}));
     assign prod_luma_xpm_buf_id                = luma_xpm_rdata[(C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN) +: (C_VIDEO_CHAN*2)];
     assign luma_frmbuf_addr_outthres           = luma_xpm_rdata[0 +: (C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN)];

     //genvar x;
     //generate
     //  for (x=0;x<C_VIDEO_CHAN;x=x+1) 
     //  begin: gen_luma_outthreshold
     //    //assign luma_frmbuf_addr_outthres[(x*C_FRMBUF_ADDR_WIDTH) +: C_FRMBUF_ADDR_WIDTH] = (luma_xpm_rdata[(x*C_FRMBUF_ADDR_WIDTH) +: C_FRMBUF_ADDR_WIDTH] &
     //    //                                                                                    {C_FRMBUF_ADDR_WIDTH{prod_luma_xpm_addr_outthreshold_vld[x]}});
     //    assign luma_frmbuf_addr_outthres[(x*C_FRMBUF_ADDR_WIDTH) +: C_FRMBUF_ADDR_WIDTH] = (luma_xpm_rdata[(x*C_FRMBUF_ADDR_WIDTH) +: C_FRMBUF_ADDR_WIDTH] &
     //                                                                                        {C_FRMBUF_ADDR_WIDTH{|prod_luma_xpm_addr_outthreshold_vld}});
     //  end
     //endgenerate

    // always @ (posedge S_AXI_ACLK)
    // begin
    //  if (~rst)
    //  begin
    //    prod_luma_xpm_frmbuf_addr_done      <= {C_VIDEO_CHAN{1'b0}};
    //    prod_luma_xpm_addr_outthreshold_vld <= {C_VIDEO_CHAN{1'b0}};
    //    prod_luma_xpm_buf_id                <= {2*C_VIDEO_CHAN{1'b0}};
    //    luma_frmbuf_addr_outthres           <= {C_VIDEO_CHAN*C_FRMBUF_ADDR_WIDTH{1'b0}};
    //  end
    //  else
    //  begin
    //    prod_luma_xpm_frmbuf_addr_done      <= luma_xpm_rdata[(XPM_FIFO_DWIDTH-1): (XPM_FIFO_DWIDTH-C_VIDEO_CHAN)];
    //    prod_luma_xpm_addr_outthreshold_vld <= luma_xpm_rdata[(XPM_FIFO_DWIDTH-C_VIDEO_CHAN-1):(XPM_FIFO_DWIDTH-(2*C_VIDEO_CHAN))];
    //    prod_luma_xpm_buf_id                <= luma_xpm_rdata[(XPM_FIFO_DWIDTH-(2*C_VIDEO_CHAN)-1):(XPM_FIFO_DWIDTH-(4*C_VIDEO_CHAN))];
    //    if ( |(luma_xpm_rdata[(XPM_FIFO_DWIDTH-C_VIDEO_CHAN-1):(XPM_FIFO_DWIDTH-(2*C_VIDEO_CHAN))]))
    //    begin
    //      luma_frmbuf_addr_outthres         <= luma_xpm_rdata[(XPM_FIFO_DWIDTH-(4*C_VIDEO_CHAN)-1):0];
    //    end
    //  end
    // end

   //chroma outthreshold fifo
//   always @ (posedge producer_aclk)
//   begin//{
//     if (~producer_aresetn)
//     begin//{
//       chroma_wptr <= {3{1'b0}};
//     end//}
//     else
//     begin//{
//       chroma_wptr <= chroma_wptr +  (|prod_chroma_frmbuf_addr_outthres_valid_pulse);
//       ot_chroma_fifo[chroma_wptr[1:0]] <= prod_chroma_frmbuf_addr_outthres;
//     end//}
//   end//}
//
//   always @ (posedge S_AXI_ACLK)
//   begin//{
//     if (~rst)
//     begin//{
//       chroma_rptr <= {3{1'b0}};
//     end//}
//     else
//     begin//{
//       chroma_rptr <= chroma_rptr + (~chroma_empty);
//       chroma_frmbuf_addr_outthres <= ot_chroma_fifo[chroma_rptr[1:0]];
//     end//}
//   end//}
//
//   assign chroma_empty = (chroma_wptr == chroma_rptr);
//   assign chroma_full  = (chroma_wptr[1:0] == chroma_rptr[1:0]) && (chroma_wptr[2] != chroma_rptr[2]);

   assign chroma_xpm_wen   = ( (|prod_chroma_frmbuf_c0_addr_done) |
                               (|prod_chroma_frmbuf_c1_addr_done) |
                               (|prod_chroma_frmbuf_c2_addr_done) |
                               (|prod_chroma_frmbuf_c3_addr_done) |
                               (|prod_chroma_frmbuf_addr_outthres_valid_pulse) |
                               (|prod_chroma_frmbuf_addr_done) );

   assign chroma_xpm_ren   = (~(chroma_empty));

   assign chroma_xpm_wdata = {prod_chroma_frmbuf_c0_addr_done,
                              prod_chroma_frmbuf_c1_addr_done,
                              prod_chroma_frmbuf_c2_addr_done,
                              prod_chroma_frmbuf_c3_addr_done,
                              prod_chroma_frmbuf_addr_done,
                              prod_chroma_frmbuf_addr_outthres_valid_pulse,
                              prod_chroma_buf_id,
                              prod_chroma_frmbuf_addr_outthres};

   xpm_fifo_async # (
                     .FIFO_MEMORY_TYPE    ("auto"), //string; "auto", "block", or "distributed";
                     .ECC_MODE            ("no_ecc"), //string; "no_ecc" or "en_ecc";
                     .RELATED_CLOCKS      (0), //positive integer; 0 or 1
                     .FIFO_WRITE_DEPTH    (32), //positive integer
                     .WRITE_DATA_WIDTH    (XPM_FIFO_DWIDTH), //positive integer
                     .WR_DATA_COUNT_WIDTH (6), //positive integer
                     .PROG_FULL_THRESH    (16), //positive integer
                     .FULL_RESET_VALUE    (0), //positive integer; 0 or 1
                     //.USE_ADV_FEATURES  ("0707"), //string; "0000" to "1F1F";
                     .USE_ADV_FEATURES    ("1000"), //string; "0000" to "1F1F";
                     .READ_MODE           ("fwft"), //string; "std" or "fwft";
                     .FIFO_READ_LATENCY   (1), //positive integer;
                     .READ_DATA_WIDTH     (XPM_FIFO_DWIDTH), //positive integer
                     .RD_DATA_COUNT_WIDTH (6), //positive integer
                     .PROG_EMPTY_THRESH   (5), //positive integer
                     .DOUT_RESET_VALUE    ("0"), //string
                     .CDC_SYNC_STAGES     (2), //positive integer
                     .WAKEUP_TIME         (0) //positive integer; 0 or 2;
                    ) 
      chroma_outthrehold_fifo_inst (
                                  .rst           (~rst),
                                  .wr_clk        (producer_aclk),
                                  //.wr_en         ((|prod_chroma_frmbuf_addr_outthres_valid_pulse)|(|prod_chroma_frmbuf_addr_done)),
                                  .wr_en         (chroma_xpm_wen),
                                  //.din           (prod_chroma_frmbuf_addr_outthres ),
                                  .din           (chroma_xpm_wdata),
                                  .prog_full     (chroma_full ),
                                  .rd_clk        (S_AXI_ACLK ),
                                  .rd_en         (chroma_xpm_ren),
                                  //.dout          (chroma_frmbuf_addr_outthres ),
                                  .dout          (chroma_xpm_rdata ),
                                  .empty         (chroma_empty ),
                                  .sleep         (1'b0 ),
                                  .injectsbiterr (1'b0 ),
                                  .injectdbiterr (1'b0 ),
                                  .sbiterr       (),
                                  .dbiterr       (),
                                  .full          (),
                                  .overflow      (),
                                  .wr_rst_busy   (),
                                  .underflow     (),
                                  .rd_rst_busy   (),
                                  .wr_data_count (),
                                  .prog_empty    (),
                                  .rd_data_count (),
                                  .almost_full   (),
                                  .wr_ack        (),
                                  .almost_empty  (),
                                  .data_valid    (chroma_xpm_rvld)
                                 );

     assign int_prod_chroma_frmbuf_c0_addr_done_w = (chroma_xpm_rdata[((C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN)+(7*C_VIDEO_CHAN)) +: C_VIDEO_CHAN] & ({C_VIDEO_CHAN{chroma_xpm_rvld}}));
     assign int_prod_chroma_frmbuf_c1_addr_done_w = (chroma_xpm_rdata[((C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN)+(6*C_VIDEO_CHAN)) +: C_VIDEO_CHAN] & ({C_VIDEO_CHAN{chroma_xpm_rvld}}));
     assign int_prod_chroma_frmbuf_c2_addr_done_w = (chroma_xpm_rdata[((C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN)+(5*C_VIDEO_CHAN)) +: C_VIDEO_CHAN] & ({C_VIDEO_CHAN{chroma_xpm_rvld}}));
     assign int_prod_chroma_frmbuf_c3_addr_done_w = (chroma_xpm_rdata[((C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN)+(4*C_VIDEO_CHAN)) +: C_VIDEO_CHAN] & ({C_VIDEO_CHAN{chroma_xpm_rvld}}));
     assign prod_chroma_xpm_frmbuf_addr_done_w    = (chroma_xpm_rdata[((C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN)+(3*C_VIDEO_CHAN)) +: C_VIDEO_CHAN] & ({C_VIDEO_CHAN{chroma_xpm_rvld}}));
     assign prod_chroma_xpm_addr_outthreshold_vld = (chroma_xpm_rdata[((C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN)+(2*C_VIDEO_CHAN)) +: C_VIDEO_CHAN] & ({C_VIDEO_CHAN{chroma_xpm_rvld}}));
     assign prod_chroma_xpm_buf_id                = chroma_xpm_rdata[(C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN) +: (C_VIDEO_CHAN*2)];
     assign chroma_frmbuf_addr_outthres           = chroma_xpm_rdata[0 +: (C_FRMBUF_ADDR_WIDTH*C_VIDEO_CHAN)];


     //genvar y;
     //generate
     //  for (y=0;y<C_VIDEO_CHAN;y=y+1) 
     //  begin: gen_chroma_outthreshold
     //    assign chroma_frmbuf_addr_outthres[(y*C_FRMBUF_ADDR_WIDTH) +: C_FRMBUF_ADDR_WIDTH] = (chroma_xpm_rdata[(y*C_FRMBUF_ADDR_WIDTH) +: C_FRMBUF_ADDR_WIDTH] &
     //                                                                                          {C_FRMBUF_ADDR_WIDTH{prod_chroma_xpm_addr_outthreshold_vld[y]}});
     //  end
     //endgenerate

     //always @ (posedge S_AXI_ACLK)
     //begin
     // if (~rst)
     // begin
     //   prod_chroma_xpm_frmbuf_addr_done      <= {C_VIDEO_CHAN{1'b0}};
     //   prod_chroma_xpm_addr_outthreshold_vld <= {C_VIDEO_CHAN{1'b0}};
     //   prod_chroma_xpm_buf_id                <= {2*C_VIDEO_CHAN{1'b0}};
     //   chroma_frmbuf_addr_outthres           <= {C_VIDEO_CHAN*C_FRMBUF_ADDR_WIDTH{1'b0}};
     // end
     // else
     // begin
     //   prod_chroma_xpm_frmbuf_addr_done      <= chroma_xpm_rdata[(XPM_FIFO_DWIDTH-1): (XPM_FIFO_DWIDTH-C_VIDEO_CHAN)];
     //   prod_chroma_xpm_addr_outthreshold_vld <= chroma_xpm_rdata[(XPM_FIFO_DWIDTH-C_VIDEO_CHAN-1):(XPM_FIFO_DWIDTH-(2*C_VIDEO_CHAN))];
     //   prod_chroma_xpm_buf_id                <= chroma_xpm_rdata[(XPM_FIFO_DWIDTH-(2*C_VIDEO_CHAN)-1):(XPM_FIFO_DWIDTH-(4*C_VIDEO_CHAN))];
     //   if ( |(chroma_xpm_rdata[(XPM_FIFO_DWIDTH-C_VIDEO_CHAN-1):(XPM_FIFO_DWIDTH-(2*C_VIDEO_CHAN))]))
     //   begin
     //     chroma_frmbuf_addr_outthres         <= chroma_xpm_rdata[(XPM_FIFO_DWIDTH-(4*C_VIDEO_CHAN)-1):0];
     //   end
     // end
     //end



   // crossing from producer to consumer clock domain
   genvar c;
   generate
      for (c=0;c<C_VIDEO_CHAN;c=c+1) begin: gen_chan

         dff_sync en_sw_rst (.i(S_AXI_SW_ARESET[c]),
                             .clk (S_AXI_ACLK),
                             .o(int_s_axi_sw_areset[c]));

         assign S_AXI_ARESET[c] = S_AXI_ARESETN & (~int_s_axi_sw_areset[c]);


         always @ (posedge S_AXI_ACLK)
         begin
           if (~S_AXI_ARESET[c])
           begin
             int_prod_luma_frmbuf_c0_addr_done_rg[c]   <= 1'b0;
             int_prod_luma_frmbuf_c1_addr_done_rg[c]   <= 1'b0;
             int_prod_luma_frmbuf_c2_addr_done_rg[c]   <= 1'b0;
             int_prod_luma_frmbuf_c3_addr_done_rg[c]   <= 1'b0;
             prod_luma_xpm_frmbuf_addr_done_rg[c]      <= 1'b0; 
             prod_chroma_xpm_frmbuf_addr_done_rg[c]    <= 1'b0; 
             int_prod_chroma_frmbuf_c0_addr_done_rg[c] <= 1'b0;
             int_prod_chroma_frmbuf_c1_addr_done_rg[c] <= 1'b0;
             int_prod_chroma_frmbuf_c2_addr_done_rg[c] <= 1'b0;
             int_prod_chroma_frmbuf_c3_addr_done_rg[c] <= 1'b0;
           end
           else
           begin
             int_prod_luma_frmbuf_c0_addr_done_rg[c]   <= int_prod_luma_frmbuf_c0_addr_done_w[c]  ;
             int_prod_luma_frmbuf_c1_addr_done_rg[c]   <= int_prod_luma_frmbuf_c1_addr_done_w[c]  ;
             int_prod_luma_frmbuf_c2_addr_done_rg[c]   <= int_prod_luma_frmbuf_c2_addr_done_w[c]  ;
             int_prod_luma_frmbuf_c3_addr_done_rg[c]   <= int_prod_luma_frmbuf_c3_addr_done_w[c]  ;
             prod_luma_xpm_frmbuf_addr_done_rg[c]      <= prod_luma_xpm_frmbuf_addr_done_w[c]     ; 
             prod_chroma_xpm_frmbuf_addr_done_rg[c]    <= prod_chroma_xpm_frmbuf_addr_done_w[c]   ; 
             int_prod_chroma_frmbuf_c0_addr_done_rg[c] <= int_prod_chroma_frmbuf_c0_addr_done_w[c];
             int_prod_chroma_frmbuf_c1_addr_done_rg[c] <= int_prod_chroma_frmbuf_c1_addr_done_w[c];
             int_prod_chroma_frmbuf_c2_addr_done_rg[c] <= int_prod_chroma_frmbuf_c2_addr_done_w[c];
             int_prod_chroma_frmbuf_c3_addr_done_rg[c] <= int_prod_chroma_frmbuf_c3_addr_done_w[c];
             
           end
         end

         assign int_prod_luma_frmbuf_c0_addr_done[c]   = ~int_prod_luma_frmbuf_c0_addr_done_rg[c]   & int_prod_luma_frmbuf_c0_addr_done_w[c]  ; 
         assign int_prod_luma_frmbuf_c1_addr_done[c]   = ~int_prod_luma_frmbuf_c1_addr_done_rg[c]   & int_prod_luma_frmbuf_c1_addr_done_w[c]  ; 
         assign int_prod_luma_frmbuf_c2_addr_done[c]   = ~int_prod_luma_frmbuf_c2_addr_done_rg[c]   & int_prod_luma_frmbuf_c2_addr_done_w[c]  ; 
         assign int_prod_luma_frmbuf_c3_addr_done[c]   = ~int_prod_luma_frmbuf_c3_addr_done_rg[c]   & int_prod_luma_frmbuf_c3_addr_done_w[c]  ; 
         assign prod_luma_xpm_frmbuf_addr_done[c]      = ~prod_luma_xpm_frmbuf_addr_done_rg[c]      & prod_luma_xpm_frmbuf_addr_done_w[c]     ;
         assign prod_chroma_xpm_frmbuf_addr_done[c]    = ~prod_chroma_xpm_frmbuf_addr_done_rg[c]    & prod_chroma_xpm_frmbuf_addr_done_w[c]   ;
         assign int_prod_chroma_frmbuf_c0_addr_done[c] = ~int_prod_chroma_frmbuf_c0_addr_done_rg[c] & int_prod_chroma_frmbuf_c0_addr_done_w[c]; 
         assign int_prod_chroma_frmbuf_c1_addr_done[c] = ~int_prod_chroma_frmbuf_c1_addr_done_rg[c] & int_prod_chroma_frmbuf_c1_addr_done_w[c]; 
         assign int_prod_chroma_frmbuf_c2_addr_done[c] = ~int_prod_chroma_frmbuf_c2_addr_done_rg[c] & int_prod_chroma_frmbuf_c2_addr_done_w[c]; 
         assign int_prod_chroma_frmbuf_c3_addr_done[c] = ~int_prod_chroma_frmbuf_c3_addr_done_rg[c] & int_prod_chroma_frmbuf_c3_addr_done_w[c]; 
//	 pulse_crossing luma_addr_done_sync (.i(prod_luma_frmbuf_addr_done[c]),
//					.i_clk (producer_aclk),
//					.i_arst_n (producer_aresetn),
//					//.o_arst_n(S_AXI_ARESETN),
//					.o_arst_n(S_AXI_ARESET[c]),
//					.o_clk (S_AXI_ACLK),
//					.o(int_prod_luma_frmbuf_addr_done[c])); // pulse
//       pulse_crossing luma_c0_addr_done_sync (.i(prod_luma_frmbuf_c0_addr_done[c]),
//      				.i_clk (producer_aclk),
//      				.i_arst_n (producer_aresetn),
//      				//.o_arst_n(S_AXI_ARESETN),
//      				.o_arst_n(S_AXI_ARESET[c]),
//      				.o_clk (S_AXI_ACLK),
//      				.o(int_prod_luma_frmbuf_c0_addr_done[c])); // pulse//####
//       pulse_crossing luma_c1_addr_done_sync (.i(prod_luma_frmbuf_c1_addr_done[c]),
//      				.i_clk (producer_aclk),
//      				.i_arst_n (producer_aresetn),
//      				//.o_arst_n(S_AXI_ARESETN),
//      				.o_arst_n(S_AXI_ARESET[c]),
//      				.o_clk (S_AXI_ACLK),
//      				.o(int_prod_luma_frmbuf_c1_addr_done[c])); // pulse//####
//       pulse_crossing luma_c2_addr_done_sync (.i(prod_luma_frmbuf_c2_addr_done[c]),
//      				.i_clk (producer_aclk),
//      				.i_arst_n (producer_aresetn),
//      				//.o_arst_n(S_AXI_ARESETN),
//      				.o_arst_n(S_AXI_ARESET[c]),
//      				.o_clk (S_AXI_ACLK),
//      				.o(int_prod_luma_frmbuf_c2_addr_done[c])); // pulse//####
//       pulse_crossing luma_c3_addr_done_sync (.i(prod_luma_frmbuf_c3_addr_done[c]),
//      				.i_clk (producer_aclk),
//      				.i_arst_n (producer_aresetn),
//      				//.o_arst_n(S_AXI_ARESETN),
//      				.o_arst_n(S_AXI_ARESET[c]),
//      				.o_clk (S_AXI_ACLK),
//      				.o(int_prod_luma_frmbuf_c3_addr_done[c])); // pulse//####


	//assign int_prod_luma_frmbuf_addr_done_buf0[c]    = ((int_prod_luma_frmbuf_addr_done[c])    & (prod_luma_buf_id[2*c +:2] == 2'd0));//#### 
	assign int_prod_luma_frmbuf_addr_done_buf0[c]    = ((prod_luma_xpm_frmbuf_addr_done[c])    & (prod_luma_xpm_buf_id[2*c +:2] == 2'd0));//#### 
	assign int_prod_luma_frmbuf_c0_addr_done_buf0[c] = ((int_prod_luma_frmbuf_c0_addr_done[c] | prod_luma_xpm_frmbuf_addr_done[c]) & (prod_luma_xpm_buf_id[2*c +:2] == 2'd0));//#### 
	assign int_prod_luma_frmbuf_c1_addr_done_buf0[c] = ((int_prod_luma_frmbuf_c1_addr_done[c] | prod_luma_xpm_frmbuf_addr_done[c]) & (prod_luma_xpm_buf_id[2*c +:2] == 2'd0));//#### 
	assign int_prod_luma_frmbuf_c2_addr_done_buf0[c] = ((int_prod_luma_frmbuf_c2_addr_done[c] | prod_luma_xpm_frmbuf_addr_done[c]) & (prod_luma_xpm_buf_id[2*c +:2] == 2'd0));//#### 
	assign int_prod_luma_frmbuf_c3_addr_done_buf0[c] = ((int_prod_luma_frmbuf_c3_addr_done[c] | prod_luma_xpm_frmbuf_addr_done[c]) & (prod_luma_xpm_buf_id[2*c +:2] == 2'd0));//#### 
	//assign int_prod_luma_frmbuf_addr_done_buf1[c]    = ((int_prod_luma_frmbuf_addr_done[c])    & (prod_luma_buf_id[2*c +:2] == 2'd1));
	assign int_prod_luma_frmbuf_addr_done_buf1[c]    = ((prod_luma_xpm_frmbuf_addr_done[c])    & (prod_luma_xpm_buf_id[2*c +:2] == 2'd1));
	assign int_prod_luma_frmbuf_c0_addr_done_buf1[c] = ((int_prod_luma_frmbuf_c0_addr_done[c] | prod_luma_xpm_frmbuf_addr_done[c]) & (prod_luma_xpm_buf_id[2*c +:2] == 2'd1));//#### 
	assign int_prod_luma_frmbuf_c1_addr_done_buf1[c] = ((int_prod_luma_frmbuf_c1_addr_done[c] | prod_luma_xpm_frmbuf_addr_done[c]) & (prod_luma_xpm_buf_id[2*c +:2] == 2'd1));//####
	assign int_prod_luma_frmbuf_c2_addr_done_buf1[c] = ((int_prod_luma_frmbuf_c2_addr_done[c] | prod_luma_xpm_frmbuf_addr_done[c]) & (prod_luma_xpm_buf_id[2*c +:2] == 2'd1));//####
	assign int_prod_luma_frmbuf_c3_addr_done_buf1[c] = ((int_prod_luma_frmbuf_c3_addr_done[c] | prod_luma_xpm_frmbuf_addr_done[c]) & (prod_luma_xpm_buf_id[2*c +:2] == 2'd1));//####
	//assign int_prod_luma_frmbuf_addr_done_buf2[c]    = ((int_prod_luma_frmbuf_addr_done[c])    & (prod_luma_buf_id[2*c +:2] == 2'd2));
	assign int_prod_luma_frmbuf_addr_done_buf2[c]    = ((prod_luma_xpm_frmbuf_addr_done[c])    & (prod_luma_xpm_buf_id[2*c +:2] == 2'd2));
	assign int_prod_luma_frmbuf_c0_addr_done_buf2[c] = ((int_prod_luma_frmbuf_c0_addr_done[c] | prod_luma_xpm_frmbuf_addr_done[c]) & (prod_luma_xpm_buf_id[2*c +:2] == 2'd2));//#### 
	assign int_prod_luma_frmbuf_c1_addr_done_buf2[c] = ((int_prod_luma_frmbuf_c1_addr_done[c] | prod_luma_xpm_frmbuf_addr_done[c]) & (prod_luma_xpm_buf_id[2*c +:2] == 2'd2));//####
	assign int_prod_luma_frmbuf_c2_addr_done_buf2[c] = ((int_prod_luma_frmbuf_c2_addr_done[c] | prod_luma_xpm_frmbuf_addr_done[c]) & (prod_luma_xpm_buf_id[2*c +:2] == 2'd2));//####
	assign int_prod_luma_frmbuf_c3_addr_done_buf2[c] = ((int_prod_luma_frmbuf_c3_addr_done[c] | prod_luma_xpm_frmbuf_addr_done[c]) & (prod_luma_xpm_buf_id[2*c +:2] == 2'd2));//####

	//assign int_luma_frmbuf_addr_done_1_buf0[c] = ((cons_luma_buf_id[2*c +:2] == 2'd0) & (int_luma_frmbuf_addr_done_1[c] | cons_luma_frmbuf_addr_done_in[c]));//####
	//assign int_luma_frmbuf_addr_done_1_buf1[c] = ((cons_luma_buf_id[2*c +:2] == 2'd1) & (int_luma_frmbuf_addr_done_1[c] | cons_luma_frmbuf_addr_done_in[c]));
	//assign int_luma_frmbuf_addr_done_1_buf2[c] = ((cons_luma_buf_id[2*c +:2] == 2'd2) & (int_luma_frmbuf_addr_done_1[c] | cons_luma_frmbuf_addr_done_in[c]));
	assign int_luma_frmbuf_addr_done_1_buf0[c] = ((cons_luma_buf_id[2*c +:2] == 2'd0) & (luma_frmbuf_addr_done_1[c] | cons_luma_frmbuf_addr_done_in[c]));//####
	assign int_luma_frmbuf_addr_done_1_buf1[c] = ((cons_luma_buf_id[2*c +:2] == 2'd1) & (luma_frmbuf_addr_done_1[c] | cons_luma_frmbuf_addr_done_in[c]));
	assign int_luma_frmbuf_addr_done_1_buf2[c] = ((cons_luma_buf_id[2*c +:2] == 2'd2) & (luma_frmbuf_addr_done_1[c] | cons_luma_frmbuf_addr_done_in[c]));

	//assign int_luma_frmbuf_addr_done_2_buf0[c] = ((cons_luma_buf_id[2*c +:2] == 2'd0) & (int_luma_frmbuf_addr_done_2[c] | cons_luma_frmbuf_addr_done_in[c]));//####
	//assign int_luma_frmbuf_addr_done_2_buf1[c] = ((cons_luma_buf_id[2*c +:2] == 2'd1) & (int_luma_frmbuf_addr_done_2[c] | cons_luma_frmbuf_addr_done_in[c]));
	//assign int_luma_frmbuf_addr_done_2_buf2[c] = ((cons_luma_buf_id[2*c +:2] == 2'd2) & (int_luma_frmbuf_addr_done_2[c] | cons_luma_frmbuf_addr_done_in[c]));
	assign int_luma_frmbuf_addr_done_2_buf0[c] = ((cons_luma_buf_id[2*c +:2] == 2'd0) & (luma_frmbuf_addr_done_2[c] | cons_luma_frmbuf_addr_done_in[c]));//####
	assign int_luma_frmbuf_addr_done_2_buf1[c] = ((cons_luma_buf_id[2*c +:2] == 2'd1) & (luma_frmbuf_addr_done_2[c] | cons_luma_frmbuf_addr_done_in[c]));
	assign int_luma_frmbuf_addr_done_2_buf2[c] = ((cons_luma_buf_id[2*c +:2] == 2'd2) & (luma_frmbuf_addr_done_2[c] | cons_luma_frmbuf_addr_done_in[c]));


	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	 always @(posedge S_AXI_ACLK)
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESET[c])
	   //if (~S_AXI_ARESETN)
	   if (~S_AXI_ARESET[c])
	     int_prod_luma_frmbuf_addr_done_keep_0[c] <= 1'b0;
	   //else if (int_prod_luma_frmbuf_addr_done[c])
	   else if (prod_luma_xpm_frmbuf_addr_done[c])
	     int_prod_luma_frmbuf_addr_done_keep_0[c] <= 1'b1;
	   else if (luma_frmbuf_addr_done_0[c])
	     int_prod_luma_frmbuf_addr_done_keep_0[c] <= 1'b0;
	 

	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	 always @(posedge S_AXI_ACLK)
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESET[c])
	   //if (~S_AXI_ARESETN)
	   if (~S_AXI_ARESET[c])
	   begin
	     int_prod_luma_frmbuf_addr_done_keep_1_buf0[c] <= 1'b0;//####
	     int_prod_luma_frmbuf_addr_done_keep_1_buf1[c] <= 1'b0;
	     int_prod_luma_frmbuf_addr_done_keep_1_buf2[c] <= 1'b0;
	   end
	   //else if ((int_prod_luma_frmbuf_c0_addr_done_buf0[c] & C_VIDEO_CHAN_ID == 0)| 
           //           (int_prod_luma_frmbuf_c2_addr_done_buf0[c] & C_VIDEO_CHAN_ID == 1))
	   //else if ((int_prod_luma_frmbuf_c0_addr_done_buf0[c])| 
           //         (int_prod_luma_frmbuf_c2_addr_done_buf0[c]))
	   else if ((int_prod_luma_frmbuf_addr_done_buf0[c]))
	   begin
	     int_prod_luma_frmbuf_addr_done_keep_1_buf0[c] <= 1'b1;//####
	   end
	   //else if ((int_prod_luma_frmbuf_c0_addr_done_buf1[c] & C_VIDEO_CHAN_ID == 0)| 
           //         (int_prod_luma_frmbuf_c2_addr_done_buf1[c] & C_VIDEO_CHAN_ID == 1))
	   //else if ((int_prod_luma_frmbuf_c0_addr_done_buf1[c])| 
           //         (int_prod_luma_frmbuf_c2_addr_done_buf1[c]))
	   else if ((int_prod_luma_frmbuf_addr_done_buf1[c]))
	   begin
	     int_prod_luma_frmbuf_addr_done_keep_1_buf1[c] <= 1'b1;//####
           end
	   //else if ((int_prod_luma_frmbuf_c0_addr_done_buf2[c] & C_VIDEO_CHAN_ID == 0)| 
           //         (int_prod_luma_frmbuf_c2_addr_done_buf2[c] & C_VIDEO_CHAN_ID == 1))
	   //else if ((int_prod_luma_frmbuf_c0_addr_done_buf2[c])| 
           //         (int_prod_luma_frmbuf_c2_addr_done_buf2[c]))
	   else if ((int_prod_luma_frmbuf_addr_done_buf2[c]))
	   begin
	     int_prod_luma_frmbuf_addr_done_keep_1_buf2[c] <= 1'b1;//####
           end
           //else if (int_luma_frmbuf_addr_done_1[c] & int_luma_frmbuf_addr_done_1_buf0[c])
           else if (int_luma_frmbuf_addr_done_1_buf0[c])
             int_prod_luma_frmbuf_addr_done_keep_1_buf0[c] <= 1'b0;
           //else if (int_luma_frmbuf_addr_done_1[c] & int_luma_frmbuf_addr_done_1_buf1[c])
           else if (int_luma_frmbuf_addr_done_1_buf1[c])
             int_prod_luma_frmbuf_addr_done_keep_1_buf1[c] <= 1'b0;
           //else if (int_luma_frmbuf_addr_done_1[c] & int_luma_frmbuf_addr_done_1_buf2[c])
           else if (int_luma_frmbuf_addr_done_1_buf2[c])
             int_prod_luma_frmbuf_addr_done_keep_1_buf2[c] <= 1'b0;


	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	 always @(posedge S_AXI_ACLK)
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESET[c])
	   //if (~S_AXI_ARESETN)
	   if (~S_AXI_ARESET[c])
	   begin
	     int_prod_luma_frmbuf_addr_done_keep_2_buf0[c] <= 1'b0;//####
	     int_prod_luma_frmbuf_addr_done_keep_2_buf1[c] <= 1'b0;
	     int_prod_luma_frmbuf_addr_done_keep_2_buf2[c] <= 1'b0;
	   end
	   //else if ((int_prod_luma_frmbuf_c1_addr_done_buf0[c] & C_VIDEO_CHAN_ID == 0)|
           //         (int_prod_luma_frmbuf_c3_addr_done_buf0[c] & C_VIDEO_CHAN_ID == 1))
           //else if ((int_prod_luma_frmbuf_c1_addr_done_buf0[c])|
           //         (int_prod_luma_frmbuf_c3_addr_done_buf0[c]))
	   else if ((int_prod_luma_frmbuf_addr_done_buf0[c]))
	   begin
	     int_prod_luma_frmbuf_addr_done_keep_2_buf0[c] <= 1'b1;//####
	   end
	   //else if ((int_prod_luma_frmbuf_c1_addr_done_buf1[c] & C_VIDEO_CHAN_ID == 0)|
           //         (int_prod_luma_frmbuf_c3_addr_done_buf1[c] & C_VIDEO_CHAN_ID == 1))
	   //else if ((int_prod_luma_frmbuf_c1_addr_done_buf1[c])|
           //         (int_prod_luma_frmbuf_c3_addr_done_buf1[c]))
	   else if ((int_prod_luma_frmbuf_addr_done_buf1[c]))
	   begin
	     int_prod_luma_frmbuf_addr_done_keep_2_buf1[c] <= 1'b1;//####
           end
	   //else if ((int_prod_luma_frmbuf_c1_addr_done_buf2[c] & C_VIDEO_CHAN_ID == 0)|
           //         (int_prod_luma_frmbuf_c3_addr_done_buf2[c] & C_VIDEO_CHAN_ID == 1))
	   //else if ((int_prod_luma_frmbuf_c1_addr_done_buf2[c])|
           //         (int_prod_luma_frmbuf_c3_addr_done_buf2[c]))
	   else if ((int_prod_luma_frmbuf_addr_done_buf2[c]))
	   begin
	     int_prod_luma_frmbuf_addr_done_keep_2_buf2[c] <= 1'b1;//####
           end
           //else if (int_luma_frmbuf_addr_done_2[c] & int_luma_frmbuf_addr_done_2_buf0[c])
           else if (int_luma_frmbuf_addr_done_2_buf0[c])
             int_prod_luma_frmbuf_addr_done_keep_2_buf0[c] <= 1'b0;
           //else if (int_luma_frmbuf_addr_done_2[c] & int_luma_frmbuf_addr_done_2_buf1[c])
           else if (int_luma_frmbuf_addr_done_2_buf1[c])
             int_prod_luma_frmbuf_addr_done_keep_2_buf1[c] <= 1'b0;
           //else if (int_luma_frmbuf_addr_done_2[c] & int_luma_frmbuf_addr_done_2_buf2[c])
           else if (int_luma_frmbuf_addr_done_2_buf2[c])
             int_prod_luma_frmbuf_addr_done_keep_2_buf2[c] <= 1'b0;

	 
//	 pulse_crossing chroma_addr_done_sync (.i(prod_chroma_frmbuf_addr_done[c]),
//					.i_clk (producer_aclk),
//					.i_arst_n (producer_aresetn),
//					//.o_arst_n(S_AXI_ARESETN),
//					.o_arst_n(S_AXI_ARESET[c]),
//					.o_clk (S_AXI_ACLK),
//					.o(int_prod_chroma_frmbuf_addr_done[c])); // pulse
//       pulse_crossing chroma_c0_addr_done_sync (.i(prod_chroma_frmbuf_c0_addr_done[c]),
//      				.i_clk (producer_aclk),
//      				.i_arst_n (producer_aresetn),
//      				//.o_arst_n(S_AXI_ARESETN),
//      				.o_arst_n(S_AXI_ARESET[c]),
//      				.o_clk (S_AXI_ACLK),
//      				.o(int_prod_chroma_frmbuf_c0_addr_done[c])); // pulse
//       pulse_crossing chroma_c1_addr_done_sync (.i(prod_chroma_frmbuf_c1_addr_done[c]),
//      				.i_clk (producer_aclk),
//      				.i_arst_n (producer_aresetn),
//      				//.o_arst_n(S_AXI_ARESETN),
//      				.o_arst_n(S_AXI_ARESET[c]),
//      				.o_clk (S_AXI_ACLK),
//      				.o(int_prod_chroma_frmbuf_c1_addr_done[c])); // pulse
//       pulse_crossing chroma_c2_addr_done_sync (.i(prod_chroma_frmbuf_c2_addr_done[c]),
//      				.i_clk (producer_aclk),
//      				.i_arst_n (producer_aresetn),
//      				//.o_arst_n(S_AXI_ARESETN),
//      				.o_arst_n(S_AXI_ARESET[c]),
//      				.o_clk (S_AXI_ACLK),
//      				.o(int_prod_chroma_frmbuf_c2_addr_done[c])); // pulse
//       pulse_crossing chroma_c3_addr_done_sync (.i(prod_chroma_frmbuf_c3_addr_done[c]),
//      				.i_clk (producer_aclk),
//      				.i_arst_n (producer_aresetn),
//      				//.o_arst_n(S_AXI_ARESETN),
//      				.o_arst_n(S_AXI_ARESET[c]),
//      				.o_clk (S_AXI_ACLK),
//      				.o(int_prod_chroma_frmbuf_c3_addr_done[c])); // pulse

	//assign int_prod_chroma_frmbuf_addr_done_buf0[c] = ((prod_chroma_buf_id[2*c +:2] == 2'd0) & int_prod_chroma_frmbuf_addr_done[c]);//####
	assign int_prod_chroma_frmbuf_addr_done_buf0[c]    = ((prod_chroma_xpm_buf_id[2*c +:2] == 2'd0) & prod_chroma_xpm_frmbuf_addr_done[c]);//####
	assign int_prod_chroma_frmbuf_c0_addr_done_buf0[c] = ((prod_chroma_xpm_buf_id[2*c +:2] == 2'd0) & (int_prod_chroma_frmbuf_c0_addr_done[c] | prod_chroma_xpm_frmbuf_addr_done[c]));//####
	assign int_prod_chroma_frmbuf_c1_addr_done_buf0[c] = ((prod_chroma_xpm_buf_id[2*c +:2] == 2'd0) & (int_prod_chroma_frmbuf_c1_addr_done[c] | prod_chroma_xpm_frmbuf_addr_done[c]));//####
	assign int_prod_chroma_frmbuf_c2_addr_done_buf0[c] = ((prod_chroma_xpm_buf_id[2*c +:2] == 2'd0) & (int_prod_chroma_frmbuf_c2_addr_done[c] | prod_chroma_xpm_frmbuf_addr_done[c]));//####
	assign int_prod_chroma_frmbuf_c3_addr_done_buf0[c] = ((prod_chroma_xpm_buf_id[2*c +:2] == 2'd0) & (int_prod_chroma_frmbuf_c3_addr_done[c] | prod_chroma_xpm_frmbuf_addr_done[c]));//####
	//assign int_prod_chroma_frmbuf_addr_done_buf1[c] = ((prod_chroma_buf_id[2*c +:2] == 2'd1) & int_prod_chroma_frmbuf_addr_done[c]);
	assign int_prod_chroma_frmbuf_addr_done_buf1[c]    = ((prod_chroma_xpm_buf_id[2*c +:2] == 2'd1) & prod_chroma_xpm_frmbuf_addr_done[c]);
	assign int_prod_chroma_frmbuf_c0_addr_done_buf1[c] = ((prod_chroma_xpm_buf_id[2*c +:2] == 2'd1) & (int_prod_chroma_frmbuf_c0_addr_done[c] | prod_chroma_xpm_frmbuf_addr_done[c]));//#### 
	assign int_prod_chroma_frmbuf_c1_addr_done_buf1[c] = ((prod_chroma_xpm_buf_id[2*c +:2] == 2'd1) & (int_prod_chroma_frmbuf_c1_addr_done[c] | prod_chroma_xpm_frmbuf_addr_done[c]));//####
	assign int_prod_chroma_frmbuf_c2_addr_done_buf1[c] = ((prod_chroma_xpm_buf_id[2*c +:2] == 2'd1) & (int_prod_chroma_frmbuf_c2_addr_done[c] | prod_chroma_xpm_frmbuf_addr_done[c]));//####
	assign int_prod_chroma_frmbuf_c3_addr_done_buf1[c] = ((prod_chroma_xpm_buf_id[2*c +:2] == 2'd1) & (int_prod_chroma_frmbuf_c3_addr_done[c] | prod_chroma_xpm_frmbuf_addr_done[c]));//####
	//assign int_prod_chroma_frmbuf_addr_done_buf2[c] = ((prod_chroma_buf_id[2*c +:2] == 2'd2) & int_prod_chroma_frmbuf_addr_done[c]);
	assign int_prod_chroma_frmbuf_addr_done_buf2[c]   =  ((prod_chroma_xpm_buf_id[2*c +:2] == 2'd2) & prod_chroma_xpm_frmbuf_addr_done[c]);
	assign int_prod_chroma_frmbuf_c0_addr_done_buf2[c] = ((prod_chroma_xpm_buf_id[2*c +:2] == 2'd2) & (int_prod_chroma_frmbuf_c0_addr_done[c] | prod_chroma_xpm_frmbuf_addr_done[c]));//#### 
	assign int_prod_chroma_frmbuf_c1_addr_done_buf2[c] = ((prod_chroma_xpm_buf_id[2*c +:2] == 2'd2) & (int_prod_chroma_frmbuf_c1_addr_done[c] | prod_chroma_xpm_frmbuf_addr_done[c]));//####
	assign int_prod_chroma_frmbuf_c2_addr_done_buf2[c] = ((prod_chroma_xpm_buf_id[2*c +:2] == 2'd2) & (int_prod_chroma_frmbuf_c2_addr_done[c] | prod_chroma_xpm_frmbuf_addr_done[c]));//####
	assign int_prod_chroma_frmbuf_c3_addr_done_buf2[c] = ((prod_chroma_xpm_buf_id[2*c +:2] == 2'd2) & (int_prod_chroma_frmbuf_c3_addr_done[c] | prod_chroma_xpm_frmbuf_addr_done[c]));//####

	//assign int_chroma_frmbuf_addr_done_1_buf0[c] = ((cons_chroma_buf_id[2*c +:2] == 2'd0) & (int_chroma_frmbuf_addr_done_1[c] | cons_chroma_frmbuf_addr_done_in[c]));//####
	//assign int_chroma_frmbuf_addr_done_1_buf1[c] = ((cons_chroma_buf_id[2*c +:2] == 2'd1) & (int_chroma_frmbuf_addr_done_1[c] | cons_chroma_frmbuf_addr_done_in[c]));
	//assign int_chroma_frmbuf_addr_done_1_buf2[c] = ((cons_chroma_buf_id[2*c +:2] == 2'd2) & (int_chroma_frmbuf_addr_done_1[c] | cons_chroma_frmbuf_addr_done_in[c]));
	assign int_chroma_frmbuf_addr_done_1_buf0[c] = ((cons_chroma_buf_id[2*c +:2] == 2'd0) & (chroma_frmbuf_addr_done_1[c] | cons_chroma_frmbuf_addr_done_in[c]));//####
	assign int_chroma_frmbuf_addr_done_1_buf1[c] = ((cons_chroma_buf_id[2*c +:2] == 2'd1) & (chroma_frmbuf_addr_done_1[c] | cons_chroma_frmbuf_addr_done_in[c]));
	assign int_chroma_frmbuf_addr_done_1_buf2[c] = ((cons_chroma_buf_id[2*c +:2] == 2'd2) & (chroma_frmbuf_addr_done_1[c] | cons_chroma_frmbuf_addr_done_in[c]));

	//assign int_chroma_frmbuf_addr_done_2_buf0[c] = ((cons_chroma_buf_id[2*c +:2] == 2'd0) & (int_chroma_frmbuf_addr_done_2[c] | cons_chroma_frmbuf_addr_done_in[c]));//####
	//assign int_chroma_frmbuf_addr_done_2_buf1[c] = ((cons_chroma_buf_id[2*c +:2] == 2'd1) & (int_chroma_frmbuf_addr_done_2[c] | cons_chroma_frmbuf_addr_done_in[c]));
	//assign int_chroma_frmbuf_addr_done_2_buf2[c] = ((cons_chroma_buf_id[2*c +:2] == 2'd2) & (int_chroma_frmbuf_addr_done_2[c] | cons_chroma_frmbuf_addr_done_in[c]));
	assign int_chroma_frmbuf_addr_done_2_buf0[c] = ((cons_chroma_buf_id[2*c +:2] == 2'd0) & (chroma_frmbuf_addr_done_2[c] | cons_chroma_frmbuf_addr_done_in[c]));//####
	assign int_chroma_frmbuf_addr_done_2_buf1[c] = ((cons_chroma_buf_id[2*c +:2] == 2'd1) & (chroma_frmbuf_addr_done_2[c] | cons_chroma_frmbuf_addr_done_in[c]));
	assign int_chroma_frmbuf_addr_done_2_buf2[c] = ((cons_chroma_buf_id[2*c +:2] == 2'd2) & (chroma_frmbuf_addr_done_2[c] | cons_chroma_frmbuf_addr_done_in[c]));

	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	 always @(posedge S_AXI_ACLK)
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESET[c])
	   //if (~S_AXI_ARESETN)
	   if (~S_AXI_ARESET[c])
	     int_prod_chroma_frmbuf_addr_done_keep_0[c] <= 1'b0;
	   //else if (int_prod_chroma_frmbuf_addr_done[c])
	   else if (prod_chroma_xpm_frmbuf_addr_done[c])
	     int_prod_chroma_frmbuf_addr_done_keep_0[c] <= 1'b1;
	   else if (chroma_frmbuf_addr_done_0[c])
	     int_prod_chroma_frmbuf_addr_done_keep_0[c] <= 1'b0;
	 

	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	 always @(posedge S_AXI_ACLK)
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESET[c])
	   //if (~S_AXI_ARESETN)
	   if (~S_AXI_ARESET[c])
	   begin
	     int_prod_chroma_frmbuf_addr_done_keep_1_buf0[c] <= 1'b0;//####
	     int_prod_chroma_frmbuf_addr_done_keep_1_buf1[c] <= 1'b0;
	     int_prod_chroma_frmbuf_addr_done_keep_1_buf2[c] <= 1'b0;
	   end
	   //else if ((int_prod_chroma_frmbuf_c0_addr_done_buf0[c] & C_VIDEO_CHAN_ID == 0)|
           //         (int_prod_chroma_frmbuf_c2_addr_done_buf0[c] & C_VIDEO_CHAN_ID == 1))
	   //else if ((int_prod_chroma_frmbuf_c0_addr_done_buf0[c])|
           //         (int_prod_chroma_frmbuf_c2_addr_done_buf0[c]))
	   else if ((int_prod_chroma_frmbuf_addr_done_buf0[c]))
	   begin
	     int_prod_chroma_frmbuf_addr_done_keep_1_buf0[c] <= 1'b1;//####
           end
	   //else if ((int_prod_chroma_frmbuf_c0_addr_done_buf1[c] & C_VIDEO_CHAN_ID == 0)|
           //         (int_prod_chroma_frmbuf_c2_addr_done_buf1[c] & C_VIDEO_CHAN_ID == 1))
	   //else if ((int_prod_chroma_frmbuf_c0_addr_done_buf1[c])|
           //         (int_prod_chroma_frmbuf_c2_addr_done_buf1[c]))
	   else if ((int_prod_chroma_frmbuf_addr_done_buf1[c]))
	   begin
	     int_prod_chroma_frmbuf_addr_done_keep_1_buf1[c] <= 1'b1;
           end
	   //else if ((int_prod_chroma_frmbuf_c0_addr_done_buf2[c] & C_VIDEO_CHAN_ID == 0)|
           //         (int_prod_chroma_frmbuf_c2_addr_done_buf2[c] & C_VIDEO_CHAN_ID == 1))
	   //else if ((int_prod_chroma_frmbuf_c0_addr_done_buf2[c])|
           //         (int_prod_chroma_frmbuf_c2_addr_done_buf2[c]))
	   else if ((int_prod_chroma_frmbuf_addr_done_buf2[c]))
	   begin
	     int_prod_chroma_frmbuf_addr_done_keep_1_buf2[c] <= 1'b1;
	   end
           //else if (int_chroma_frmbuf_addr_done_1[c] & int_chroma_frmbuf_addr_done_1_buf0[c])
           else if (int_chroma_frmbuf_addr_done_1_buf0[c])
             int_prod_chroma_frmbuf_addr_done_keep_1_buf0[c] <= 1'b0;
           //else if (int_chroma_frmbuf_addr_done_1[c] & int_chroma_frmbuf_addr_done_1_buf1[c])
           else if (int_chroma_frmbuf_addr_done_1_buf1[c])
             int_prod_chroma_frmbuf_addr_done_keep_1_buf1[c] <= 1'b0;
           //else if (int_chroma_frmbuf_addr_done_1[c] & int_chroma_frmbuf_addr_done_1_buf2[c])
           else if (int_chroma_frmbuf_addr_done_1_buf2[c])
             int_prod_chroma_frmbuf_addr_done_keep_1_buf2[c] <= 1'b0;

	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESET[c])
	 always @(posedge S_AXI_ACLK)
	   //if (~S_AXI_ARESETN)
	   if (~S_AXI_ARESET[c])
	   begin
	     int_prod_chroma_frmbuf_addr_done_keep_2_buf0[c] <= 1'b0;//####
	     int_prod_chroma_frmbuf_addr_done_keep_2_buf1[c] <= 1'b0;
	     int_prod_chroma_frmbuf_addr_done_keep_2_buf2[c] <= 1'b0;
	   end
	   //else if ((int_prod_chroma_frmbuf_c1_addr_done_buf0[c] & C_VIDEO_CHAN_ID == 0)|
           //         (int_prod_chroma_frmbuf_c3_addr_done_buf0[c] & C_VIDEO_CHAN_ID == 1))
	   //else if ((int_prod_chroma_frmbuf_c1_addr_done_buf0[c])|
           //         (int_prod_chroma_frmbuf_c3_addr_done_buf0[c]))
	   else if ((int_prod_chroma_frmbuf_addr_done_buf0[c]))
	   begin
	     int_prod_chroma_frmbuf_addr_done_keep_2_buf0[c] <= 1'b1;//####
           end
	   //else if ((int_prod_chroma_frmbuf_c1_addr_done_buf1[c] & C_VIDEO_CHAN_ID == 0)|
           //         (int_prod_chroma_frmbuf_c3_addr_done_buf1[c] & C_VIDEO_CHAN_ID == 1))
	   //else if ((int_prod_chroma_frmbuf_c1_addr_done_buf1[c])|
           //         (int_prod_chroma_frmbuf_c3_addr_done_buf1[c]))
	   else if ((int_prod_chroma_frmbuf_addr_done_buf1[c]))
	   begin
	     int_prod_chroma_frmbuf_addr_done_keep_2_buf1[c] <= 1'b1;
           end
	   //else if ((int_prod_chroma_frmbuf_c1_addr_done_buf2[c] & C_VIDEO_CHAN_ID == 0)|
           //         (int_prod_chroma_frmbuf_c3_addr_done_buf2[c] & C_VIDEO_CHAN_ID == 1))
	   //else if ((int_prod_chroma_frmbuf_c1_addr_done_buf2[c])|
           //         (int_prod_chroma_frmbuf_c3_addr_done_buf2[c]))
	   else if ((int_prod_chroma_frmbuf_addr_done_buf2[c]))
	   begin
	     int_prod_chroma_frmbuf_addr_done_keep_2_buf2[c] <= 1'b1;
	   end
           //else if (int_chroma_frmbuf_addr_done_2[c] & int_chroma_frmbuf_addr_done_2_buf0[c])
           else if (int_chroma_frmbuf_addr_done_2_buf0[c])
             int_prod_chroma_frmbuf_addr_done_keep_2_buf0[c] <= 1'b0;
           //else if (int_chroma_frmbuf_addr_done_2[c] & int_chroma_frmbuf_addr_done_2_buf1[c])
           else if (int_chroma_frmbuf_addr_done_2_buf1[c])
             int_prod_chroma_frmbuf_addr_done_keep_2_buf1[c] <= 1'b0;
           //else if (int_chroma_frmbuf_addr_done_2[c] & int_chroma_frmbuf_addr_done_2_buf2[c])
           else if (int_chroma_frmbuf_addr_done_2_buf2[c])
             int_prod_chroma_frmbuf_addr_done_keep_2_buf2[c] <= 1'b0;


//	 pulse_crossing luma_outthres_valid_sync (.i(prod_luma_frmbuf_addr_outthres_valid_pulse[c]),
//					.i_clk (producer_aclk),
//					.i_arst_n (producer_aresetn),
//					//.o_arst_n(S_AXI_ARESETN),
//					.o_arst_n(S_AXI_ARESET[c]),
//					.o_clk (S_AXI_ACLK),
//					.o(i_prod_luma_frmbuf_addr_outthres_valid_pulse[c])); // pulse
//
//	 pulse_crossing chroma_outthres_valid_sync (.i(prod_chroma_frmbuf_addr_outthres_valid_pulse[c]),
//					.i_clk (producer_aclk),
//					.i_arst_n (producer_aresetn),
//					//.o_arst_n(S_AXI_ARESETN),
//					.o_arst_n(S_AXI_ARESET[c]),
//					.o_clk (S_AXI_ACLK),
//					.o(i_prod_chroma_frmbuf_addr_outthres_valid_pulse[c])); // pulse

	 
         dff_sync en_sync (.i(en[c]),
			   .clk (S_AXI_ACLK),
			   .o(int_en[c]));

//         dff_sync en_sw_rst (.i(S_AXI_SW_ARESET),
//			     .clk (S_AXI_ACLK),
//			     .o(int_s_axi_sw_areset));
	
	 pulse_crossing luma_addr_valid_sync  (.i (luma_frmbuf_addr_valid_pulse[c]),
					  .i_clk (ctrl_aclk), // This is S_AXI_CTL clock
					  .i_arst_n (ctrl_aresetn),
					  //.o_arst_n (S_AXI_ARESETN),
					  .o_arst_n (S_AXI_ARESET[c]),
					  .o_clk (S_AXI_ACLK),   // This is consumer clock
					  .o (i_luma_frmbuf_addr_valid_pulse[c]));
	 
	 pulse_crossing chroma_addr_valid_sync  (.i (chroma_frmbuf_addr_valid_pulse[c]),
					  .i_clk (ctrl_aclk), // This is S_AXI_CTL clock
					  .i_arst_n (ctrl_aresetn),
					  //.o_arst_n (S_AXI_ARESETN),
					  .o_arst_n (S_AXI_ARESET[c]),
					  .o_clk (S_AXI_ACLK),   // This is consumer clock
					  .o (i_chroma_frmbuf_addr_valid_pulse[c]));
	 
	 always @(posedge S_AXI_ACLK) begin
	    if (int_en[c]) begin
	       i_luma_frmbuf_start_addr[c] <= luma_frmbuf_start_addr[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH];
	       i_luma_frmbuf_end_addr[c] <= luma_frmbuf_end_addr[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH];
	       //i_prod_luma_frmbuf_addr_outthres[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH] <= prod_luma_frmbuf_addr_outthres[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH];

	       i_chroma_frmbuf_start_addr[c] <= chroma_frmbuf_start_addr[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH];
	       i_chroma_frmbuf_end_addr[c] <= chroma_frmbuf_end_addr[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH];
	       //i_prod_chroma_frmbuf_addr_outthres[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH] <= prod_chroma_frmbuf_addr_outthres[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH];

	    end
	 end


         always @ (posedge S_AXI_ACLK)
         begin
           if (~S_AXI_ARESET[c])
           begin
             i_luma_frmbuf_addr_valid_pulse_rg[c]   <= {C_VIDEO_CHAN{1'b0}};
             i_chroma_frmbuf_addr_valid_pulse_rg[c] <= {C_VIDEO_CHAN{1'b0}};
           end
           else
           begin
             i_luma_frmbuf_addr_valid_pulse_rg[c]   <= i_luma_frmbuf_addr_valid_pulse[c];
             i_chroma_frmbuf_addr_valid_pulse_rg[c] <= i_chroma_frmbuf_addr_valid_pulse[c];
           end
         end

         //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESET[c])
	 always @(posedge S_AXI_ACLK)
	   begin
	      //if (S_AXI_ARESETN == 0) begin
	      if (S_AXI_ARESET[c] == 0) begin
		 int_luma_frmbuf_addr_valid[c] <= 0;
	      end
	      else if (luma_frmbuf_addr_next[c]) begin   // clear by address monitor FSM
		 int_luma_frmbuf_addr_valid[c] <= 1'b0;
	      end
	      else if (i_luma_frmbuf_addr_valid_pulse[c]) begin  // set by ring buffer control
		 int_luma_frmbuf_addr_valid[c] <= 1'b1;
	      end
	   end

	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESET[c])
	 always @(posedge S_AXI_ACLK)
	   begin
	      //if (S_AXI_ARESETN == 0) begin
	      if (S_AXI_ARESET[c] == 0) begin
		 int_chroma_frmbuf_addr_valid[c] <= 0;
	      end
	      else if (chroma_frmbuf_addr_next[c]) begin   // clear by address monitor FSM
		 int_chroma_frmbuf_addr_valid[c] <= 1'b0;
	      end
	      else if (i_chroma_frmbuf_addr_valid_pulse[c]) begin  // set by ring buffer control
		 int_chroma_frmbuf_addr_valid[c] <= 1'b1;
	      end
	   end

         always @ (posedge S_AXI_ACLK)
         begin
           if (~S_AXI_ARESET[c])
           begin
             luma_buf_cnt[c]   <= {C_BUF_CNT_WIDTH{1'b0}};
             chroma_buf_cnt[c] <= {C_BUF_CNT_WIDTH{1'b0}};
           end
           else
           begin
             luma_buf_cnt[c]   <= luma_buf_cnt[c] + luma_frmbuf_addr_done[c];
             chroma_buf_cnt[c] <= chroma_buf_cnt[c] + chroma_frmbuf_addr_done[c];
           end
         end

         always @ (posedge S_AXI_ACLK)
         begin
           if (~S_AXI_ARESET[c])
           begin
             luma_buf_rd_cnt[c]   <= {C_RD_BUF_CNT_WIDTH{1'b0}};
             chroma_buf_rd_cnt[c] <= {C_RD_BUF_CNT_WIDTH{1'b0}};
           end
           else
           begin
             luma_buf_rd_cnt[c]   <= luma_buf_rd_cnt1[c] + luma_buf_rd_cnt2[c] + luma_buf_rd_cnt3[c] ;
             chroma_buf_rd_cnt[c] <= chroma_buf_rd_cnt1[c] + chroma_buf_rd_cnt2[c] + chroma_buf_rd_cnt3[c] ;
           end
         end

         always @ (*)
         begin
           luma_buf_rd_cnt3[c]   = cons_luma_buf_rd_cnt_in[c*C_RD_BUF_CNT_WIDTH +: C_RD_BUF_CNT_WIDTH];
           chroma_buf_rd_cnt3[c] = cons_chroma_buf_rd_cnt_in[c*C_RD_BUF_CNT_WIDTH +: C_RD_BUF_CNT_WIDTH];
           cons_luma_buf_rd_cnt_out [c*C_RD_BUF_CNT_WIDTH +: C_RD_BUF_CNT_WIDTH]   = luma_buf_rd_cnt1[c] + 
                                                                                       luma_buf_rd_cnt2[c] ;
           cons_chroma_buf_rd_cnt_out [c*C_RD_BUF_CNT_WIDTH +: C_RD_BUF_CNT_WIDTH] = chroma_buf_rd_cnt1[c] + 
                                                                                       chroma_buf_rd_cnt2[c] ;
         end
	
         always @ (posedge S_AXI_ACLK)
         begin
           if (~S_AXI_ARESET[c])
           begin
             luma_total_buf_rd_cnt_rg[c]       <= {C_RD_BUF_CNT_WIDTH{1'b0}};
             calc_luma_total_buf_rd_cnt1_rg[c] <= {C_RD_BUF_CNT_WIDTH{1'b0}};
             calc_luma_total_buf_rd_cnt2_rg[c] <= {C_RD_BUF_CNT_WIDTH{1'b0}};
           end
           else if (i_luma_frmbuf_addr_valid_pulse_rg[c])
           begin
             luma_total_buf_rd_cnt_rg[c]       <= i_luma_frmbuf_end_addr[c]-i_luma_frmbuf_start_addr[c];
             calc_luma_total_buf_rd_cnt1_rg[c] <= calc_luma_frmbuf_end_addr_1[c] - i_luma_frmbuf_start_addr[c];
             calc_luma_total_buf_rd_cnt2_rg[c] <= calc_luma_frmbuf_end_addr_2[c] - i_luma_frmbuf_start_addr[c];
           end
         end

         assign luma_total_buf_rd_cnt[c]       = {1'b0,luma_total_buf_rd_cnt_rg[c][1 +: (C_RD_BUF_CNT_WIDTH-1)]};
         assign calc_luma_total_buf_rd_cnt1[c] = {1'b0,calc_luma_total_buf_rd_cnt1_rg[c][1 +: (C_RD_BUF_CNT_WIDTH-1)]};
         assign calc_luma_total_buf_rd_cnt2[c] = {1'b0,calc_luma_total_buf_rd_cnt2_rg[c][1 +: (C_RD_BUF_CNT_WIDTH-1)]};

	 always @(posedge S_AXI_ACLK)
	 begin
           if (~S_AXI_ARESET[c])
           begin
             int_luma_frmbuf_start_addr[c] <= {C_FRMBUF_ADDR_WIDTH{1'b0}};
             int_luma_frmbuf_end_addr[c]   <= {C_FRMBUF_ADDR_WIDTH{1'b0}};
           end
	   else if (i_luma_frmbuf_addr_valid_pulse[c])
           begin
             int_luma_frmbuf_start_addr[c]  <= i_luma_frmbuf_start_addr[c];
             int_luma_frmbuf_end_addr[c]    <= i_luma_frmbuf_end_addr[c];
           end
	 end

         assign calc_luma_frmbuf_end_addr_1[c]   = (int_luma_frmbuf_end_addr[c] - 
	                                            ((luma_c0_offset & {32{(C_VIDEO_CHAN_ID == 0)}}) |		//core 0####
						    (luma_c2_offset & {32{(C_VIDEO_CHAN_ID == 1)}}))); // &         // core 2
                                                   //(int_luma_frmbuf_addr_valid[c]);

	assign calc_luma_frmbuf_end_addr_2[c]   = (int_luma_frmbuf_end_addr[c] - 
	                                           ((luma_c1_offset & {32{(C_VIDEO_CHAN_ID == 0)}}) |		//core 1 ####
						   (luma_c3_offset & {32{(C_VIDEO_CHAN_ID == 1)}}) )); // &  	// core 3
                                                  //int_luma_frmbuf_addr_valid[c];


         assign calc_chroma_frmbuf_end_addr_1[c] = (int_chroma_frmbuf_end_addr[c] - 
	                                            ((chroma_c0_offset & {32{(C_VIDEO_CHAN_ID == 0)}}) |        //core 0 ####
						    (chroma_c2_offset & {32{(C_VIDEO_CHAN_ID == 1)}})));// &       //core 2
                                                   //int_chroma_frmbuf_addr_valid[c];

	assign calc_chroma_frmbuf_end_addr_2[c] = (int_chroma_frmbuf_end_addr[c] - 
	                                           ((chroma_c1_offset & {32{(C_VIDEO_CHAN_ID == 0)}}) |		//core 1 ####
						   (chroma_c3_offset & {32{(C_VIDEO_CHAN_ID == 1)}}) )); //&        //core 3
                                                  //int_chroma_frmbuf_addr_valid[c];

         //#### End address calculation per core 

         always @ (posedge S_AXI_ACLK)
         begin
           if (~S_AXI_ARESET[c])
           begin
             chroma_total_buf_rd_cnt_rg[c]       <= {C_RD_BUF_CNT_WIDTH{1'b0}};
             calc_chroma_total_buf_rd_cnt1_rg[c] <= {C_RD_BUF_CNT_WIDTH{1'b0}};
             calc_chroma_total_buf_rd_cnt2_rg[c] <= {C_RD_BUF_CNT_WIDTH{1'b0}};
           end
           else if (i_chroma_frmbuf_addr_valid_pulse_rg[c])
           begin
             chroma_total_buf_rd_cnt_rg[c]       <= i_chroma_frmbuf_end_addr[c]-i_chroma_frmbuf_start_addr[c];
             calc_chroma_total_buf_rd_cnt1_rg[c] <= calc_chroma_frmbuf_end_addr_1[c] - i_chroma_frmbuf_start_addr[c];
             calc_chroma_total_buf_rd_cnt2_rg[c] <= calc_chroma_frmbuf_end_addr_2[c] - i_chroma_frmbuf_start_addr[c];
           end
         end


         assign chroma_total_buf_rd_cnt[c]       = {1'b0,chroma_total_buf_rd_cnt_rg[c][1 +: (C_RD_BUF_CNT_WIDTH-1)]};
         assign calc_chroma_total_buf_rd_cnt1[c] = {1'b0,calc_chroma_total_buf_rd_cnt1_rg[c][1 +: (C_RD_BUF_CNT_WIDTH-1)]};
         assign calc_chroma_total_buf_rd_cnt2[c] = {1'b0,calc_chroma_total_buf_rd_cnt2_rg[c][1 +: (C_RD_BUF_CNT_WIDTH-1)]};

	 always @(posedge S_AXI_ACLK)
         begin
	   if (~S_AXI_ARESET[c])
           begin
             int_chroma_frmbuf_start_addr[c] <= {C_FRMBUF_ADDR_WIDTH{1'b0}};
             int_chroma_frmbuf_end_addr[c]   <= {C_FRMBUF_ADDR_WIDTH{1'b0}};
           end
           else if (i_chroma_frmbuf_addr_valid_pulse[c])
           begin
             int_chroma_frmbuf_start_addr[c]  <= i_chroma_frmbuf_start_addr[c];
             int_chroma_frmbuf_end_addr[c]    <= i_chroma_frmbuf_end_addr[c];
           end
         end

	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
//	 always @(posedge S_AXI_ACLK or negedge S_AXI_ARESET[c])
//	   begin
//	      //if (S_AXI_ARESETN == 0) begin
//	      if (S_AXI_ARESET[c] == 0) begin
//		 int_prod_luma_frmbuf_addr_outthres_valid[c] <= 0;
//	      end
//	      else if (i_prod_luma_frmbuf_addr_outthres_valid_pulse[c]) begin 
//		 int_prod_luma_frmbuf_addr_outthres_valid[c] <= 1'b1;
//	      end
//	      else
//	      begin
//	        int_prod_luma_frmbuf_addr_outthres_valid[c] <= 0;
//	      end
//	   end
//
//	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
//	 always @(posedge S_AXI_ACLK or negedge S_AXI_ARESET[c])
//	   begin
//	      //if (S_AXI_ARESETN == 0) begin
//	      if (S_AXI_ARESET[c] == 0) begin
//		 int_prod_chroma_frmbuf_addr_outthres_valid[c] <= 0;
//	      end
//	      else if (i_prod_chroma_frmbuf_addr_outthres_valid_pulse[c]) begin 
//		 int_prod_chroma_frmbuf_addr_outthres_valid[c] <= 1'b1;
//	      end
//	      else
//	      begin
//	        int_prod_chroma_frmbuf_addr_outthres_valid[c] <= 0;
//	      end
//	   end

	 
//	 always @(posedge S_AXI_ACLK)
//	   begin
//	      if (i_prod_luma_frmbuf_addr_outthres_valid_pulse[c]) begin
//		 int_prod_luma_frmbuf_addr_outthres[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH] <= i_prod_luma_frmbuf_addr_outthres[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH];
//	      end
//	      else if (luma_frmbuf_addr_done[c])
//	      begin
//	        int_prod_luma_frmbuf_addr_outthres[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH] <= {C_FRMBUF_ADDR_WIDTH{1'b0}};
//	      end
//	   end
//
//	 always @(posedge S_AXI_ACLK)
//	   begin
//	      if (i_prod_chroma_frmbuf_addr_outthres_valid_pulse[c]) begin
//		 int_prod_chroma_frmbuf_addr_outthres[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH] <= i_prod_chroma_frmbuf_addr_outthres[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH];
//	      end
//	      else if (chroma_frmbuf_addr_done[c])
//	      begin
//	        int_prod_chroma_frmbuf_addr_outthres[c*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH] <= {C_FRMBUF_ADDR_WIDTH{1'b0}}; 
//	      end
//	   end
	 
      end
   endgenerate
   
   assign cons_luma_ch0_inrange   = ((S_AXI_ARADDR >= int_luma_frmbuf_start_addr[0])   && (S_AXI_ARADDR <= int_luma_frmbuf_end_addr[0])   && (int_luma_frmbuf_addr_valid[0])  );  
   assign cons_luma_ch1_inrange   = ((S_AXI_ARADDR >= int_luma_frmbuf_start_addr[1])   && (S_AXI_ARADDR <= int_luma_frmbuf_end_addr[1])   && (int_luma_frmbuf_addr_valid[1])  );  
   assign cons_luma_ch2_inrange   = ((S_AXI_ARADDR >= int_luma_frmbuf_start_addr[2])   && (S_AXI_ARADDR <= int_luma_frmbuf_end_addr[2])   && (int_luma_frmbuf_addr_valid[2])  );  
   assign cons_luma_ch3_inrange   = ((S_AXI_ARADDR >= int_luma_frmbuf_start_addr[3])   && (S_AXI_ARADDR <= int_luma_frmbuf_end_addr[3])   && (int_luma_frmbuf_addr_valid[3])  );  
   assign cons_chroma_ch0_inrange = ((S_AXI_ARADDR >= int_chroma_frmbuf_start_addr[0]) && (S_AXI_ARADDR <= int_chroma_frmbuf_end_addr[0]) && (int_chroma_frmbuf_addr_valid[0]));  
   assign cons_chroma_ch1_inrange = ((S_AXI_ARADDR >= int_chroma_frmbuf_start_addr[1]) && (S_AXI_ARADDR <= int_chroma_frmbuf_end_addr[1]) && (int_chroma_frmbuf_addr_valid[1]));  
   assign cons_chroma_ch2_inrange = ((S_AXI_ARADDR >= int_chroma_frmbuf_start_addr[2]) && (S_AXI_ARADDR <= int_chroma_frmbuf_end_addr[2]) && (int_chroma_frmbuf_addr_valid[2]));  
   assign cons_chroma_ch3_inrange = ((S_AXI_ARADDR >= int_chroma_frmbuf_start_addr[3]) && (S_AXI_ARADDR <= int_chroma_frmbuf_end_addr[3]) && (int_chroma_frmbuf_addr_valid[3]));  

   //Address decoding to identify video channel ID
   generate
      if (C_DEC_ENC_N == 1) begin: gen_dec_chan_id

         always @(*)
         begin
           luma_chan_dec  = {cons_luma_ch3_inrange,cons_luma_ch2_inrange,
                             cons_luma_ch1_inrange,cons_luma_ch0_inrange};
           case (luma_chan_dec)
             4'b0001:
               S_AXI_AR_LUMA_CHANID = 3'b000;
             4'b0010:
               S_AXI_AR_LUMA_CHANID = 3'b001;
             4'b0100:
               S_AXI_AR_LUMA_CHANID = 3'b010;
             4'b1000:
               S_AXI_AR_LUMA_CHANID = 3'b011;
             4'b0000:
               S_AXI_AR_LUMA_CHANID = 3'b100;
             default:
               begin
                  S_AXI_AR_LUMA_CHANID = 3'b100;
               end
           endcase // case (chan_dec)
         end

         always @(*)
         begin
           chroma_chan_dec  = {cons_chroma_ch3_inrange,cons_chroma_ch2_inrange,
                               cons_chroma_ch1_inrange,cons_chroma_ch0_inrange};
           case (chroma_chan_dec)
             4'b0001:
               S_AXI_AR_CHROMA_CHANID = 3'b000;
             4'b0010:
               S_AXI_AR_CHROMA_CHANID = 3'b001;
             4'b0100:
               S_AXI_AR_CHROMA_CHANID = 3'b010;
             4'b1000:
               S_AXI_AR_CHROMA_CHANID = 3'b011;
             4'b0000:
               S_AXI_AR_CHROMA_CHANID = 3'b100;
             default:
               begin
                  S_AXI_AR_CHROMA_CHANID = 3'b100;
               end
           endcase // case (chan_dec)
         end


        // always @(*) begin
        //    luma_chan_dec[3:0] = 4'b0000;
        //    if (S_AXI_ARADDR >= int_luma_frmbuf_start_addr[C_VIDEO_CHAN_ID] && S_AXI_ARADDR <= int_luma_frmbuf_end_addr[C_VIDEO_CHAN_ID] && int_luma_frmbuf_addr_valid[C_VIDEO_CHAN_ID] == 1) begin
        //       luma_chan_dec[C_VIDEO_CHAN_ID] = 1'b1;
        //       S_AXI_AR_LUMA_CHANID = C_VIDEO_CHAN_ID;
        //    end
        //    else begin
        //       luma_chan_dec[C_VIDEO_CHAN_ID] = 1'b0;
        //       S_AXI_AR_LUMA_CHANID = 3'b100;
        //    end
        // end

        // always @(*) begin
        //    chroma_chan_dec[3:0] = 4'b0000;
        //    if (S_AXI_ARADDR >= int_chroma_frmbuf_start_addr[C_VIDEO_CHAN_ID] && S_AXI_ARADDR <= int_chroma_frmbuf_end_addr[C_VIDEO_CHAN_ID] && int_chroma_frmbuf_addr_valid[C_VIDEO_CHAN_ID] == 1) begin
        //       chroma_chan_dec[C_VIDEO_CHAN_ID] = 1'b1;
        //       S_AXI_AR_CHROMA_CHANID = C_VIDEO_CHAN_ID;
        //    end
        //    else begin
        //       chroma_chan_dec[C_VIDEO_CHAN_ID] = 1'b0;
        //       S_AXI_AR_CHROMA_CHANID = 3'b100;
        //    end
        // end

      end
      else begin: gen_enc_chan_id


	 always @(*) begin
           luma_chan_dec  = {cons_luma_ch3_inrange,cons_luma_ch2_inrange,
                             cons_luma_ch1_inrange,cons_luma_ch0_inrange};
           //luma_chan_dec[3:0] = 4'b0000;

          //for (i=0;i<C_VIDEO_CHAN;i=i+1)
          // //For decoder, there are only two producer blocks always
          // //if (S_AXI_ARID[2:0] == C_SRC_FRAME_DETECT )
          //    luma_chan_dec[i] = S_AXI_ARADDR >= int_luma_frmbuf_start_addr[i] && S_AXI_ARADDR <= int_luma_frmbuf_end_addr[i] && int_luma_frmbuf_addr_valid[i] == 1;
          // //else
          // //luma_chan_dec[i] = 1'b0;
	    
          case (luma_chan_dec)
            4'b0001:
              S_AXI_AR_LUMA_CHANID = 3'b000;
            4'b0010:
              S_AXI_AR_LUMA_CHANID = 3'b001;
            4'b0100:
              S_AXI_AR_LUMA_CHANID = 3'b010;
            4'b1000:
              S_AXI_AR_LUMA_CHANID = 3'b011;
            4'b0000:
              S_AXI_AR_LUMA_CHANID = 3'b100;
            default:
              begin
                 S_AXI_AR_LUMA_CHANID = 3'b100;
                 //synthesis translate_off
                 //if (syn_ip_test_sim.init_done === 1'b1) begin
                 //   $display ("[%m:%0t] ERROR: AXI address decoding error. Cannot match it to any video channel address range. Addr=h%0x, chan_dec=b%0b,luma_frmbuf_start_addr[0]=h%0x,luma_frmbuf_end_addr[0]=h%0x",
                 //     	$time, S_AXI_ARADDR, luma_chan_dec,int_luma_frmbuf_start_addr[0],
                 //     	int_luma_frmbuf_end_addr[0]);
                 //   $stop;
                 //end
                 //synthesis translate_on
              end
          endcase // case (chan_dec)
	 end // always @ (*)
	 

         always @(*) begin
           chroma_chan_dec  = {cons_chroma_ch3_inrange,cons_chroma_ch2_inrange,
                               cons_chroma_ch1_inrange,cons_chroma_ch0_inrange};
           // chroma_chan_dec[3:0] = 4'b0000;
           // 
           // for (i=0;i<C_VIDEO_CHAN;i=i+1)
           // //For decoder, there are only two producer blocks always
           //   //if (S_AXI_ARID[2:0] == C_SRC_FRAME_DETECT)
           //     chroma_chan_dec[i] = S_AXI_ARADDR >= int_chroma_frmbuf_start_addr[i] && S_AXI_ARADDR <= int_chroma_frmbuf_end_addr[i] && int_chroma_frmbuf_addr_valid[i] == 1;
           //   //else
           //     //chroma_chan_dec[i] = 1'b0;
            
            case (chroma_chan_dec)
              4'b0001:
                S_AXI_AR_CHROMA_CHANID = 3'b000;
              4'b0010:
                S_AXI_AR_CHROMA_CHANID = 3'b001;
              4'b0100:
                S_AXI_AR_CHROMA_CHANID = 3'b010;
              4'b1000:
                S_AXI_AR_CHROMA_CHANID = 3'b011;
              4'b0000:
                S_AXI_AR_CHROMA_CHANID = 3'b100;
              default:
                begin
                   S_AXI_AR_CHROMA_CHANID = 3'b100;
                   //synthesis translate_off
                   //if (syn_ip_test_sim.init_done === 1'b1) begin
                   //   $display ("[%m:%0t] ERROR: AXI address decoding error. Cannot match it to any video channel address range. Addr=h%0x, chan_dec=b%0b,chroma_frmbuf_start_addr[0]=h%0x,chroma_frmbuf_end_addr[0]=h%0x",
                   //     	$time, S_AXI_ARADDR, chroma_chan_dec,int_chroma_frmbuf_start_addr[0],
                   //     	int_chroma_frmbuf_end_addr[0]);
                   //   $stop;
                   //end
                   //synthesis translate_on
                end
            endcase // case (chan_dec)
         end // always @ (*)
	 
      end // block: gen_enc_chan_id
   endgenerate
   
   // READY logic back to the AXI slave port
   
   generate
      if (C_DEC_ENC_N == 0) begin: gen_enc_ready
	 
	 assign S_AXI_ARREADY = 
				S_AXI_ARREADY_0 & (S_AXI_ARID[2:0] != C_SRC_FRAME_DETECT)
				  |
				S_AXI_ARREADY_1 & (S_AXI_ARID[2:0] == C_SRC_FRAME_DETECT) & 
				(S_AXI_ARID[3] == 0) &
				(idle_insert_1 == 0)
				  |
				S_AXI_ARREADY_2 & (S_AXI_ARID[2:0] == C_SRC_FRAME_DETECT) & 
				(S_AXI_ARID[3] == 1) &
				(idle_insert_2 == 0);
	 
      end
      else begin: gen_dec_ready
	 
	 assign S_AXI_ARREADY = S_AXI_ARREADY_0 & ~idle_insert_0;
	 
	 
      end
   endgenerate

   // Done to ring buffer to clear valid bit
   assign luma_frmbuf_addr_done_i   = (luma_frmbuf_addr_done_0   & (C_DEC_ENC_N == 1)) | luma_frmbuf_addr_done_1 | luma_frmbuf_addr_done_2;
   assign chroma_frmbuf_addr_done_i = (chroma_frmbuf_addr_done_0 & (C_DEC_ENC_N == 1)) | chroma_frmbuf_addr_done_1 | chroma_frmbuf_addr_done_2;
   always @(posedge S_AXI_ACLK) begin
      luma_frmbuf_addr_done_p <= luma_frmbuf_addr_done_i;
      chroma_frmbuf_addr_done_p <= chroma_frmbuf_addr_done_i;
   end

   assign luma_frmbuf_addr_done = luma_frmbuf_addr_done_i & ~luma_frmbuf_addr_done_p;
   assign chroma_frmbuf_addr_done = chroma_frmbuf_addr_done_i & ~chroma_frmbuf_addr_done_p;
   
   
   // next is to advance the ring buffer after valid bit is cleared by done
   //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
   always @(posedge S_AXI_ACLK)
     begin
	if (~S_AXI_ARESETN) begin
	   luma_frmbuf_addr_next <= 0;
	   chroma_frmbuf_addr_next <= 0;
	end
	else begin
	   luma_frmbuf_addr_next <= luma_frmbuf_addr_done;
	   chroma_frmbuf_addr_next <= chroma_frmbuf_addr_done;
	end
     end

   assign luma_outofrange_c = luma_outofrange_0 | luma_outofrange_1 | luma_outofrange_2;
   assign chroma_outofrange_c = chroma_outofrange_0 | chroma_outofrange_1 | chroma_outofrange_2;

   always @(posedge S_AXI_ACLK) begin
      luma_outofrange_p <= luma_outofrange_c;
      chroma_outofrange_p <= chroma_outofrange_c;
    end
 
   assign luma_outofrange = luma_outofrange_c & ~ luma_outofrange_p;
   assign chroma_outofrange = chroma_outofrange_c & ~ chroma_outofrange_p;
   
  
   // Timeout circuit
   // ---------------------
   
   genvar cc;
   generate
      for (cc=0;cc < C_VIDEO_CHAN; cc = cc + 1) begin: gen_cc
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESET[cc])
	 always @(posedge S_AXI_ACLK)
	   begin
	      //if (~S_AXI_ARESETN) begin
	      if (~S_AXI_ARESET[cc]) begin
		 luma_timeout[cc] <= 1'b0;
		 luma_timeout_counter[cc] <= 24'd0;
		 luma_timeout_en[cc] <= 1'b0;
		 
	      end
	      else if (luma_frmbuf_addr_done[cc]) begin
		 luma_timeout[cc] <= 1'b0;
		 luma_timeout_counter[cc] <= 24'd0;
		 luma_timeout_en[cc] <= 0;
	      end
	      else if (luma_chan_dec[cc] | luma_timeout_en[cc]) begin
		 luma_timeout_en[cc] <= 1'b1;
		 luma_timeout_counter[cc] <= luma_timeout_counter[cc] + 1;
		 if (luma_timeout_counter[cc] == C_TIMEOUT) luma_timeout[cc] <= 1'b1;
	      end
	      else begin
		 luma_timeout[cc] <= 1'b0;
	      end
	   end

	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESET[cc])
	 always @(posedge S_AXI_ACLK)
	   begin
	      //if (~S_AXI_ARESETN) begin
	      if (~S_AXI_ARESET[cc]) begin
		 chroma_timeout[cc] <= 0;
		 chroma_timeout_counter[cc] <= 0;
		 chroma_timeout_en[cc] <= 0;
		 
	      end
	      else if (chroma_frmbuf_addr_done[cc]) begin
		 chroma_timeout[cc] <= 0;
		 chroma_timeout_counter[cc] <= 0;
		 chroma_timeout_en[cc] <= 0;
	      end
	      else if (chroma_chan_dec[cc] | chroma_timeout_en[cc]) begin
		 chroma_timeout_en[cc] <= 1'b1;
		 chroma_timeout_counter[cc] <= chroma_timeout_counter[cc] + 1;
		 if (chroma_timeout_counter[cc] == C_TIMEOUT) chroma_timeout[cc] <= 1'b1;
	      end
	      else begin
		 chroma_timeout[cc] <= 1'b0;
	      end
	   end

      end
   endgenerate
   
   //AXI register slice for Address Read for Encoder or Framebuf_Read
   //-  In decoder case, all read address requests are passed thru register slice (no fifo needed)
   //-  In encoder case, all read address requests w/ non-src frame ID are passed thru register sliace
   //-  Read Data phase are always passed through via register slice

   axi_ar_reg_slice axi_ar_reg_slice 
     (.aclk           (S_AXI_ACLK), 
      .aresetn        (S_AXI_ARESETN), 
      .s_axi_arid     (S_AXI_ARID), //I
      .s_axi_araddr   (S_AXI_ARADDR[63:0]), 
      .s_axi_arlen    (S_AXI_ARLEN[7:0]), 
      .s_axi_arsize   (S_AXI_ARSIZE[2:0]), 
      .s_axi_arburst  (S_AXI_ARBURST[1:0]), 
      .s_axi_arlock   (S_AXI_ARLOCK), 
      .s_axi_arcache  (S_AXI_ARCACHE[3:0]), 
      .s_axi_arprot   (S_AXI_ARPROT[2:0]), 
      .s_axi_arregion (S_AXI_ARREGION[3:0]), 
      .s_axi_arqos    (S_AXI_ARQOS[3:0]), 
      .s_axi_aruser   ({axi_axaddr_burst_len,S_AXI_AR_CHROMA_CHANID[2:0],S_AXI_AR_LUMA_CHANID[2:0]}),  // use ARUSER to pass ARCHANID decoded value
      .s_axi_arvalid  (S_AXI_ARVALID & ((C_DEC_ENC_N == 1) || ((C_DEC_ENC_N == 0) && (S_AXI_ARID[2:0] != C_SRC_FRAME_DETECT)) )),  // I 
      .s_axi_arready  (S_AXI_ARREADY_0),  // O
      
      .s_axi_rid      (S_AXI_RID),  // O
      .s_axi_rdata    (S_AXI_RDATA[127:0]), 
      .s_axi_rresp    (S_AXI_RRESP[1:0]), 
      .s_axi_rlast    (S_AXI_RLAST), 
      .s_axi_rvalid   (S_AXI_RVALID),   // O
      .s_axi_rready   (S_AXI_RREADY),   // I
      
      .m_axi_arid     (s_axi_arid_0),   // O
      .m_axi_araddr   (s_axi_araddr_0), 
      .m_axi_arlen    (s_axi_arlen_0), 
      .m_axi_arsize   (s_axi_arsize_0), 
      .m_axi_arburst  (s_axi_arburst_0), 
      .m_axi_arlock   (s_axi_arlock_0), 
      .m_axi_arcache  (s_axi_arcache_0), 
      .m_axi_arprot   (s_axi_arprot_0), 
      .m_axi_arregion (s_axi_arregion_0), 
      .m_axi_arqos    (s_axi_arqos_0), 
      .m_axi_aruser   ({s_axi_axaddr_burst_len_0,s_axi_aruser_0}),
      .m_axi_arvalid  (s_axi_arvalid_0), // O
      .m_axi_arready  (s_axi_arready_0 & (read_en_0 | (C_DEC_ENC_N==1))), // I
      
      .m_axi_rid      (m_axi_rid),     // I
      .m_axi_rdata    (m_axi_rdata), 
      .m_axi_rresp    (m_axi_rresp), 
      .m_axi_rlast    (m_axi_rlast), 
      .m_axi_rvalid   (m_axi_rvalid),  // I 
      .m_axi_rready   (m_axi_rready)   // O
      );


   // read gating logic for decoder register slice
 


   //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
   always @(posedge S_AXI_ACLK)
     begin
	if (~S_AXI_ARESETN) begin
	   read_en_0 <= 1'b0;
	   luma_frmbuf_addr_done_0 <= 0;
	   chroma_frmbuf_addr_done_0 <= 0;
           int_luma_frmbuf_addr_done_0   <= 0;
           int_chroma_frmbuf_addr_done_0 <= 0;
	   luma_outofrange_0 <= {C_VIDEO_CHAN{1'b0}};
	   chroma_outofrange_0 <= {C_VIDEO_CHAN{1'b0}};
	   ot_luma_buf_id_0 <= 2'b00;
           ot_chroma_buf_id_0 <= 2'b00;
	end
	else if (C_DEC_ENC_N == 0) begin
	   read_en_0 <= 1'b1;  // for encoder, read enable should always be asserted to pass thru non-src frame requests
	   luma_frmbuf_addr_done_0 <= 0;
	   chroma_frmbuf_addr_done_0 <= 0;
           int_luma_frmbuf_addr_done_0   <= 0;
           int_chroma_frmbuf_addr_done_0 <= 0;
	   luma_outofrange_0 <= {C_VIDEO_CHAN{1'b0}};
	   chroma_outofrange_0 <= {C_VIDEO_CHAN{1'b0}};
           luma_buf_rd_cnt0[0]           <= {C_RD_BUF_CNT_WIDTH{1'b0}};
           luma_buf_rd_cnt0[1]           <= {C_RD_BUF_CNT_WIDTH{1'b0}};
           luma_buf_rd_cnt0[2]           <= {C_RD_BUF_CNT_WIDTH{1'b0}};
           luma_buf_rd_cnt0[3]           <= {C_RD_BUF_CNT_WIDTH{1'b0}};
           chroma_buf_rd_cnt0[0]         <= {C_RD_BUF_CNT_WIDTH{1'b0}};
           chroma_buf_rd_cnt0[1]         <= {C_RD_BUF_CNT_WIDTH{1'b0}};
           chroma_buf_rd_cnt0[2]         <= {C_RD_BUF_CNT_WIDTH{1'b0}};
           chroma_buf_rd_cnt0[3]         <= {C_RD_BUF_CNT_WIDTH{1'b0}};

	end
//        else if ( (|luma_frmbuf_addr_done_0 ) | (|chroma_frmbuf_addr_done_0))
//        begin
//	  read_en_0 <= 1'b0; 
//          int_luma_frmbuf_addr_done_0   <= 0;
//          int_chroma_frmbuf_addr_done_0 <= 0;
//	  luma_outofrange_0 <= {C_VIDEO_CHAN{1'b0}};
//	  chroma_outofrange_0 <= {C_VIDEO_CHAN{1'b0}};
//          luma_frmbuf_addr_done_0 <= {C_VIDEO_CHAN{1'b0}};
//          chroma_frmbuf_addr_done_0 <= {C_VIDEO_CHAN{1'b0}};
//          luma_buf_rd_cnt0[0]   <= (luma_buf_rd_cnt0[0] & {C_RD_BUF_CNT_WIDTH{(~luma_frmbuf_addr_done_0[0])}});
//          luma_buf_rd_cnt0[1]   <= (luma_buf_rd_cnt0[1] & {C_RD_BUF_CNT_WIDTH{(~luma_frmbuf_addr_done_0[1])}});
//          luma_buf_rd_cnt0[2]   <= (luma_buf_rd_cnt0[2] & {C_RD_BUF_CNT_WIDTH{(~luma_frmbuf_addr_done_0[2])}});
//          luma_buf_rd_cnt0[3]   <= (luma_buf_rd_cnt0[3] & {C_RD_BUF_CNT_WIDTH{(~luma_frmbuf_addr_done_0[3])}});
//          chroma_buf_rd_cnt0[0] <= (chroma_buf_rd_cnt0[0] & {C_RD_BUF_CNT_WIDTH{(~chroma_frmbuf_addr_done_0[0])}});
//          chroma_buf_rd_cnt0[1] <= (chroma_buf_rd_cnt0[1] & {C_RD_BUF_CNT_WIDTH{(~chroma_frmbuf_addr_done_0[1])}});
//          chroma_buf_rd_cnt0[2] <= (chroma_buf_rd_cnt0[2] & {C_RD_BUF_CNT_WIDTH{(~chroma_frmbuf_addr_done_0[2])}});
//          chroma_buf_rd_cnt0[3] <= (chroma_buf_rd_cnt0[3] & {C_RD_BUF_CNT_WIDTH{(~chroma_frmbuf_addr_done_0[3])}});
//        end
	else if (s_axi_arvalid_0 & s_axi_arready_0) begin
	  read_en_0 <= 1'b0; 
	  //luma_frmbuf_addr_done_0 <= 0;
	  //chroma_frmbuf_addr_done_0 <= 0;
          int_luma_frmbuf_addr_done_0   <= 0;
          int_chroma_frmbuf_addr_done_0 <= 0;
	  luma_outofrange_0 <= {C_VIDEO_CHAN{1'b0}};
	  chroma_outofrange_0 <= {C_VIDEO_CHAN{1'b0}};
          luma_frmbuf_addr_done_0[0]       <= ((((s_axi_araddr_0 + s_axi_axaddr_burst_len_0) == (int_luma_frmbuf_end_addr[0] + 1'b1)) & int_luma_frmbuf_addr_valid[0]) &
                                               ((((luma_buf_rd_cnt[0] + s_axi_axaddr_burst_len_0) >= luma_total_buf_rd_cnt[0]) & (buf_rd_cnt_en[0])) | (~buf_rd_cnt_en[0]))); //####
          luma_frmbuf_addr_done_0[1]       <= ((((s_axi_araddr_0 + s_axi_axaddr_burst_len_0) == (int_luma_frmbuf_end_addr[1] + 1'b1)) & int_luma_frmbuf_addr_valid[1]) &
                                               ((((luma_buf_rd_cnt[1] + s_axi_axaddr_burst_len_0) >= luma_total_buf_rd_cnt[1]) & (buf_rd_cnt_en[1])) | (~buf_rd_cnt_en[1])));
          chroma_frmbuf_addr_done_0[0]     <= ((((s_axi_araddr_0 + s_axi_axaddr_burst_len_0) == (int_chroma_frmbuf_end_addr[0] + 1'b1)) & int_chroma_frmbuf_addr_valid[0]) &
                                               ((((chroma_buf_rd_cnt[0] + s_axi_axaddr_burst_len_0) >= chroma_total_buf_rd_cnt[0]) & (buf_rd_cnt_en[0])) | (~buf_rd_cnt_en[0]))); //####
          chroma_frmbuf_addr_done_0[1]     <= ((((s_axi_araddr_0 + s_axi_axaddr_burst_len_0) == (int_chroma_frmbuf_end_addr[1] + 1'b1)) & int_chroma_frmbuf_addr_valid[1]) &
                                               ((((chroma_buf_rd_cnt[1] + s_axi_axaddr_burst_len_0) >= chroma_total_buf_rd_cnt[1]) & (buf_rd_cnt_en[1])) | (~buf_rd_cnt_en[1])));

          luma_buf_rd_cnt0[0]              <= luma_buf_rd_cnt0[0] + (s_axi_axaddr_burst_len_0 & ({C_BL_WIDTH{s_axi_aruser_0[2:0] == 3'b000}}));
          luma_buf_rd_cnt0[1]              <= luma_buf_rd_cnt0[1] + (s_axi_axaddr_burst_len_0 & ({C_BL_WIDTH{s_axi_aruser_0[2:0] == 3'b001}}));
          luma_buf_rd_cnt0[2]              <= luma_buf_rd_cnt0[2] + (s_axi_axaddr_burst_len_0 & ({C_BL_WIDTH{s_axi_aruser_0[2:0] == 3'b010}}));
          luma_buf_rd_cnt0[3]              <= luma_buf_rd_cnt0[3] + (s_axi_axaddr_burst_len_0 & ({C_BL_WIDTH{s_axi_aruser_0[2:0] == 3'b011}}));

          chroma_buf_rd_cnt0[0]            <= chroma_buf_rd_cnt0[0] + (s_axi_axaddr_burst_len_0 & ({C_BL_WIDTH{s_axi_aruser_0[5:3] == 3'b000}}));
          chroma_buf_rd_cnt0[1]            <= chroma_buf_rd_cnt0[1] + (s_axi_axaddr_burst_len_0 & ({C_BL_WIDTH{s_axi_aruser_0[5:3] == 3'b001}}));
          chroma_buf_rd_cnt0[2]            <= chroma_buf_rd_cnt0[2] + (s_axi_axaddr_burst_len_0 & ({C_BL_WIDTH{s_axi_aruser_0[5:3] == 3'b010}}));
          chroma_buf_rd_cnt0[3]            <= chroma_buf_rd_cnt0[3] + (s_axi_axaddr_burst_len_0 & ({C_BL_WIDTH{s_axi_aruser_0[5:3] == 3'b011}}));

	end
	else if (s_axi_arvalid_0) begin // for decoder, read enable is throttled based on controls from producer side
	   luma_frmbuf_addr_done_0 <= 0;
	   chroma_frmbuf_addr_done_0 <= 0;
           int_luma_frmbuf_addr_done_0   <= 0;
           int_chroma_frmbuf_addr_done_0 <= 0;
	   luma_outofrange_0 <= {C_VIDEO_CHAN{1'b0}};
	   chroma_outofrange_0 <= {C_VIDEO_CHAN{1'b0}};

          luma_buf_rd_cnt0[0]   <= (luma_buf_rd_cnt0[0] & {C_RD_BUF_CNT_WIDTH{(~cons_luma_frmbuf_addr_done_in[0])}});
          luma_buf_rd_cnt0[1]   <= (luma_buf_rd_cnt0[1] & {C_RD_BUF_CNT_WIDTH{(~cons_luma_frmbuf_addr_done_in[1])}});
          luma_buf_rd_cnt0[2]   <= (luma_buf_rd_cnt0[2] & {C_RD_BUF_CNT_WIDTH{(~cons_luma_frmbuf_addr_done_in[2])}});
          luma_buf_rd_cnt0[3]   <= (luma_buf_rd_cnt0[3] & {C_RD_BUF_CNT_WIDTH{(~cons_luma_frmbuf_addr_done_in[3])}});
          chroma_buf_rd_cnt0[0] <= (chroma_buf_rd_cnt0[0] & {C_RD_BUF_CNT_WIDTH{(~cons_chroma_frmbuf_addr_done_in[0])}});
          chroma_buf_rd_cnt0[1] <= (chroma_buf_rd_cnt0[1] & {C_RD_BUF_CNT_WIDTH{(~cons_chroma_frmbuf_addr_done_in[1])}});
          chroma_buf_rd_cnt0[2] <= (chroma_buf_rd_cnt0[2] & {C_RD_BUF_CNT_WIDTH{(~cons_chroma_frmbuf_addr_done_in[2])}});
          chroma_buf_rd_cnt0[3] <= (chroma_buf_rd_cnt0[3] & {C_RD_BUF_CNT_WIDTH{(~cons_chroma_frmbuf_addr_done_in[3])}});


	   case (s_axi_aruser_0)
	     6'b100000: begin
		//if ((s_axi_araddr_0 + s_axi_axaddr_burst_len_0 -1) < int_prod_luma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH])
		if ((int_prod_luma_frmbuf_addr_done_keep_0[0]) | ((s_axi_araddr_0 + s_axi_axaddr_burst_len_0 -1) < luma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH]))
		  begin
		     read_en_0                      <=  1'b1;
		  end
		else
		  luma_outofrange_0[0] <= 1'b1; // error, display overshoot
		
	     end
	     6'b100001: begin
		//if ((s_axi_araddr_0 + s_axi_axaddr_burst_len_0 -1) < int_prod_luma_frmbuf_addr_outthres[C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH])
		if ((int_prod_luma_frmbuf_addr_done_keep_0[1])|((s_axi_araddr_0 + s_axi_axaddr_burst_len_0 -1) < luma_frmbuf_addr_outthres[C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH]))
		  begin
		     read_en_0                      <= 1'b1;
		  end
		else
		  luma_outofrange_0[1] <= 1'b1;
		
	     end
	     6'b000100: begin
		//if ((s_axi_araddr_0 + s_axi_axaddr_burst_len_0 -1) < int_prod_chroma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH])
		if ((int_prod_chroma_frmbuf_addr_done_keep_0[0])|((s_axi_araddr_0 + s_axi_axaddr_burst_len_0 -1) < chroma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH]))
		  begin
		     read_en_0                        <= 1'b1;
		  end
		else
		  chroma_outofrange_0[0] <= 1'b1;
		
	     end
	     6'b001100: begin
		//if ((s_axi_araddr_0 + s_axi_axaddr_burst_len_0 -1) < int_prod_chroma_frmbuf_addr_outthres[C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH])
		if ((int_prod_chroma_frmbuf_addr_done_keep_0[1])|((s_axi_araddr_0 + s_axi_axaddr_burst_len_0 -1) < chroma_frmbuf_addr_outthres[C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH]))
		  begin
		     read_en_0                        <= 1'b1;
		  end
		else
		  chroma_outofrange_0[1] <= 1'b1;
	     end
	     6'b100100: begin
		read_en_0 <= 1'b1; // let data go thru if they're not in any video channel region
		luma_frmbuf_addr_done_0 <= 0;
		chroma_frmbuf_addr_done_0 <= 0;
                int_luma_frmbuf_addr_done_0 <= 0;
                int_chroma_frmbuf_addr_done_0 <= 0;
		luma_outofrange_0 <= 2'b11;
		chroma_outofrange_0 <= 2'b11;

		//synthesis translate_off
		// In decoder-display case, this is illegal
		$display ("[%m:%0t] ERROR:  regslice address requests received but not in any filled video channel region. Consumer port = %0d, Addr=%0x. Check if this is a legal case.",
			  $time, C_VIDEO_CHAN_ID, s_axi_araddr_0);
		$stop;
		//synthesis translate_on 	      

	     end

	     default: begin
		read_en_0 <= 1'b1; // let data go thru when both luma and chroma addresses in range
		//luma_frmbuf_addr_done_0 <= {C_VIDEO_CHAN{1'b1}};
		//chroma_frmbuf_addr_done_0 <= {C_VIDEO_CHAN{1'b1}};
                //int_luma_frmbuf_addr_done_0   <= {C_VIDEO_CHAN{1'b1}};
                //int_chroma_frmbuf_addr_done_0 <= {C_VIDEO_CHAN{1'b1}};
		luma_frmbuf_addr_done_0 <= {C_VIDEO_CHAN{1'b0}};
		chroma_frmbuf_addr_done_0 <= {C_VIDEO_CHAN{1'b0}};
                int_luma_frmbuf_addr_done_0   <= {C_VIDEO_CHAN{1'b0}};
                int_chroma_frmbuf_addr_done_0 <= {C_VIDEO_CHAN{1'b0}};
		luma_outofrange_0 <= 2'b11;
		chroma_outofrange_0 <= 2'b11;

		//synthesis translate_off
		$display ("[%m:%0t] ERROR: regslice address requests received but shown both luma and chroma addresses in range. Addr=%0x. This is illegal case.",
			  $time, s_axi_araddr_0);
		$stop;
		//synthesis translate_on 	      
	     end
	   endcase // case (s_axi_aruser_0)
	end // if (s_axi_arvalid_0)
	else begin
	   read_en_0 <= 1'b0; // deassert to prevent passing the head data of next request
	   luma_frmbuf_addr_done_0 <= 0;
	   chroma_frmbuf_addr_done_0 <= 0;
           int_luma_frmbuf_addr_done_0   <= 0;
           int_chroma_frmbuf_addr_done_0 <= 0;
	   luma_outofrange_0 <= {C_VIDEO_CHAN{1'b0}};
	   chroma_outofrange_0 <= {C_VIDEO_CHAN{1'b0}};
           ot_luma_buf_id_0 <= 2'b00;
           ot_chroma_buf_id_0 <= 2'b00;
	end
     end // always @ (posedge S_AXI_ACLK or negedge S_AXI_ARESETN)

   // Record previous channel status
   //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
   always @(posedge S_AXI_ACLK)
     begin
	if (~S_AXI_ARESETN) begin
	   S_AXI_ARREADY_0_r <= 1'b0;
	   S_AXI_AR_LUMA_CHANID_0_r <= 3'b100;
	   S_AXI_AR_CHROMA_CHANID_0_r <= 3'b100;

	end
	else if (C_DEC_ENC_N == 1) begin
	   S_AXI_ARREADY_0_r <= S_AXI_ARREADY_0 & ~idle_insert_0;
	   if (S_AXI_ARVALID ) begin
	      S_AXI_AR_LUMA_CHANID_0_r <= S_AXI_AR_LUMA_CHANID;
	      S_AXI_AR_CHROMA_CHANID_0_r <= S_AXI_AR_CHROMA_CHANID;
	   end
	   else begin
	      S_AXI_AR_LUMA_CHANID_0_r <= 3'b100;
	      S_AXI_AR_CHROMA_CHANID_0_r <= 3'b100;
	   end
	end
     end

   // Idle insertion when switching videl channel in back-to-back requests
   // Since gating logic requires 1 cycle of latency, if channel switches in the middle of continuous request,
   // the "head" of new channel request can be passed thru accidentally. To prevent this,
   // insert an idle cycle when such condition is detected.
   //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
   always @(posedge S_AXI_ACLK)
     begin
	if (~S_AXI_ARESETN)
	  idle_insert_0 <= 1'b0;
	else if ( (C_DEC_ENC_N == 1) 
		  & S_AXI_ARVALID_r & S_AXI_ARREADY_0_r & S_AXI_ARVALID 
		  & (
		     (S_AXI_AR_LUMA_CHANID != S_AXI_AR_LUMA_CHANID_0_r) & ~S_AXI_AR_LUMA_CHANID[2] & ~S_AXI_AR_LUMA_CHANID_0_r[2]
		     | (S_AXI_AR_CHROMA_CHANID != S_AXI_AR_CHROMA_CHANID_0_r) & ~S_AXI_AR_CHROMA_CHANID[2] & ~S_AXI_AR_LUMA_CHANID_0_r[2])
		  )
	  idle_insert_0 <= 1'b1;
	else
	  idle_insert_0 <= 1'b0;
     end

   
   // AXI FIFOs for read address requests, one for each channel
   // Note that at any given time only two video channes will be active on the AXI interface, but which of two can vary and
   // requires address decoding.
   //-  In decoder case, NO requests need to store in these FIFOs
   //-  In encoder case, all read address requests w/ src frame ID are divided based on core ID and dispatched to FIFOs

   generate
      if (C_DEC_ENC_N == 0) begin: gen_fifo_1

	 // FIFO1
	 axi_mm_rfifo_128x100b
	   axi_mm_rfifo_128x100b_0
	     (.s_aclk     (S_AXI_ACLK), 
	      //.s_aresetn  (S_AXI_ARESETN), 
	      //.s_aresetn  (S_AXI_ARESET), 
	      .s_aresetn  (f1_rst), 
	      .s_axi_arid     (S_AXI_ARID[3:0]), 
	      .s_axi_araddr   (S_AXI_ARADDR[63:0]), 
	      .s_axi_arlen    (S_AXI_ARLEN[7:0]), 
	      .s_axi_arsize   (S_AXI_ARSIZE[2:0]), 
	      .s_axi_arburst  (S_AXI_ARBURST[1:0]), 
	      .s_axi_arlock   (S_AXI_ARLOCK), 
	      .s_axi_arcache  (S_AXI_ARCACHE[3:0]), 
	      .s_axi_arprot   (S_AXI_ARPROT[2:0]), 
	      .s_axi_arregion (S_AXI_ARREGION[3:0]), 
	      .s_axi_arqos    (S_AXI_ARQOS[3:0]),
 	      .s_axi_aruser   ({axi_axaddr_burst_len,S_AXI_AR_CHROMA_CHANID[2:0],S_AXI_AR_LUMA_CHANID[2:0]}),
	      .s_axi_arvalid  (S_AXI_ARVALID & 
			       (C_DEC_ENC_N == 0) &
			       (S_AXI_ARID[2:0] == C_SRC_FRAME_DETECT)  & 
			       (S_AXI_ARID[3] == 0) 
 			       ), 
	      .s_axi_arready  (S_AXI_ARREADY_1),  // O 
	      
	      .s_axi_rid      (),   // O
	      .s_axi_rdata    (), 
	      .s_axi_rresp    (), 
	      .s_axi_rlast    (), 
	      .s_axi_rvalid   (),     // O
	      .s_axi_rready   (1'b0),     // I
	      
//              .m_axi_arid     (f1_s_axi_arid_1), 
//              .m_axi_araddr   (f1_s_axi_araddr_1), 
//              .m_axi_arlen    (f1_s_axi_arlen_1), 
//              .m_axi_arsize   (f1_s_axi_arsize_1), 
//              .m_axi_arburst  (f1_s_axi_arburst_1), 
//              .m_axi_arlock   (f1_s_axi_arlock_1), 
//              .m_axi_arcache  (f1_s_axi_arcache_1), 
//              .m_axi_arprot   (f1_s_axi_arprot_1), 
//              .m_axi_arregion (f1_s_axi_arregion_1), 
//              .m_axi_arqos    (f1_s_axi_arqos_1),
//              .m_axi_aruser   (f1_s_axi_aruser_1), //{s_axi_axaddr_burst_len_1,s_axi_aruser_1}),
//              .m_axi_arvalid  (f1_s_axi_arvalid_1),  // O
//              //.m_axi_arready  (f1_s_axi_arready_1 & fifo_read_en_1), // I
//              .m_axi_arready  (f1_s_axi_arready_1), // I

              .m_axi_arid     (s_axi_arid_1), 
              .m_axi_araddr   (s_axi_araddr_1), 
              .m_axi_arlen    (s_axi_arlen_1), 
              .m_axi_arsize   (s_axi_arsize_1), 
              .m_axi_arburst  (s_axi_arburst_1), 
              .m_axi_arlock   (s_axi_arlock_1), 
              .m_axi_arcache  (s_axi_arcache_1), 
              .m_axi_arprot   (s_axi_arprot_1), 
              .m_axi_arregion (s_axi_arregion_1), 
              .m_axi_arqos    (s_axi_arqos_1),
              //.m_axi_aruser   (s_axi_aruser_1), //{s_axi_axaddr_burst_len_1,s_axi_aruser_1}),
              .m_axi_aruser   ({s_axi_axaddr_burst_len_1,s_axi_aruser_1}),
              .m_axi_arvalid  (s_axi_arvalid_1),  // O
              .m_axi_arready  (s_axi_arready_1 & fifo_read_en_1), // I
              //.m_axi_arready  (s_axi_arready_1), // I

	      .m_axi_rid      (4'd0  ), 
	      .m_axi_rdata    (128'd0), 
	      .m_axi_rresp    (2'd0  ), 
	      .m_axi_rlast    (1'b0  ), 
	      .m_axi_rvalid   (1'b0  ), 
	      .m_axi_rready   (      )
	      );
	 

//   axi_ar_reg_slice fifo1_axi_ar_reg_slice 
//     (.aclk           (S_AXI_ACLK), 
//      .aresetn        (f1_rst), 
//      .s_axi_arid     (f1_s_axi_arid_1), //I
//      .s_axi_araddr   (f1_s_axi_araddr_1), 
//      .s_axi_arlen    (f1_s_axi_arlen_1), 
//      .s_axi_arsize   (f1_s_axi_arsize_1), 
//      .s_axi_arburst  (f1_s_axi_arburst_1), 
//      .s_axi_arlock   (f1_s_axi_arlock_1), 
//      .s_axi_arcache  (f1_a_axi_arcache_1), 
//      .s_axi_arprot   (f1_s_axi_arprot_1), 
//      .s_axi_arregion (f1_s_axi_arregion_1), 
//      .s_axi_arqos    (f1_s_axi_arqos_1), 
//      .s_axi_aruser   (f1_s_axi_aruser_1),  // use ARUSER to pass ARCHANID decoded value
//      .s_axi_arvalid  (f1_s_axi_arvalid_1),  // I 
//      .s_axi_arready  (f1_s_axi_arready_1),  // O
//      
//      .s_axi_rid      ( ),  // O
//      .s_axi_rdata    ( ), 
//      .s_axi_rresp    ( ), 
//      .s_axi_rlast    ( ), 
//      .s_axi_rvalid   ( ),   // O
//      .s_axi_rready   ( ),   // I
//      
//      .m_axi_arid     (s_axi_arid_1),   // O
//      .m_axi_araddr   (s_axi_araddr_1), 
//      .m_axi_arlen    (s_axi_arlen_1), 
//      .m_axi_arsize   (s_axi_arsize_1), 
//      .m_axi_arburst  (s_axi_arburst_1), 
//      .m_axi_arlock   (s_axi_arlock_1), 
//      .m_axi_arcache  (s_axi_arcache_1), 
//      .m_axi_arprot   (s_axi_arprot_1), 
//      .m_axi_arregion (s_axi_arregion_1), 
//      .m_axi_arqos    (s_axi_arqos_1), 
//      .m_axi_aruser   ({s_axi_axaddr_burst_len_1,s_axi_aruser_1}),
//      .m_axi_arvalid  (s_axi_arvalid_1), // O
//      .m_axi_arready  (s_axi_arready_1 & fifo_read_en_1), // I
//      //.m_axi_arready  (s_axi_arready_1 & fifo_read_en_1_rg), // I
//      
//      .m_axi_rid      (0),     // I
//      .m_axi_rdata    (0), 
//      .m_axi_rresp    (0), 
//      .m_axi_rlast    (0), 
//      .m_axi_rvalid   (0),  // I 
//      .m_axi_rready   (0)   // O
//      );


	 //always @(posedge S_AXI_ACLK or negedge f1_rst)
	 always @(posedge S_AXI_ACLK)
         begin
	   if (~f1_rst) 
           begin
             fifo_read_en_1_rg <= 1'b0;
           end
           else
           begin
             fifo_read_en_1_rg <= fifo_read_en_1;
           end
         end
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESET)
	 //always @(posedge S_AXI_ACLK or negedge f1_rst)
	 always @(posedge S_AXI_ACLK)
	   begin
	      //if (~S_AXI_ARESETN) begin
	      //if (~S_AXI_ARESET) begin
	      if (~f1_rst) begin
		 fifo_read_en_1                <= 1'b0;
		 luma_frmbuf_addr_done_1       <= 0;
		 luma_frmbuf_addr_done_1_new   <= 0;
		 chroma_frmbuf_addr_done_1     <= 0;
		 chroma_frmbuf_addr_done_1_new <= 0;
		 int_luma_frmbuf_addr_done_1   <= 0;
		 int_chroma_frmbuf_addr_done_1 <= 0;
		 luma_outofrange_1             <= {C_VIDEO_CHAN{1'b0}};
		 chroma_outofrange_1           <= {C_VIDEO_CHAN{1'b0}};
                 ot_luma_buf_id_1              <= 2'b00;
                 ot_chroma_buf_id_1            <= 2'b00;
                 luma_buf_rd_cnt1[0]           <= {C_RD_BUF_CNT_WIDTH{1'b0}};
                 luma_buf_rd_cnt1[1]           <= {C_RD_BUF_CNT_WIDTH{1'b0}};
                 luma_buf_rd_cnt1[2]           <= {C_RD_BUF_CNT_WIDTH{1'b0}};
                 luma_buf_rd_cnt1[3]           <= {C_RD_BUF_CNT_WIDTH{1'b0}};
                 chroma_buf_rd_cnt1[0]         <= {C_RD_BUF_CNT_WIDTH{1'b0}};
                 chroma_buf_rd_cnt1[1]         <= {C_RD_BUF_CNT_WIDTH{1'b0}};
                 chroma_buf_rd_cnt1[2]         <= {C_RD_BUF_CNT_WIDTH{1'b0}};
                 chroma_buf_rd_cnt1[3]         <= {C_RD_BUF_CNT_WIDTH{1'b0}};
	      end
	      else if (s_axi_arvalid_1 & s_axi_arready_1) begin
		 fifo_read_en_1 <= 1'b0; 
		 luma_outofrange_1 <= {C_VIDEO_CHAN{1'b0}};
		 chroma_outofrange_1 <= {C_VIDEO_CHAN{1'b0}};
	  	 int_luma_frmbuf_addr_done_1[0] <= (((s_axi_araddr_1 + s_axi_axaddr_burst_len_1) == (calc_luma_frmbuf_end_addr_1[0] + 1'b1)) &
		                                    ((((luma_buf_rd_cnt[0] + s_axi_axaddr_burst_len_1) >= calc_luma_total_buf_rd_cnt1[0]) & (buf_rd_cnt_en[0])) | (~buf_rd_cnt_en[0]))); //####
		 int_luma_frmbuf_addr_done_1[1] <= (((s_axi_araddr_1 + s_axi_axaddr_burst_len_1) == (calc_luma_frmbuf_end_addr_1[1] + 1'b1)) &
		                                    ((((luma_buf_rd_cnt[1] + s_axi_axaddr_burst_len_1) >= calc_luma_total_buf_rd_cnt1[1]) & (buf_rd_cnt_en[1])) | (~buf_rd_cnt_en[1]))); //####
		 int_luma_frmbuf_addr_done_1[2] <= (((s_axi_araddr_1 + s_axi_axaddr_burst_len_1) == (calc_luma_frmbuf_end_addr_1[2] + 1'b1)) &
		                                    ((((luma_buf_rd_cnt[2] + s_axi_axaddr_burst_len_1) >= calc_luma_total_buf_rd_cnt1[2]) & (buf_rd_cnt_en[2])) | (~buf_rd_cnt_en[2]))); //####
		 int_luma_frmbuf_addr_done_1[3] <= (((s_axi_araddr_1 + s_axi_axaddr_burst_len_1) == (calc_luma_frmbuf_end_addr_1[3] + 1'b1)) &
		                                    ((((luma_buf_rd_cnt[3] + s_axi_axaddr_burst_len_1) >= calc_luma_total_buf_rd_cnt1[3]) & (buf_rd_cnt_en[3])) | (~buf_rd_cnt_en[3]))); //####

                 luma_frmbuf_addr_done_1[0]     <= ((((s_axi_araddr_1 + s_axi_axaddr_burst_len_1) == (int_luma_frmbuf_end_addr[0] + 1'b1)) & int_luma_frmbuf_addr_valid[0]) &
                                                    ((((luma_buf_rd_cnt[0] + s_axi_axaddr_burst_len_1) >= luma_total_buf_rd_cnt[0]) & (buf_rd_cnt_en[0])) | (~buf_rd_cnt_en[0]))); //####
                 luma_frmbuf_addr_done_1[1]     <= ((((s_axi_araddr_1 + s_axi_axaddr_burst_len_1) == (int_luma_frmbuf_end_addr[1] + 1'b1)) & int_luma_frmbuf_addr_valid[1]) &
                                                    ((((luma_buf_rd_cnt[1] + s_axi_axaddr_burst_len_1) >= luma_total_buf_rd_cnt[1]) & (buf_rd_cnt_en[1])) | (~buf_rd_cnt_en[1]))); //####
                 luma_frmbuf_addr_done_1[2]     <= ((((s_axi_araddr_1 + s_axi_axaddr_burst_len_1) == (int_luma_frmbuf_end_addr[2] + 1'b1)) & int_luma_frmbuf_addr_valid[2]) &
                                                    ((((luma_buf_rd_cnt[2] + s_axi_axaddr_burst_len_1) >= luma_total_buf_rd_cnt[2]) & (buf_rd_cnt_en[2])) | (~buf_rd_cnt_en[2]))); //####
                 luma_frmbuf_addr_done_1[3]     <= ((((s_axi_araddr_1 + s_axi_axaddr_burst_len_1) == (int_luma_frmbuf_end_addr[3] + 1'b1)) & int_luma_frmbuf_addr_valid[3]) &
                                                    ((((luma_buf_rd_cnt[3] + s_axi_axaddr_burst_len_1) >= luma_total_buf_rd_cnt[3]) & (buf_rd_cnt_en[3])) | (~buf_rd_cnt_en[3]))); //####

                 int_chroma_frmbuf_addr_done_1[0] <= (((s_axi_araddr_1 + s_axi_axaddr_burst_len_1) == (calc_chroma_frmbuf_end_addr_1[0] + 1'b1)) &
                                                      ((((chroma_buf_rd_cnt[0] + s_axi_axaddr_burst_len_1) >= calc_chroma_total_buf_rd_cnt1[0]) & (buf_rd_cnt_en[0])) | (~buf_rd_cnt_en[0]))); //####
                 int_chroma_frmbuf_addr_done_1[1] <= (((s_axi_araddr_1 + s_axi_axaddr_burst_len_1) == (calc_chroma_frmbuf_end_addr_1[1] + 1'b1)) &
                                                      ((((chroma_buf_rd_cnt[1] + s_axi_axaddr_burst_len_1) >= calc_chroma_total_buf_rd_cnt1[1]) & (buf_rd_cnt_en[1])) | (~buf_rd_cnt_en[1]))); //####
                 int_chroma_frmbuf_addr_done_1[2] <= (((s_axi_araddr_1 + s_axi_axaddr_burst_len_1) == (calc_chroma_frmbuf_end_addr_1[2] + 1'b1)) &
                                                      ((((chroma_buf_rd_cnt[2] + s_axi_axaddr_burst_len_1) >= calc_chroma_total_buf_rd_cnt1[2]) & (buf_rd_cnt_en[2])) | (~buf_rd_cnt_en[2]))); //####
                 int_chroma_frmbuf_addr_done_1[3] <= (((s_axi_araddr_1 + s_axi_axaddr_burst_len_1) == (calc_chroma_frmbuf_end_addr_1[3] + 1'b1)) &
                                                      ((((chroma_buf_rd_cnt[3] + s_axi_axaddr_burst_len_1) >= calc_chroma_total_buf_rd_cnt1[3]) & (buf_rd_cnt_en[3])) | (~buf_rd_cnt_en[3]))); //####


                 chroma_frmbuf_addr_done_1[0]     <= ((((s_axi_araddr_1 + s_axi_axaddr_burst_len_1) == (int_chroma_frmbuf_end_addr[0] + 1'b1)) & int_chroma_frmbuf_addr_valid[0]) &
                                                      ((((chroma_buf_rd_cnt[0] + s_axi_axaddr_burst_len_1) >= chroma_total_buf_rd_cnt[0]) & (buf_rd_cnt_en[0])) | (~buf_rd_cnt_en[0]))); //####
                 chroma_frmbuf_addr_done_1[1]     <= ((((s_axi_araddr_1 + s_axi_axaddr_burst_len_1) == (int_chroma_frmbuf_end_addr[1] + 1'b1)) & int_chroma_frmbuf_addr_valid[1]) &
                                                      ((((chroma_buf_rd_cnt[1] + s_axi_axaddr_burst_len_1) >= chroma_total_buf_rd_cnt[1]) & (buf_rd_cnt_en[1])) | (~buf_rd_cnt_en[1]))); //####
                 chroma_frmbuf_addr_done_1[2]     <= ((((s_axi_araddr_1 + s_axi_axaddr_burst_len_1) == (int_chroma_frmbuf_end_addr[2] + 1'b1)) & int_chroma_frmbuf_addr_valid[2]) &
                                                      ((((chroma_buf_rd_cnt[2] + s_axi_axaddr_burst_len_1) >= chroma_total_buf_rd_cnt[2]) & (buf_rd_cnt_en[2])) | (~buf_rd_cnt_en[2]))); //####
                 chroma_frmbuf_addr_done_1[3]     <= ((((s_axi_araddr_1 + s_axi_axaddr_burst_len_1) == (int_chroma_frmbuf_end_addr[3] + 1'b1)) & int_chroma_frmbuf_addr_valid[3]) &
                                                      ((((chroma_buf_rd_cnt[3] + s_axi_axaddr_burst_len_1) >= chroma_total_buf_rd_cnt[3]) & (buf_rd_cnt_en[3])) | (~buf_rd_cnt_en[3]))); //####

                 luma_buf_rd_cnt1[0]              <= luma_buf_rd_cnt1[0] + (s_axi_axaddr_burst_len_1 & ({C_BL_WIDTH{s_axi_aruser_1[2:0] == 3'b000}}));
                 luma_buf_rd_cnt1[1]              <= luma_buf_rd_cnt1[1] + (s_axi_axaddr_burst_len_1 & ({C_BL_WIDTH{s_axi_aruser_1[2:0] == 3'b001}}));
                 luma_buf_rd_cnt1[2]              <= luma_buf_rd_cnt1[2] + (s_axi_axaddr_burst_len_1 & ({C_BL_WIDTH{s_axi_aruser_1[2:0] == 3'b010}}));
                 luma_buf_rd_cnt1[3]              <= luma_buf_rd_cnt1[3] + (s_axi_axaddr_burst_len_1 & ({C_BL_WIDTH{s_axi_aruser_1[2:0] == 3'b011}}));

                 chroma_buf_rd_cnt1[0]            <= chroma_buf_rd_cnt1[0] + (s_axi_axaddr_burst_len_1 & ({C_BL_WIDTH{s_axi_aruser_1[5:3] == 3'b000}}));
                 chroma_buf_rd_cnt1[1]            <= chroma_buf_rd_cnt1[1] + (s_axi_axaddr_burst_len_1 & ({C_BL_WIDTH{s_axi_aruser_1[5:3] == 3'b001}}));
                 chroma_buf_rd_cnt1[2]            <= chroma_buf_rd_cnt1[2] + (s_axi_axaddr_burst_len_1 & ({C_BL_WIDTH{s_axi_aruser_1[5:3] == 3'b010}}));
                 chroma_buf_rd_cnt1[3]            <= chroma_buf_rd_cnt1[3] + (s_axi_axaddr_burst_len_1 & ({C_BL_WIDTH{s_axi_aruser_1[5:3] == 3'b011}}));

	      end
	      else if (s_axi_arvalid_1) begin
		luma_frmbuf_addr_done_1 <= 0;
		luma_frmbuf_addr_done_1_new <= 0;
		chroma_frmbuf_addr_done_1 <= 0;
		chroma_frmbuf_addr_done_1_new <= 0;
		int_luma_frmbuf_addr_done_1   <= 0;
		int_chroma_frmbuf_addr_done_1 <= 0;
		luma_outofrange_1 <= {C_VIDEO_CHAN{1'b0}};
		chroma_outofrange_1 <= {C_VIDEO_CHAN{1'b0}};

                luma_buf_rd_cnt1[0]   <= (luma_buf_rd_cnt1[0] & {C_RD_BUF_CNT_WIDTH{(~cons_luma_frmbuf_addr_done_in[0])}});
                luma_buf_rd_cnt1[1]   <= (luma_buf_rd_cnt1[1] & {C_RD_BUF_CNT_WIDTH{(~cons_luma_frmbuf_addr_done_in[1])}});
                luma_buf_rd_cnt1[2]   <= (luma_buf_rd_cnt1[2] & {C_RD_BUF_CNT_WIDTH{(~cons_luma_frmbuf_addr_done_in[2])}});
                luma_buf_rd_cnt1[3]   <= (luma_buf_rd_cnt1[3] & {C_RD_BUF_CNT_WIDTH{(~cons_luma_frmbuf_addr_done_in[3])}});
                chroma_buf_rd_cnt1[0] <= (chroma_buf_rd_cnt1[0] & {C_RD_BUF_CNT_WIDTH{(~cons_chroma_frmbuf_addr_done_in[0])}});
                chroma_buf_rd_cnt1[1] <= (chroma_buf_rd_cnt1[1] & {C_RD_BUF_CNT_WIDTH{(~cons_chroma_frmbuf_addr_done_in[1])}});
                chroma_buf_rd_cnt1[2] <= (chroma_buf_rd_cnt1[2] & {C_RD_BUF_CNT_WIDTH{(~cons_chroma_frmbuf_addr_done_in[2])}});
                chroma_buf_rd_cnt1[3] <= (chroma_buf_rd_cnt1[3] & {C_RD_BUF_CNT_WIDTH{(~cons_chroma_frmbuf_addr_done_in[3])}});

		 case (s_axi_aruser_1)
		   6'b100000:
		     begin
			//if ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1 ) < int_prod_luma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH])
		        if ((int_prod_luma_frmbuf_addr_done_keep_1_buf0[0] | int_prod_luma_frmbuf_addr_done_keep_1_buf1[0] | int_prod_luma_frmbuf_addr_done_keep_1_buf2[0])|
                            ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1 ) < luma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH]))
			  begin
			     fifo_read_en_1                 <=  1'b1;
			     end
		     end	       	
                   6'b100001: 
                     begin
                        //if ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1 ) < int_prod_luma_frmbuf_addr_outthres[C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH])
                        if ((int_prod_luma_frmbuf_addr_done_keep_1_buf0[1] | int_prod_luma_frmbuf_addr_done_keep_1_buf1[1] | int_prod_luma_frmbuf_addr_done_keep_1_buf2[1])|
                            ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1 ) < luma_frmbuf_addr_outthres[C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH]))
                          begin
                             fifo_read_en_1                 <=  1'b1;
                          end
                     end
		   6'b100010:
		     begin
			//if ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1) < int_prod_luma_frmbuf_addr_outthres[2*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH])
			if ((int_prod_luma_frmbuf_addr_done_keep_1_buf0[2] | int_prod_luma_frmbuf_addr_done_keep_1_buf1[2] | int_prod_luma_frmbuf_addr_done_keep_1_buf2[2])|
                            ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1) < luma_frmbuf_addr_outthres[2*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH]))
			  begin
			     fifo_read_en_1                 <=  1'b1;
			  end
		     end
		   6'b100011:
		     begin
			//if ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1) < int_prod_luma_frmbuf_addr_outthres[3*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH])
			if ((int_prod_luma_frmbuf_addr_done_keep_1_buf0[3] | int_prod_luma_frmbuf_addr_done_keep_1_buf1[3] | int_prod_luma_frmbuf_addr_done_keep_1_buf2[3])|
                            ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1) < luma_frmbuf_addr_outthres[3*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH]))
			  begin
			     fifo_read_en_1                 <=  1'b1;
			  end
		     end
		   
		   6'b000100:
		     begin
			//if ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1) < int_prod_chroma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH])
			if ((int_prod_chroma_frmbuf_addr_done_keep_1_buf0[0] | int_prod_chroma_frmbuf_addr_done_keep_1_buf1[0] | int_prod_chroma_frmbuf_addr_done_keep_1_buf2[0])|
                            ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1) < chroma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH]))
			  begin
			     fifo_read_en_1                   <=  1'b1;
			  end
		     end	       	
		   6'b001100: 
		     begin
			if ((int_prod_chroma_frmbuf_addr_done_keep_1_buf0[1] | int_prod_chroma_frmbuf_addr_done_keep_1_buf1[1] | int_prod_chroma_frmbuf_addr_done_keep_1_buf2[1])|
                            ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1) < prod_chroma_frmbuf_addr_outthres[C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH]))
                        begin
			     fifo_read_en_1                   <=  1'b1;
			  end
		     end
		   6'b010100:
		     begin
			//if ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1) < int_prod_chroma_frmbuf_addr_outthres[2*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH])
			if ((int_prod_chroma_frmbuf_addr_done_keep_1_buf0[2] | int_prod_chroma_frmbuf_addr_done_keep_1_buf1[2] | int_prod_chroma_frmbuf_addr_done_keep_1_buf2[2])|
                            ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1) < chroma_frmbuf_addr_outthres[2*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH]))
			  begin
			     fifo_read_en_1                   <=  1'b1;
			  end
		     end
		   6'b011100:
		     begin
			//if ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1) < int_prod_chroma_frmbuf_addr_outthres[3*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH])
			if ((int_prod_chroma_frmbuf_addr_done_keep_1_buf0[3] | int_prod_chroma_frmbuf_addr_done_keep_1_buf1[3] | int_prod_chroma_frmbuf_addr_done_keep_1_buf2[3])|
                            ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1) < chroma_frmbuf_addr_outthres[3*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH]))
			  begin
			     fifo_read_en_1                   <=  1'b1;
			  end
		     end
		   
		   6'b100100: begin
		      fifo_read_en_1                <= 1'b1; // let data go thru if they're not in any video channel region
		      luma_frmbuf_addr_done_1       <= 0;
		      chroma_frmbuf_addr_done_1     <= 0;
		      int_luma_frmbuf_addr_done_1   <= 0;
		      int_chroma_frmbuf_addr_done_1 <= 0; 
		      
		      if (C_DEC_ENC_N == 1) begin
			 
			 luma_outofrange_1 <= 1'b1;
			 chroma_outofrange_1 <= 1'b1;
			 
			 //synthesis translate_off
			 // In decoder-display case, this is illegal
			 $display ("[%m:%0t] ERROR: fifo_1 address requests received but not in any filled video channel region. Addr=%0x. Check if this is a legal case.",
				   $time, s_axi_araddr_1);
			 $stop;
			 //synthesis translate_on 
		      end 	      
		   end

                   6'b000000: begin
		    // if ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1) < int_prod_luma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH])
		     if ((int_prod_luma_frmbuf_addr_done_keep_1_buf0[0] | int_prod_luma_frmbuf_addr_done_keep_1_buf1[0] | int_prod_luma_frmbuf_addr_done_keep_1_buf2[0])|
                         ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1) < luma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH]))
                     begin
                       fifo_read_en_1                 <=  1'b1;
                     end
                     //else if ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1) < int_prod_chroma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH])
                     else if ((int_prod_chroma_frmbuf_addr_done_keep_1_buf0[0] | int_prod_chroma_frmbuf_addr_done_keep_1_buf1[0] | int_prod_chroma_frmbuf_addr_done_keep_1_buf2[0])|
                              ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1) < chroma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH]))
                     begin
                       fifo_read_en_1                   <=  1'b1;
                     end
                   end

                  6'b001001: begin
		    // if ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1) < int_prod_luma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH])
		     if ((int_prod_luma_frmbuf_addr_done_keep_1_buf0[1] | int_prod_luma_frmbuf_addr_done_keep_1_buf1[1] | int_prod_luma_frmbuf_addr_done_keep_1_buf2[1])|
                         ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1) < luma_frmbuf_addr_outthres[C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH]))
                     begin
                       fifo_read_en_1          <=  1'b1;
                     end
                     //else if ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1) < int_prod_chroma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH])
                     else if ((int_prod_chroma_frmbuf_addr_done_keep_1_buf0[1] | int_prod_chroma_frmbuf_addr_done_keep_1_buf1[1] | int_prod_chroma_frmbuf_addr_done_keep_1_buf2[1])|
                              ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1) < chroma_frmbuf_addr_outthres[C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH]))
                     begin
                       fifo_read_en_1          <=  1'b1;
                     end
                   end

                  6'b010010: begin
		    // if ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1) < int_prod_luma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH])
		     if ((int_prod_luma_frmbuf_addr_done_keep_1_buf0[2] | int_prod_luma_frmbuf_addr_done_keep_1_buf1[2] | int_prod_luma_frmbuf_addr_done_keep_1_buf2[2])|
                         ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1) < luma_frmbuf_addr_outthres[(2*C_FRMBUF_ADDR_WIDTH) +: C_FRMBUF_ADDR_WIDTH]))
                     begin
                       fifo_read_en_1          <=  1'b1;
                     end
                     //else if ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1) < int_prod_chroma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH])
                     else if ((int_prod_chroma_frmbuf_addr_done_keep_1_buf0[2] | int_prod_chroma_frmbuf_addr_done_keep_1_buf1[2] | int_prod_chroma_frmbuf_addr_done_keep_1_buf2[2])|
                              ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1) < chroma_frmbuf_addr_outthres[(2*C_FRMBUF_ADDR_WIDTH) +: C_FRMBUF_ADDR_WIDTH]))
                     begin
                       fifo_read_en_1          <=  1'b1;
                     end
                   end

                  6'b011011: begin
		    // if ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1) < int_prod_luma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH])
		     if ((int_prod_luma_frmbuf_addr_done_keep_1_buf0[3] | int_prod_luma_frmbuf_addr_done_keep_1_buf1[3] | int_prod_luma_frmbuf_addr_done_keep_1_buf2[3])|
                         ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1) < luma_frmbuf_addr_outthres[(3*C_FRMBUF_ADDR_WIDTH) +: C_FRMBUF_ADDR_WIDTH]))
                     begin
                       fifo_read_en_1          <=  1'b1;
                     end
                     //else if ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1) < int_prod_chroma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH])
                     else if ((int_prod_chroma_frmbuf_addr_done_keep_1_buf0[3] | int_prod_chroma_frmbuf_addr_done_keep_1_buf1[3] | int_prod_chroma_frmbuf_addr_done_keep_1_buf2[3])|
                              ((s_axi_araddr_1 + s_axi_axaddr_burst_len_1 -1) < chroma_frmbuf_addr_outthres[(3*C_FRMBUF_ADDR_WIDTH) +: C_FRMBUF_ADDR_WIDTH]))
                     begin
                       fifo_read_en_1          <=  1'b1;
                     end
                   end 

		   default: begin
		      fifo_read_en_1 <= 1'b1; // let data go thru if both luma and chroma data found, however, this is illegal case.
		     // luma_frmbuf_addr_done_1 <= {C_VIDEO_CHAN{1'b1}};
		     // luma_frmbuf_addr_done_1_new <= {C_VIDEO_CHAN{1'b1}};		      
		     // chroma_frmbuf_addr_done_1 <= {C_VIDEO_CHAN{1'b1}};
		     // chroma_frmbuf_addr_done_1_new <= {C_VIDEO_CHAN{1'b1}};
		     // int_luma_frmbuf_addr_done_1   <= {C_VIDEO_CHAN{1'b1}};
		     // int_chroma_frmbuf_addr_done_1 <= {C_VIDEO_CHAN{1'b1}};
		      luma_frmbuf_addr_done_1 <= {C_VIDEO_CHAN{1'b0}};
		      luma_frmbuf_addr_done_1_new <= {C_VIDEO_CHAN{1'b0}};		      
		      chroma_frmbuf_addr_done_1 <= {C_VIDEO_CHAN{1'b0}};
		      chroma_frmbuf_addr_done_1_new <= {C_VIDEO_CHAN{1'b0}};
		      int_luma_frmbuf_addr_done_1   <= {C_VIDEO_CHAN{1'b0}};
		      int_chroma_frmbuf_addr_done_1 <= {C_VIDEO_CHAN{1'b0}};

		      luma_outofrange_1 <= 1'b1;
		      chroma_outofrange_1 <= 1'b1;
		      
		      //synthesis translate_off
		      $display ("[%m:%0t] ERROR: fifo_1 both luma and chroma address requests received in video channel region. Addr=%0x. Tthis is illegal case.",
				$time, s_axi_araddr_1);
		      $stop;
		      //synthesis translate_on 	      
		   end
		 endcase // case (s_axi_aruser_1)
	      end // if (s_axi_arvalid_1)
	      else begin
		 fifo_read_en_1 <= 1'b0; // deassert to prevent passing the head data of next request
		 luma_frmbuf_addr_done_1 <= 0;
		 luma_frmbuf_addr_done_1_new <= 0;		 
		 chroma_frmbuf_addr_done_1 <= 0;
		 chroma_frmbuf_addr_done_1_new <= 0;		 
		 int_luma_frmbuf_addr_done_1   <= 0;
		 int_chroma_frmbuf_addr_done_1 <= 0;
		 luma_outofrange_1 <= {C_VIDEO_CHAN{1'b0}};
		 chroma_outofrange_1 <= {C_VIDEO_CHAN{1'b0}};
                 ot_luma_buf_id_1 <= 2'b00;
                 ot_chroma_buf_id_1 <= 2'b00;

                 luma_buf_rd_cnt1[0]   <= (luma_buf_rd_cnt1[0] & {C_RD_BUF_CNT_WIDTH{(~cons_luma_frmbuf_addr_done_in[0])}});
                 luma_buf_rd_cnt1[1]   <= (luma_buf_rd_cnt1[1] & {C_RD_BUF_CNT_WIDTH{(~cons_luma_frmbuf_addr_done_in[1])}});
                 luma_buf_rd_cnt1[2]   <= (luma_buf_rd_cnt1[2] & {C_RD_BUF_CNT_WIDTH{(~cons_luma_frmbuf_addr_done_in[2])}});
                 luma_buf_rd_cnt1[3]   <= (luma_buf_rd_cnt1[3] & {C_RD_BUF_CNT_WIDTH{(~cons_luma_frmbuf_addr_done_in[3])}});
                 chroma_buf_rd_cnt1[0] <= (chroma_buf_rd_cnt1[0] & {C_RD_BUF_CNT_WIDTH{(~cons_chroma_frmbuf_addr_done_in[0])}});
                 chroma_buf_rd_cnt1[1] <= (chroma_buf_rd_cnt1[1] & {C_RD_BUF_CNT_WIDTH{(~cons_chroma_frmbuf_addr_done_in[1])}});
                 chroma_buf_rd_cnt1[2] <= (chroma_buf_rd_cnt1[2] & {C_RD_BUF_CNT_WIDTH{(~cons_chroma_frmbuf_addr_done_in[2])}});
                 chroma_buf_rd_cnt1[3] <= (chroma_buf_rd_cnt1[3] & {C_RD_BUF_CNT_WIDTH{(~cons_chroma_frmbuf_addr_done_in[3])}});

	      end
	   end // always @ (posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	 

	 // Record previous channel status
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESET)
	 //always @(posedge S_AXI_ACLK or negedge f1_rst)
	 always @(posedge S_AXI_ACLK)
	   begin
	      //if (~S_AXI_ARESETN) begin
	      //if (~S_AXI_ARESET) begin
	      if (~f1_rst) begin
		 S_AXI_ARREADY_1_r <= 1'b0;
		 S_AXI_AR_LUMA_CHANID_1_r <= 3'b100;
		 S_AXI_AR_CHROMA_CHANID_1_r <= 3'b100;
		 
	      end
	      else if (C_DEC_ENC_N == 0) begin
		 S_AXI_ARREADY_1_r <= S_AXI_ARREADY_1 & ~idle_insert_1;
		 if (S_AXI_ARVALID & (S_AXI_ARID[3] == 0)) begin
		    S_AXI_AR_LUMA_CHANID_1_r <= S_AXI_AR_LUMA_CHANID;
		    S_AXI_AR_CHROMA_CHANID_1_r <= S_AXI_AR_CHROMA_CHANID;	      
		 end
		 else begin
		    S_AXI_AR_LUMA_CHANID_1_r <= 3'b100;
		    S_AXI_AR_CHROMA_CHANID_1_r <= 3'b100;	      
		 end
	      end
	   end
	 
	 // Idle insertion when switching videl channel in back-to-back requests
	 // Since gating logic requires 1 cycle of latency, if channel switches in the middle of continuous request,
	 // the "head" of new channel request can be passed thru accidentally. To prevent this,
	 // insert an idle cycle when such condition is detected.
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESET)
	 //always @(posedge S_AXI_ACLK or negedge f1_rst)
	 always @(posedge S_AXI_ACLK)
	   begin
	      //if (~S_AXI_ARESETN)
	      //if (~S_AXI_ARESET)
	      if (~f1_rst)
		idle_insert_1 <= 1'b0;
	      else if ( (C_DEC_ENC_N == 0) 
			& S_AXI_ARVALID_r & S_AXI_ARREADY_1_r 
			& S_AXI_ARVALID & (S_AXI_ARID[3] == 0) 
			& (
			   (S_AXI_AR_LUMA_CHANID != S_AXI_AR_LUMA_CHANID_1_r) & ~S_AXI_AR_LUMA_CHANID[2] & ~S_AXI_AR_LUMA_CHANID_1_r[2]
			   | (S_AXI_AR_CHROMA_CHANID != S_AXI_AR_CHROMA_CHANID_1_r) & ~S_AXI_AR_CHROMA_CHANID[2] & ~S_AXI_AR_CHROMA_CHANID_1_r[2])
			)
		idle_insert_1 <= 1'b1;
	      else
		idle_insert_1 <= 1'b0;
	   end

      end // block: gen_fifo_1
      else begin: gen_no_fifo_1

	 assign S_AXI_ARREADY_1 = 0;
	 assign s_axi_arid_1 = 0; 
	 assign s_axi_araddr_1 = 0; 
	 assign s_axi_arlen_1 = 0; 
	 assign s_axi_arsize_1 = 0; 
	 assign s_axi_arburst_1 = 0; 
	 assign s_axi_arlock_1 = 0; 
	 assign s_axi_arcache_1 = 0; 
	 assign s_axi_arprot_1 = 0; 
	 assign s_axi_arqos_1 = 0; 
	 assign s_axi_arvalid_1 = 0; 

	 always @(posedge S_AXI_ACLK) begin
	    luma_outofrange_1 <= {C_VIDEO_CHAN{1'b0}};
	    chroma_outofrange_1 <= {C_VIDEO_CHAN{1'b0}};
	    luma_frmbuf_addr_done_1 <= 0;
	    luma_frmbuf_addr_done_1_new <= 0;	    
	    chroma_frmbuf_addr_done_1 <= 0;		 
	    chroma_frmbuf_addr_done_1_new <= 0;
	    int_luma_frmbuf_addr_done_1   <= 0;
	    int_chroma_frmbuf_addr_done_1 <= 0;
	 end

      end
   endgenerate
   
   generate
      if (C_CONSUMER_CHAN > 1 && C_DEC_ENC_N == 0 ) begin: gen_fifo_2
	 
	 // FIFO2
	 axi_mm_rfifo_128x100b
	   axi_mm_rfifo_128x100b_1
	     (.s_aclk     (S_AXI_ACLK), 
	      //.s_aresetn  (S_AXI_ARESETN), 
	      //.s_aresetn  (S_AXI_ARESET), 
	      .s_aresetn  (f2_rst), 
	      .s_axi_arid     (S_AXI_ARID[3:0]), 
	      .s_axi_araddr   (S_AXI_ARADDR[63:0]), 
	      .s_axi_arlen    (S_AXI_ARLEN[7:0]), 
	      .s_axi_arsize   (S_AXI_ARSIZE[2:0]), 
	      .s_axi_arburst  (S_AXI_ARBURST[1:0]), 
	      .s_axi_arlock   (S_AXI_ARLOCK), 
	      .s_axi_arcache  (S_AXI_ARCACHE[3:0]), 
	      .s_axi_arprot   (S_AXI_ARPROT[2:0]), 
	      .s_axi_arregion (S_AXI_ARREGION[3:0]), 
	      .s_axi_arqos    (S_AXI_ARQOS[3:0]), 
	      .s_axi_aruser   ({axi_axaddr_burst_len,S_AXI_AR_CHROMA_CHANID[2:0],S_AXI_AR_LUMA_CHANID[2:0]}),
	      .s_axi_arvalid  (S_AXI_ARVALID & 
			       (C_DEC_ENC_N == 0) &  
			       (S_AXI_ARID[2:0] == C_SRC_FRAME_DETECT) & 
			       (S_AXI_ARID[3] == 1) 
 			       ), 
	      .s_axi_arready  (S_AXI_ARREADY_2), 
	      
	      .s_axi_rid      (), 
	      .s_axi_rdata    (), 
	      .s_axi_rresp    (), 
	      .s_axi_rlast    (), 
	      .s_axi_rvalid   (), 
	      .s_axi_rready   (1'b0),
	      
//              .m_axi_arid     (f2_s_axi_arid_2), 
//              .m_axi_araddr   (f2_s_axi_araddr_2), 
//              .m_axi_arlen    (f2_s_axi_arlen_2), 
//              .m_axi_arsize   (f2_s_axi_arsize_2), 
//              .m_axi_arburst  (f2_s_axi_arburst_2), 
//              .m_axi_arlock   (f2_s_axi_arlock_2), 
//              .m_axi_arcache  (f2_s_axi_arcache_2), 
//              .m_axi_arprot   (f2_s_axi_arprot_2), 
//              .m_axi_arregion (f2_s_axi_arregion_2), 
//              .m_axi_arqos    (f2_s_axi_arqos_2),
//              .m_axi_aruser   (f2_s_axi_aruser_2), //{s_axi_axaddr_burst_len_2,s_axi_aruser_2}),
//              .m_axi_arvalid  (f2_s_axi_arvalid_2),  // O
//              //.m_axi_arready  (f2_s_axi_arready_2 & fifo_read_en_2), // I
//              .m_axi_arready  (f2_s_axi_arready_2), // I

              .m_axi_arid     (s_axi_arid_2), 
              .m_axi_araddr   (s_axi_araddr_2), 
              .m_axi_arlen    (s_axi_arlen_2), 
              .m_axi_arsize   (s_axi_arsize_2), 
              .m_axi_arburst  (s_axi_arburst_2), 
              .m_axi_arlock   (s_axi_arlock_2), 
              .m_axi_arcache  (s_axi_arcache_2), 
              .m_axi_arprot   (s_axi_arprot_2), 
              .m_axi_arregion (s_axi_arregion_2), 
              .m_axi_arqos    (s_axi_arqos_2),
              //.m_axi_aruser   (s_axi_aruser_2), //{s_axi_axaddr_burst_len_2,s_axi_aruser_2}),
              .m_axi_aruser   ({s_axi_axaddr_burst_len_2,s_axi_aruser_2}),
              .m_axi_arvalid  (s_axi_arvalid_2),  // O
              .m_axi_arready  (s_axi_arready_2 & fifo_read_en_2), // I
              //.m_axi_arready  (s_axi_arready_2), // I

	      .m_axi_rid      (4'd0  ), 
	      .m_axi_rdata    (128'd0), 
	      .m_axi_rresp    (2'd0  ), 
	      .m_axi_rlast    (1'b0  ), 
	      .m_axi_rvalid   (1'b0  ), 
	      .m_axi_rready   (      )
	       );


//   axi_ar_reg_slice fifo2_axi_ar_reg_slice 
//     (.aclk           (S_AXI_ACLK), 
//      .aresetn        (f2_rst), 
//      .s_axi_arid     (f2_s_axi_arid_2), //I
//      .s_axi_araddr   (f2_s_axi_araddr_2), 
//      .s_axi_arlen    (f2_s_axi_arlen_2), 
//      .s_axi_arsize   (f2_s_axi_arsize_2), 
//      .s_axi_arburst  (f2_s_axi_arburst_2), 
//      .s_axi_arlock   (f2_s_axi_arlock_2), 
//      .s_axi_arcache  (f2_a_axi_arcache_2), 
//      .s_axi_arprot   (f2_s_axi_arprot_2), 
//      .s_axi_arregion (f2_s_axi_arregion_2), 
//      .s_axi_arqos    (f2_s_axi_arqos_2), 
//      .s_axi_aruser   (f2_s_axi_aruser_2),  // use ARUSER to pass ARCHANID decoded value
//      .s_axi_arvalid  (f2_s_axi_arvalid_2),  // I 
//      .s_axi_arready  (f2_s_axi_arready_2),  // O
//      
//      .s_axi_rid      ( ),  // O
//      .s_axi_rdata    ( ), 
//      .s_axi_rresp    ( ), 
//      .s_axi_rlast    ( ), 
//      .s_axi_rvalid   ( ),   // O
//      .s_axi_rready   ( ),   // I
//      
//      .m_axi_arid     (s_axi_arid_2),   // O
//      .m_axi_araddr   (s_axi_araddr_2), 
//      .m_axi_arlen    (s_axi_arlen_2), 
//      .m_axi_arsize   (s_axi_arsize_2), 
//      .m_axi_arburst  (s_axi_arburst_2), 
//      .m_axi_arlock   (s_axi_arlock_2), 
//      .m_axi_arcache  (s_axi_arcache_2), 
//      .m_axi_arprot   (s_axi_arprot_2), 
//      .m_axi_arregion (s_axi_arregion_2), 
//      .m_axi_arqos    (s_axi_arqos_2), 
//      .m_axi_aruser   ({s_axi_axaddr_burst_len_2,s_axi_aruser_2}),
//      .m_axi_arvalid  (s_axi_arvalid_2), // O
//      //.m_axi_arready  (s_axi_arready_2 & fifo_read_en_2_rg), // I
//      .m_axi_arready  (s_axi_arready_2 & fifo_read_en_2), // I
//      
//      .m_axi_rid      (0),     // I
//      .m_axi_rdata    (0), 
//      .m_axi_rresp    (0), 
//      .m_axi_rlast    (0), 
//      .m_axi_rvalid   (0),  // I 
//      .m_axi_rready   (0)   // O
//      );


	 //always @(posedge S_AXI_ACLK or negedge f1_rst)
	 always @(posedge S_AXI_ACLK)
         begin
	   if (~f2_rst) 
           begin
             fifo_read_en_2_rg <= 1'b0;
           end
           else
           begin
             fifo_read_en_2_rg <= fifo_read_en_2;
           end
         end


	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESET)
	 //always @(posedge S_AXI_ACLK or negedge f2_rst)
	 always @(posedge S_AXI_ACLK)
	   begin
	      //if (~S_AXI_ARESETN) begin
	      //if (~S_AXI_ARESET) begin
	      if (~f2_rst) begin
		 fifo_read_en_2 <= 1'b0;
		 luma_frmbuf_addr_done_2 <= 0;
		 luma_frmbuf_addr_done_2_new <= 0;		 
		 chroma_frmbuf_addr_done_2 <= 0;		 
		 chroma_frmbuf_addr_done_2_new <= 0;		 
		 int_luma_frmbuf_addr_done_2 <= 0;
		 int_chroma_frmbuf_addr_done_2 <= 0;
		 luma_outofrange_2 <= {C_VIDEO_CHAN{1'b0}};
		 chroma_outofrange_2 <= {C_VIDEO_CHAN{1'b0}};
                 ot_luma_buf_id_2 <= 2'b00;
                 ot_chroma_buf_id_2 <= 2'b00;
                 luma_buf_rd_cnt2[0]           <= {C_RD_BUF_CNT_WIDTH{1'b0}};
                 luma_buf_rd_cnt2[1]           <= {C_RD_BUF_CNT_WIDTH{1'b0}};
                 luma_buf_rd_cnt2[2]           <= {C_RD_BUF_CNT_WIDTH{1'b0}};
                 luma_buf_rd_cnt2[3]           <= {C_RD_BUF_CNT_WIDTH{1'b0}};
                 chroma_buf_rd_cnt2[0]         <= {C_RD_BUF_CNT_WIDTH{1'b0}};
                 chroma_buf_rd_cnt2[1]         <= {C_RD_BUF_CNT_WIDTH{1'b0}};
                 chroma_buf_rd_cnt2[2]         <= {C_RD_BUF_CNT_WIDTH{1'b0}};
                 chroma_buf_rd_cnt2[3]         <= {C_RD_BUF_CNT_WIDTH{1'b0}};
	      end
	      else if (s_axi_arvalid_2 & s_axi_arready_2) begin
		 fifo_read_en_2 <= 1'b0; 
		 luma_outofrange_2 <= {C_VIDEO_CHAN{1'b0}};
		 chroma_outofrange_2 <= {C_VIDEO_CHAN{1'b0}};
	  	 int_luma_frmbuf_addr_done_2[0] <= (((s_axi_araddr_2 + s_axi_axaddr_burst_len_2) == (calc_luma_frmbuf_end_addr_2[0] + 1'b1)) &
		                                    ((((luma_buf_rd_cnt[0] + s_axi_axaddr_burst_len_2) >= calc_luma_total_buf_rd_cnt2[0]) & (buf_rd_cnt_en[0])) | (~buf_rd_cnt_en[0]))); //####
		 int_luma_frmbuf_addr_done_2[1] <= (((s_axi_araddr_2 + s_axi_axaddr_burst_len_2) == (calc_luma_frmbuf_end_addr_2[1] + 1'b1)) &
		                                    ((((luma_buf_rd_cnt[1] + s_axi_axaddr_burst_len_2) >= calc_luma_total_buf_rd_cnt2[1]) & (buf_rd_cnt_en[1])) | (~buf_rd_cnt_en[1]))); //####
		 int_luma_frmbuf_addr_done_2[2] <= (((s_axi_araddr_2 + s_axi_axaddr_burst_len_2) == (calc_luma_frmbuf_end_addr_2[2] + 1'b1)) &
		                                    ((((luma_buf_rd_cnt[2] + s_axi_axaddr_burst_len_2) >= calc_luma_total_buf_rd_cnt2[2]) & (buf_rd_cnt_en[2])) | (~buf_rd_cnt_en[2]))); //####
		 int_luma_frmbuf_addr_done_2[3] <= (((s_axi_araddr_2 + s_axi_axaddr_burst_len_2) == (calc_luma_frmbuf_end_addr_2[3] + 1'b1)) &
		                                    ((((luma_buf_rd_cnt[3] + s_axi_axaddr_burst_len_2) >= calc_luma_total_buf_rd_cnt2[3]) & (buf_rd_cnt_en[3])) | (~buf_rd_cnt_en[3]))); //####

                 luma_frmbuf_addr_done_2[0]     <= ((((s_axi_araddr_2 + s_axi_axaddr_burst_len_2) == (int_luma_frmbuf_end_addr[0] + 1'b1)) & int_luma_frmbuf_addr_valid[0]) &
                                                    ((((luma_buf_rd_cnt[0] + s_axi_axaddr_burst_len_2) >= luma_total_buf_rd_cnt[0]) & (buf_rd_cnt_en[0])) | (~buf_rd_cnt_en[0]))); //####
                 luma_frmbuf_addr_done_2[1]     <= ((((s_axi_araddr_2 + s_axi_axaddr_burst_len_2) == (int_luma_frmbuf_end_addr[1] + 1'b1)) & int_luma_frmbuf_addr_valid[1]) &
                                                    ((((luma_buf_rd_cnt[1] + s_axi_axaddr_burst_len_2) >= luma_total_buf_rd_cnt[1]) & (buf_rd_cnt_en[1])) | (~buf_rd_cnt_en[1]))); //####
                 luma_frmbuf_addr_done_2[2]     <= ((((s_axi_araddr_2 + s_axi_axaddr_burst_len_2) == (int_luma_frmbuf_end_addr[2] + 1'b1)) & int_luma_frmbuf_addr_valid[2]) &
                                                    ((((luma_buf_rd_cnt[2] + s_axi_axaddr_burst_len_2) >= luma_total_buf_rd_cnt[2]) & (buf_rd_cnt_en[2])) | (~buf_rd_cnt_en[2]))); //####
                 luma_frmbuf_addr_done_2[3]     <= ((((s_axi_araddr_2 + s_axi_axaddr_burst_len_2) == (int_luma_frmbuf_end_addr[3] + 1'b1)) & int_luma_frmbuf_addr_valid[3]) &
                                                    ((((luma_buf_rd_cnt[3] + s_axi_axaddr_burst_len_2) >= luma_total_buf_rd_cnt[3]) & (buf_rd_cnt_en[3])) | (~buf_rd_cnt_en[3]))); //####

                 int_chroma_frmbuf_addr_done_2[0] <= (((s_axi_araddr_2 + s_axi_axaddr_burst_len_2) == (calc_chroma_frmbuf_end_addr_2[0] + 1'b1)) &
                                                      ((((chroma_buf_rd_cnt[0] + s_axi_axaddr_burst_len_2) >= calc_chroma_total_buf_rd_cnt2[0]) & (buf_rd_cnt_en[0])) | (~buf_rd_cnt_en[0]))); //####
                 int_chroma_frmbuf_addr_done_2[1] <= (((s_axi_araddr_2 + s_axi_axaddr_burst_len_2) == (calc_chroma_frmbuf_end_addr_2[1] + 1'b1)) &
                                                      ((((chroma_buf_rd_cnt[1] + s_axi_axaddr_burst_len_2) >= calc_chroma_total_buf_rd_cnt2[1]) & (buf_rd_cnt_en[1])) | (~buf_rd_cnt_en[1]))); //####
                 int_chroma_frmbuf_addr_done_2[2] <= (((s_axi_araddr_2 + s_axi_axaddr_burst_len_2) == (calc_chroma_frmbuf_end_addr_2[2] + 1'b1)) &
                                                      ((((chroma_buf_rd_cnt[2] + s_axi_axaddr_burst_len_2) >= calc_chroma_total_buf_rd_cnt2[2]) & (buf_rd_cnt_en[2])) | (~buf_rd_cnt_en[2]))); //####
                 int_chroma_frmbuf_addr_done_2[3] <= (((s_axi_araddr_2 + s_axi_axaddr_burst_len_2) == (calc_chroma_frmbuf_end_addr_2[3] + 1'b1)) &
                                                      ((((chroma_buf_rd_cnt[3] + s_axi_axaddr_burst_len_2) >= calc_chroma_total_buf_rd_cnt2[3]) & (buf_rd_cnt_en[3])) | (~buf_rd_cnt_en[3]))); //####


                 chroma_frmbuf_addr_done_2[0]     <= ((((s_axi_araddr_2 + s_axi_axaddr_burst_len_2) == (int_chroma_frmbuf_end_addr[0] + 1'b1)) & int_chroma_frmbuf_addr_valid[0]) &
                                                      ((((chroma_buf_rd_cnt[0] + s_axi_axaddr_burst_len_2) >= chroma_total_buf_rd_cnt[0]) & (buf_rd_cnt_en[0])) | (~buf_rd_cnt_en[0]))); //####
                 chroma_frmbuf_addr_done_2[1]     <= ((((s_axi_araddr_2 + s_axi_axaddr_burst_len_2) == (int_chroma_frmbuf_end_addr[1] + 1'b1)) & int_chroma_frmbuf_addr_valid[1]) &
                                                      ((((chroma_buf_rd_cnt[1] + s_axi_axaddr_burst_len_2) >= chroma_total_buf_rd_cnt[1]) & (buf_rd_cnt_en[1])) | (~buf_rd_cnt_en[1]))); //####
                 chroma_frmbuf_addr_done_2[2]     <= ((((s_axi_araddr_2 + s_axi_axaddr_burst_len_2) == (int_chroma_frmbuf_end_addr[2] + 1'b1)) & int_chroma_frmbuf_addr_valid[2]) &
                                                      ((((chroma_buf_rd_cnt[2] + s_axi_axaddr_burst_len_2) >= chroma_total_buf_rd_cnt[2]) & (buf_rd_cnt_en[2])) | (~buf_rd_cnt_en[2]))); //####
                 chroma_frmbuf_addr_done_2[3]     <= ((((s_axi_araddr_2 + s_axi_axaddr_burst_len_2) == (int_chroma_frmbuf_end_addr[3] + 1'b1)) & int_chroma_frmbuf_addr_valid[3]) &
                                                      ((((chroma_buf_rd_cnt[3] + s_axi_axaddr_burst_len_2) >= chroma_total_buf_rd_cnt[3]) & (buf_rd_cnt_en[3])) | (~buf_rd_cnt_en[3]))); //####

                 luma_buf_rd_cnt2[0]              <= luma_buf_rd_cnt2[0] + (s_axi_axaddr_burst_len_2 & ({C_BL_WIDTH{s_axi_aruser_2[2:0] == 3'b000}}));
                 luma_buf_rd_cnt2[1]              <= luma_buf_rd_cnt2[1] + (s_axi_axaddr_burst_len_2 & ({C_BL_WIDTH{s_axi_aruser_2[2:0] == 3'b001}}));
                 luma_buf_rd_cnt2[2]              <= luma_buf_rd_cnt2[2] + (s_axi_axaddr_burst_len_2 & ({C_BL_WIDTH{s_axi_aruser_2[2:0] == 3'b010}}));
                 luma_buf_rd_cnt2[3]              <= luma_buf_rd_cnt2[3] + (s_axi_axaddr_burst_len_2 & ({C_BL_WIDTH{s_axi_aruser_2[2:0] == 3'b011}}));

                 chroma_buf_rd_cnt2[0]            <= chroma_buf_rd_cnt2[0] + (s_axi_axaddr_burst_len_2 & ({C_BL_WIDTH{s_axi_aruser_2[5:3] == 3'b000}}));
                 chroma_buf_rd_cnt2[1]            <= chroma_buf_rd_cnt2[1] + (s_axi_axaddr_burst_len_2 & ({C_BL_WIDTH{s_axi_aruser_2[5:3] == 3'b001}}));
                 chroma_buf_rd_cnt2[2]            <= chroma_buf_rd_cnt2[2] + (s_axi_axaddr_burst_len_2 & ({C_BL_WIDTH{s_axi_aruser_2[5:3] == 3'b010}}));
                 chroma_buf_rd_cnt2[3]            <= chroma_buf_rd_cnt2[3] + (s_axi_axaddr_burst_len_2 & ({C_BL_WIDTH{s_axi_aruser_2[5:3] == 3'b011}}));

	      end
	      else if (s_axi_arvalid_2 ) begin
                luma_frmbuf_addr_done_2 <= 0;
                luma_frmbuf_addr_done_2_new <= 0;		 
                chroma_frmbuf_addr_done_2 <= 0;
                chroma_frmbuf_addr_done_2_new <= 0;
                int_luma_frmbuf_addr_done_2 <= 0;
                int_chroma_frmbuf_addr_done_2 <= 0;
                luma_outofrange_2 <= {C_VIDEO_CHAN{1'b0}};
                chroma_outofrange_2 <= {C_VIDEO_CHAN{1'b0}};

                luma_buf_rd_cnt2[0] <= (luma_buf_rd_cnt2[0] & {C_RD_BUF_CNT_WIDTH{~cons_luma_frmbuf_addr_done_in[0]}});
                luma_buf_rd_cnt2[1] <= (luma_buf_rd_cnt2[1] & {C_RD_BUF_CNT_WIDTH{~cons_luma_frmbuf_addr_done_in[1]}});
                luma_buf_rd_cnt2[2] <= (luma_buf_rd_cnt2[2] & {C_RD_BUF_CNT_WIDTH{~cons_luma_frmbuf_addr_done_in[2]}});
                luma_buf_rd_cnt2[3] <= (luma_buf_rd_cnt2[3] & {C_RD_BUF_CNT_WIDTH{~cons_luma_frmbuf_addr_done_in[3]}});
                chroma_buf_rd_cnt2[0] <= (chroma_buf_rd_cnt2[0] & {C_RD_BUF_CNT_WIDTH{(~cons_chroma_frmbuf_addr_done_in[0])}});
                chroma_buf_rd_cnt2[1] <= (chroma_buf_rd_cnt2[1] & {C_RD_BUF_CNT_WIDTH{(~cons_chroma_frmbuf_addr_done_in[1])}});
                chroma_buf_rd_cnt2[2] <= (chroma_buf_rd_cnt2[2] & {C_RD_BUF_CNT_WIDTH{(~cons_chroma_frmbuf_addr_done_in[2])}});
                chroma_buf_rd_cnt2[3] <= (chroma_buf_rd_cnt2[3] & {C_RD_BUF_CNT_WIDTH{(~cons_chroma_frmbuf_addr_done_in[3])}});


		 case (s_axi_aruser_2)
		   6'b100000:
		     begin
			//if ((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 -1) < int_prod_luma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH])
			if ((int_prod_luma_frmbuf_addr_done_keep_2_buf0[0] | int_prod_luma_frmbuf_addr_done_keep_2_buf1[0] | int_prod_luma_frmbuf_addr_done_keep_2_buf2[0])|
                            ((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 -1) < luma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH]))
			  begin
			     fifo_read_en_2                 <=  1'b1;
			  end
		     end	       	
		   6'b100001: 
		     begin
			//if ((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 -1) < int_prod_luma_frmbuf_addr_outthres[C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH])
			if ((int_prod_luma_frmbuf_addr_done_keep_2_buf0[1] | int_prod_luma_frmbuf_addr_done_keep_2_buf1[1] | int_prod_luma_frmbuf_addr_done_keep_2_buf2[1])|
                            ((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 -1) < luma_frmbuf_addr_outthres[C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH]))
			  begin
			     fifo_read_en_2                 <=  1'b1;
			  end
		     end
		   6'b100010:
		     begin
			//if ((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 -1) < int_prod_luma_frmbuf_addr_outthres[2*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH])
			if ((int_prod_luma_frmbuf_addr_done_keep_2_buf0[2] | int_prod_luma_frmbuf_addr_done_keep_2_buf1[2] | int_prod_luma_frmbuf_addr_done_keep_2_buf2[2])|
                            ((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 -1) < luma_frmbuf_addr_outthres[2*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH]))
			  begin
			     fifo_read_en_2                 <=  1'b1;
			  end
		     end
		   6'b100011:
		     begin
			//if ((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 -1) < int_prod_luma_frmbuf_addr_outthres[3*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH])
			if ((int_prod_luma_frmbuf_addr_done_keep_2_buf0[3] | int_prod_luma_frmbuf_addr_done_keep_2_buf1[3] | int_prod_luma_frmbuf_addr_done_keep_2_buf2[3])|
                            ((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 -1) < luma_frmbuf_addr_outthres[3*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH]))
			  begin
			     fifo_read_en_2                 <=  1'b1;
			  end
		     end

		   6'b000100:
		     begin
			//if ((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 -1) < int_prod_chroma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH])
			if ((int_prod_chroma_frmbuf_addr_done_keep_2_buf0[0] | int_prod_chroma_frmbuf_addr_done_keep_2_buf1[0] | int_prod_chroma_frmbuf_addr_done_keep_2_buf2[0])|
                            ((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 -1) < chroma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH]))
			  begin
			     fifo_read_en_2                   <=  1'b1;
			  end
		     end	       	
		   6'b001100: 
		     begin
			//if ((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 -1) < int_prod_chroma_frmbuf_addr_outthres[C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH])
			if ((int_prod_chroma_frmbuf_addr_done_keep_2_buf0[1] | int_prod_chroma_frmbuf_addr_done_keep_2_buf1[1] | int_prod_chroma_frmbuf_addr_done_keep_2_buf2[1])|
                            ((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 -1) < chroma_frmbuf_addr_outthres[C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH]))
			  begin
			     fifo_read_en_2                   <= 1'b1;
			  end
		     end
		   6'b010100:
		     begin
			//if ((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 -1) < int_prod_chroma_frmbuf_addr_outthres[2*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH])
			if ((int_prod_chroma_frmbuf_addr_done_keep_2_buf0[2] | int_prod_chroma_frmbuf_addr_done_keep_2_buf1[2] | int_prod_chroma_frmbuf_addr_done_keep_2_buf2[2])|
                            ((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 -1) < chroma_frmbuf_addr_outthres[2*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH]))
			  begin
			     fifo_read_en_2                   <=  1'b1;
			  end
		     end
		   6'b011100:
		     begin
			//if ((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 -1) < int_prod_chroma_frmbuf_addr_outthres[3*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH])
			if ((int_prod_chroma_frmbuf_addr_done_keep_2_buf0[3] | int_prod_chroma_frmbuf_addr_done_keep_2_buf1[3] | int_prod_chroma_frmbuf_addr_done_keep_2_buf2[3])|
                            ((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 -1) < chroma_frmbuf_addr_outthres[3*C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH]))
			  begin
			     fifo_read_en_2                   <=  1'b1;
			  end
		     end


		   6'b100100: begin
		      fifo_read_en_2 <= 1'b1; // let data go thru if they're not in any video channel region
		      luma_frmbuf_addr_done_2 <= 0;

		      chroma_frmbuf_addr_done_2 <= 0;
		      int_luma_frmbuf_addr_done_2 <= 0;
		      int_chroma_frmbuf_addr_done_2 <= 0;

		      if (C_DEC_ENC_N == 1) begin			 
			 luma_outofrange_2 <= 1'b1;
			 chroma_outofrange_2 <= 1'b1;
			 
			 //synthesis translate_off
			 //In decoder-display case, this is illegal
			 
			 $display ("[%m:%0t] ERROR: fifo_2 address requests received but not in any video channel region. Addr=%0x. Check if this is a legal case.",
				   $time, s_axi_araddr_2);
			 $stop;
			 //synthesis translate_on 	      
		      end

		   end
                   6'b000000: begin
                     //if (((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 - 1) < int_prod_luma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH]) )
                     if ((int_prod_luma_frmbuf_addr_done_keep_2_buf0[0] | int_prod_luma_frmbuf_addr_done_keep_2_buf1[0] | int_prod_luma_frmbuf_addr_done_keep_2_buf2[0])|
                         ((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 - 1) < luma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH]) )

                       begin
                         fifo_read_en_2                 <=  1'b1;
                       end
                       //else if ((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 -1) < int_prod_chroma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH])
                       else if ((int_prod_chroma_frmbuf_addr_done_keep_2_buf0[0] | int_prod_chroma_frmbuf_addr_done_keep_2_buf1[0] | int_prod_chroma_frmbuf_addr_done_keep_2_buf2[0])|
                                ((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 -1) < chroma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH]))
                       begin
                         fifo_read_en_2                   <=  1'b1;
                       end
                   end
                   6'b001001: begin
                     //if (((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 - 1) < int_prod_luma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH]) )
                     if ((int_prod_luma_frmbuf_addr_done_keep_2_buf0[1] | int_prod_luma_frmbuf_addr_done_keep_2_buf1[1] | int_prod_luma_frmbuf_addr_done_keep_2_buf2[1])|
                         ((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 - 1) < luma_frmbuf_addr_outthres[C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH]) )

                       begin
                         fifo_read_en_2                 <=  1'b1;
                       end
                       //else if ((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 -1) < int_prod_chroma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH])
                       else if ((int_prod_chroma_frmbuf_addr_done_keep_2_buf0[1] | int_prod_chroma_frmbuf_addr_done_keep_2_buf1[1] | int_prod_chroma_frmbuf_addr_done_keep_2_buf2[1])|
                                ((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 -1) < chroma_frmbuf_addr_outthres[C_FRMBUF_ADDR_WIDTH +: C_FRMBUF_ADDR_WIDTH]))
                       begin
                         fifo_read_en_2                   <=  1'b1;
                       end
                   end
                   6'b010010: begin
                     //if (((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 - 1) < int_prod_luma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH]) )
                     if ((int_prod_luma_frmbuf_addr_done_keep_2_buf0[2] | int_prod_luma_frmbuf_addr_done_keep_2_buf1[2] | int_prod_luma_frmbuf_addr_done_keep_2_buf2[2])|
                         ((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 - 1) < luma_frmbuf_addr_outthres[(2*C_FRMBUF_ADDR_WIDTH) +: C_FRMBUF_ADDR_WIDTH]) )

                       begin
                         fifo_read_en_2                 <=  1'b1;
                       end
                       //else if ((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 -1) < int_prod_chroma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH])
                       else if ((int_prod_chroma_frmbuf_addr_done_keep_2_buf0[2] | int_prod_chroma_frmbuf_addr_done_keep_2_buf1[2] | int_prod_chroma_frmbuf_addr_done_keep_2_buf2[2])|
                                ((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 -1) < chroma_frmbuf_addr_outthres[(2*C_FRMBUF_ADDR_WIDTH) +: C_FRMBUF_ADDR_WIDTH]))
                       begin
                         fifo_read_en_2                   <=  1'b1;
                       end
                   end
                   6'b011011: begin
                     //if (((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 - 1) < int_prod_luma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH]) )
                     if ((int_prod_luma_frmbuf_addr_done_keep_2_buf0[3] | int_prod_luma_frmbuf_addr_done_keep_2_buf1[3] | int_prod_luma_frmbuf_addr_done_keep_2_buf2[3])|
                         ((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 - 1) < luma_frmbuf_addr_outthres[(3*C_FRMBUF_ADDR_WIDTH) +: C_FRMBUF_ADDR_WIDTH]) )

                       begin
                         fifo_read_en_2                 <=  1'b1;
                       end
                       //else if ((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 -1) < int_prod_chroma_frmbuf_addr_outthres[0 +: C_FRMBUF_ADDR_WIDTH])
                       else if ((int_prod_chroma_frmbuf_addr_done_keep_2_buf0[3] | int_prod_chroma_frmbuf_addr_done_keep_2_buf1[3] | int_prod_chroma_frmbuf_addr_done_keep_2_buf2[3])|
                                ((s_axi_araddr_2 + s_axi_axaddr_burst_len_2 -1) < chroma_frmbuf_addr_outthres[(3*C_FRMBUF_ADDR_WIDTH) +: C_FRMBUF_ADDR_WIDTH]))
                       begin
                         fifo_read_en_2                   <=  1'b1;
                       end
                   end

		   default: begin
		      fifo_read_en_2 <= 1'b1; // let data go thru if both luma and chroma found, but this is illegal case
		      //luma_frmbuf_addr_done_2 <= {C_VIDEO_CHAN{1'b1}};
		      //luma_frmbuf_addr_done_2_new <= {C_VIDEO_CHAN{1'b1}};		      
		      //chroma_frmbuf_addr_done_2 <= {C_VIDEO_CHAN{1'b1}};
		      //chroma_frmbuf_addr_done_2_new <= {C_VIDEO_CHAN{1'b1}};
		      //int_luma_frmbuf_addr_done_2 <= {C_VIDEO_CHAN{1'b1}};
		      //int_chroma_frmbuf_addr_done_2 <= {C_VIDEO_CHAN{1'b1}};
		      luma_frmbuf_addr_done_2 <= {C_VIDEO_CHAN{1'b0}};
		      luma_frmbuf_addr_done_2_new <= {C_VIDEO_CHAN{1'b0}};		      
		      chroma_frmbuf_addr_done_2 <= {C_VIDEO_CHAN{1'b0}};
		      chroma_frmbuf_addr_done_2_new <= {C_VIDEO_CHAN{1'b0}};
		      int_luma_frmbuf_addr_done_2 <= {C_VIDEO_CHAN{1'b0}};
		      int_chroma_frmbuf_addr_done_2 <= {C_VIDEO_CHAN{1'b0}};
		      luma_outofrange_2 <= 1'b1;
		      chroma_outofrange_2 <= 1'b1;
		      
		      //synthesis translate_off
		      $display ("[%m:%0t] ERROR: fifo_2 address requests received but not in any video channel region. Addr=%0x. This is illegal case.",
				$time, s_axi_araddr_2);
		      $stop;
		      //synthesis translate_on 	      
		   end
		 endcase // case (s_axi_aruser_2)
	      end // if (s_axi_arvalid_2)
	      else begin
		 fifo_read_en_2 <= 1'b0; // deassert to prevent passing the head data of next request
		 luma_frmbuf_addr_done_2 <= 0;
		 luma_frmbuf_addr_done_2_new <= 0;		 
		 chroma_frmbuf_addr_done_2 <= 0;
		 chroma_frmbuf_addr_done_2_new <= 0;
		 int_luma_frmbuf_addr_done_2 <= 0;
		 int_chroma_frmbuf_addr_done_2 <= 0;
		 luma_outofrange_2 <= {C_VIDEO_CHAN{1'b0}};
		 chroma_outofrange_2 <= {C_VIDEO_CHAN{1'b0}};
                 ot_luma_buf_id_2 <= 2'b00;
                 ot_chroma_buf_id_2 <= 2'b00;

                luma_buf_rd_cnt2[0] <= (luma_buf_rd_cnt2[0] & {C_RD_BUF_CNT_WIDTH{~cons_luma_frmbuf_addr_done_in[0]}});
                luma_buf_rd_cnt2[1] <= (luma_buf_rd_cnt2[1] & {C_RD_BUF_CNT_WIDTH{~cons_luma_frmbuf_addr_done_in[1]}});
                luma_buf_rd_cnt2[2] <= (luma_buf_rd_cnt2[2] & {C_RD_BUF_CNT_WIDTH{~cons_luma_frmbuf_addr_done_in[2]}});
                luma_buf_rd_cnt2[3] <= (luma_buf_rd_cnt2[3] & {C_RD_BUF_CNT_WIDTH{~cons_luma_frmbuf_addr_done_in[3]}});
                chroma_buf_rd_cnt2[0] <= (chroma_buf_rd_cnt2[0] & {C_RD_BUF_CNT_WIDTH{(~cons_chroma_frmbuf_addr_done_in[0])}});
                chroma_buf_rd_cnt2[1] <= (chroma_buf_rd_cnt2[1] & {C_RD_BUF_CNT_WIDTH{(~cons_chroma_frmbuf_addr_done_in[1])}});
                chroma_buf_rd_cnt2[2] <= (chroma_buf_rd_cnt2[2] & {C_RD_BUF_CNT_WIDTH{(~cons_chroma_frmbuf_addr_done_in[2])}});
                chroma_buf_rd_cnt2[3] <= (chroma_buf_rd_cnt2[3] & {C_RD_BUF_CNT_WIDTH{(~cons_chroma_frmbuf_addr_done_in[3])}});

	      end
	   end // always @ (posedge S_AXI_ACLK or negedge S_AXI_ARESETN)

	 
	 
	 // Record previous channel status
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESET)
	 //always @(posedge S_AXI_ACLK or negedge f2_rst)
	 always @(posedge S_AXI_ACLK)
	   begin
	      //if (~S_AXI_ARESETN) begin
	      if (~f2_rst) begin
		 S_AXI_ARREADY_2_r <= 1'b0;
		 S_AXI_AR_LUMA_CHANID_2_r <= 0;
		 S_AXI_AR_CHROMA_CHANID_2_r <= 0;
		 
	      end
	      else if (C_DEC_ENC_N == 0) begin
		 S_AXI_ARREADY_2_r <= S_AXI_ARREADY_2 & ~idle_insert_2;
		 if (S_AXI_ARVALID & (S_AXI_ARID[3] == 1)) begin
		    S_AXI_AR_LUMA_CHANID_2_r <= S_AXI_AR_LUMA_CHANID;
		    S_AXI_AR_CHROMA_CHANID_2_r <= S_AXI_AR_CHROMA_CHANID;
		    
		 end
		 else begin
		    S_AXI_AR_LUMA_CHANID_2_r <= 3'b100;
		    S_AXI_AR_CHROMA_CHANID_2_r <= 3'b100;
		    
		 end
	      end
	   end
	 
	 // Idle insertion when switching videl channel in back-to-back requests
	 // Since gating logic requires 1 cycle of latency, if channel switches in the middle of continuous request,
	 // the "head" of new channel request can be passed thru accidentally. To prevent this,
	 // insert an idle cycle when such condition is detected.
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	 //always @(posedge S_AXI_ACLK or negedge S_AXI_ARESET)
	 //always @(posedge S_AXI_ACLK or negedge f2_rst)
	 always @(posedge S_AXI_ACLK)
	   begin
	      //if (~S_AXI_ARESETN)
	      //if (~S_AXI_ARESET)
	      if (~f2_rst)
		idle_insert_2 <= 1'b0;
	      else if ( (C_DEC_ENC_N == 0) 
			&  S_AXI_ARVALID_r & S_AXI_ARREADY_2_r 
			& S_AXI_ARVALID & (S_AXI_ARID[3] == 1) 
			& (
			   ( S_AXI_AR_LUMA_CHANID != S_AXI_AR_LUMA_CHANID_2_r) & ~S_AXI_AR_LUMA_CHANID[2] & ~S_AXI_AR_LUMA_CHANID_2_r[2]
			|  ( S_AXI_AR_CHROMA_CHANID != S_AXI_AR_CHROMA_CHANID_2_r) & ~S_AXI_AR_CHROMA_CHANID[2] & ~S_AXI_AR_CHROMA_CHANID_2_r[2]
			   )
			)
		idle_insert_2 <= 1'b1;
	      else
		idle_insert_2 <= 1'b0;
	   end
	 
	 
	 
      end // block: gen_fifo_2
      else begin: gen_no_fifo_2

	 assign S_AXI_ARREADY_2 = 0;
	 assign s_axi_arid_2 = 0; 
	 assign s_axi_araddr_2 = 0; 
	 assign s_axi_arlen_2 = 0; 
	 assign s_axi_arsize_2 = 0; 
	 assign s_axi_arburst_2 = 0; 
	 assign s_axi_arlock_2 = 0; 
	 assign s_axi_arcache_2 = 0; 
	 assign s_axi_arprot_2 = 0; 
	 assign s_axi_arqos_2 = 0; 
	 assign s_axi_arvalid_2 = 0; 

	 always @(posedge S_AXI_ACLK) begin
	    luma_outofrange_2 <= {C_VIDEO_CHAN{1'b0}};
	    chroma_outofrange_2 <= {C_VIDEO_CHAN{1'b0}};
	    luma_frmbuf_addr_done_2 <= 0;
	    luma_frmbuf_addr_done_2_new <= 0;	    
	    chroma_frmbuf_addr_done_2 <= 0;		 
	    chroma_frmbuf_addr_done_2_new <= 0;
	    int_luma_frmbuf_addr_done_2 <= 0;
	    int_chroma_frmbuf_addr_done_2 <= 0;
	 end
      end
   endgenerate

   wire [2:0] dummy;
   generate
      if (C_DEC_ENC_N == 0) begin: gen_enc_stream_switch

	
	//axis switch for the three ARchannel streams that were created above
	axis_switch_0
		axis_switch_0_inst
	(
          .aclk(S_AXI_ACLK),
	  .aresetn(S_AXI_ARESETN),
	  //.aresetn(S_AXI_ARESET),
	  .s_axis_tvalid({(s_axi_arvalid_2 & fifo_read_en_2), (s_axi_arvalid_1& fifo_read_en_1), (s_axi_arvalid_0&read_en_0)}),//O
	  .s_axis_tready({s_axi_arready_2, s_axi_arready_1, s_axi_arready_0}),//I Three streams generated above
	  .s_axis_tdata({{3'h0,s_axi_araddr_2,s_axi_arlen_2,s_axi_arsize_2,s_axi_arburst_2,s_axi_arlock_2,s_axi_arcache_2,s_axi_arprot_2,s_axi_arqos_2,s_axi_arid_2}, 
	  		{3'h0,s_axi_araddr_1,s_axi_arlen_1,s_axi_arsize_1,s_axi_arburst_1,s_axi_arlock_1,s_axi_arcache_1,s_axi_arprot_1,s_axi_arqos_1,s_axi_arid_1}, 
			{3'h0,s_axi_araddr_0,s_axi_arlen_0,s_axi_arsize_0,s_axi_arburst_0,s_axi_arlock_0,s_axi_arcache_0,s_axi_arprot_0,s_axi_arqos_0,s_axi_arid_0}}),
	  .s_axis_tkeep({12'hff, 12'hff, 12'hff}),
	  .s_axis_tlast({1'b0, 1'b0, 1'b0}),
	  .s_axis_tid({3'd2,3'd1,3'd0}),
	  .m_axis_tvalid(m_axi_arvalid),		//switching Stream output 
	  .m_axis_tready(m_axi_arready),
	  .m_axis_tdata({dummy,m_axi_araddr,m_axi_arlen,m_axi_arsize,m_axi_arburst,m_axi_arlock,m_axi_arcache,m_axi_arprot,m_axi_arqos,m_axi_arid}),
	  .m_axis_tkeep(),
	  .m_axis_tlast(),
	  .m_axis_tid(),
	  .s_req_suppress(3'h0),
	  .s_decode_err()	
	);
	assign m_axi_arregion = S_AXI_ARREGION;
      end // block: gen_enc_crossbar
      else begin: gen_dec_passthru
	 
	 assign m_axi_arid = s_axi_arid_0 ;
	 assign m_axi_araddr = s_axi_araddr_0 ;
	 assign m_axi_arlen = s_axi_arlen_0 ;
	 assign m_axi_arsize = s_axi_arsize_0 ;
	 assign m_axi_arburst = s_axi_arburst_0 ;
	 assign m_axi_arlock = s_axi_arlock_0 ;
	 assign m_axi_arcache = s_axi_arcache_0 ;
	 assign m_axi_arprot = s_axi_arprot_0 ;
	 assign m_axi_arregion = s_axi_arregion_0 ;
	 assign m_axi_arqos = s_axi_arqos_0 ;
	 assign m_axi_arvalid = s_axi_arvalid_0 & (read_en_0 | C_DEC_ENC_N);
	 assign s_axi_arready_0 = m_axi_arready;
	 

      end
   endgenerate
   

   
   // Pass-thru AXI write transactions

   assign m_axi_awid    = S_AXI_AWID;
   assign m_axi_awaddr  = S_AXI_AWADDR;
   assign m_axi_awlen   = S_AXI_AWLEN;
   assign m_axi_awsize  = S_AXI_AWSIZE;
   assign m_axi_awburst = S_AXI_AWBURST;
   assign m_axi_awlock  = S_AXI_AWLOCK;
   assign m_axi_awcache = S_AXI_AWCACHE;
   assign m_axi_awprot  = S_AXI_AWPROT;
   assign m_axi_awregion= S_AXI_AWREGION;
   assign m_axi_awqos   = S_AXI_AWQOS;
   assign m_axi_awvalid = S_AXI_AWVALID;
   assign m_axi_wdata   = S_AXI_WDATA;
   assign m_axi_wstrb   = S_AXI_WSTRB;
   assign m_axi_wlast   = S_AXI_WLAST;
   assign m_axi_wvalid  = S_AXI_WVALID;
   assign m_axi_bready  = S_AXI_BREADY;

   assign S_AXI_AWREADY = m_axi_awready;
   assign S_AXI_WREADY  = m_axi_wready;
   assign S_AXI_BID     = m_axi_bid;
   assign S_AXI_BRESP   = m_axi_bresp;
   assign S_AXI_BVALID  = m_axi_bvalid;

endmodule // syn_ip_v1_0_S_AXI_MM


`timescale 1 ns / 1 ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Xilinx, Inc.
// Engineer: Davy Huang
// 
// Create Date: 04/24/2018 01:24:00 PM
// Design Name: VCU low latency synchronization IP
// Module Name: sync_ip_v1_0_2_M_AXI_MM
// Project Name: VCU low latency 
// Target Devices: Zynq UltraScale+ EV
// Tool Versions: Vivado 2018.1
// Description: 
//   
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module syn_ip_v1_0_M_AXI_MM #
  (
   // Users to add parameters here

   // User parameters ends
   // Do not modify the parameters beyond this line

   // Thread ID Width
   parameter integer C_M_AXI_ID_WIDTH	= 4,
   // Width of Address Bus
   parameter integer C_M_AXI_ADDR_WIDTH	= 64,
   // Width of Data Bus
   parameter integer C_M_AXI_DATA_WIDTH	= 128,
   // Width of User Write Address Bus
   parameter integer C_M_AXI_AWUSER_WIDTH	= 0,
   // Width of User Read Address Bus
   parameter integer C_M_AXI_ARUSER_WIDTH	= 0,
   // Width of User Write Data Bus
   parameter integer C_M_AXI_WUSER_WIDTH	= 0,
   // Width of User Read Data Bus
   parameter integer C_M_AXI_RUSER_WIDTH	= 0,
   // Width of User Response Bus
   parameter integer C_M_AXI_BUSER_WIDTH	= 0
   )
   (
    // Users to add ports here
    input wire [C_M_AXI_ID_WIDTH-1:0] m_axi_arid,
    input wire [C_M_AXI_ADDR_WIDTH-1:0] m_axi_araddr,
    input wire [7:0] m_axi_arlen,
    input wire [2:0] m_axi_arsize,
    input wire [1:0] m_axi_arburst,
    input wire [0:0] m_axi_arlock,
    input wire [3:0] m_axi_arcache,
    input wire [2:0] m_axi_arprot,
    input wire [3:0] m_axi_arregion,
    input wire [3:0] m_axi_arqos,
    input wire       m_axi_arvalid,
    output wire      m_axi_arready,
    output wire [C_M_AXI_ID_WIDTH-1:0]  m_axi_rid,
    output wire [C_M_AXI_DATA_WIDTH-1:0] m_axi_rdata,
    output wire [1:0]  m_axi_rresp,
    output wire      m_axi_rlast,
    output wire      m_axi_rvalid,
    input wire       m_axi_rready,
    
    input wire [C_M_AXI_ID_WIDTH-1:0] m_axi_awid,
    input wire [C_M_AXI_ADDR_WIDTH-1:0] m_axi_awaddr,
    input wire [7:0] m_axi_awlen,
    input wire [2:0] m_axi_awsize,
    input wire [1:0] m_axi_awburst,
    input wire       m_axi_awlock,
    input wire [3:0] m_axi_awcache,
    input wire [2:0] m_axi_awprot,
    input wire [3:0] m_axi_awregion,
    input wire [3:0] m_axi_awqos,
    input wire       m_axi_awvalid,
    output wire        m_axi_awready,
    input wire [C_M_AXI_DATA_WIDTH-1:0] m_axi_wdata,
    input wire [15:0] m_axi_wstrb,
    input wire       m_axi_wlast,
    input wire       m_axi_wvalid,
    output wire        m_axi_wready,
    output wire [C_M_AXI_ID_WIDTH-1:0]  m_axi_bid,
    output wire [1:0]  m_axi_bresp,
    output wire        m_axi_bvalid,
    input wire       m_axi_bready,

    // User ports ends
    // Do not modify the ports beyond this line
    // Global Clock Signal.
    input wire  M_AXI_ACLK,
    // Global Reset Singal. This Signal is Active Low
    input wire  M_AXI_ARESETN,
    // Master Interface Write Address ID
    output wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_AWID,
    // Master Interface Write Address
    output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
    // Burst length. The burst length gives the exact number of transfers in a burst
    output wire [7 : 0] M_AXI_AWLEN,
    // Burst size. This signal indicates the size of each transfer in the burst
    output wire [2 : 0] M_AXI_AWSIZE,
    // Burst type. The burst type and the size information, 
    // determine how the address for each transfer within the burst is calculated.
    output wire [1 : 0] M_AXI_AWBURST,
    // Lock type. Provides additional information about the
    // atomic characteristics of the transfer.
    output wire  M_AXI_AWLOCK,
    // Memory type. This signal indicates how transactions
    // are required to progress through a system.
    output wire [3 : 0] M_AXI_AWCACHE,
    // Protection type. This signal indicates the privilege
    // and security level of the transaction, and whether
    // the transaction is a data access or an instruction access.
    output wire [2 : 0] M_AXI_AWPROT,
    // Quality of Service, QoS identifier sent for each write transaction.
    output wire [3 : 0] M_AXI_AWQOS,
    // Optional User-defined signal in the write address channel.
    output wire [C_M_AXI_AWUSER_WIDTH-1 : 0] M_AXI_AWUSER,
    // Write address valid. This signal indicates that
    // the channel is signaling valid write address and control information.
    output wire  M_AXI_AWVALID,
    // Write address ready. This signal indicates that
    // the slave is ready to accept an address and associated control signals
    input wire  M_AXI_AWREADY,
    // Master Interface Write Data.
    output wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
    // Write strobes. This signal indicates which byte
    // lanes hold valid data. There is one write strobe
    // bit for each eight bits of the write data bus.
    output wire [C_M_AXI_DATA_WIDTH/8-1 : 0] M_AXI_WSTRB,
    // Write last. This signal indicates the last transfer in a write burst.
    output wire  M_AXI_WLAST,
    // Optional User-defined signal in the write data channel.
    output wire [C_M_AXI_WUSER_WIDTH-1 : 0] M_AXI_WUSER,
    // Write valid. This signal indicates that valid write
    // data and strobes are available
    output wire  M_AXI_WVALID,
    // Write ready. This signal indicates that the slave
    // can accept the write data.
    input wire  M_AXI_WREADY,
    // Master Interface Write Response.
    input wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_BID,
    // Write response. This signal indicates the status of the write transaction.
    input wire [1 : 0] M_AXI_BRESP,
    // Optional User-defined signal in the write response channel
    input wire [C_M_AXI_BUSER_WIDTH-1 : 0] M_AXI_BUSER,
    // Write response valid. This signal indicates that the
    // channel is signaling a valid write response.
    input wire  M_AXI_BVALID,
    // Response ready. This signal indicates that the master
    // can accept a write response.
    output wire  M_AXI_BREADY,
    // Master Interface Read Address.
    output wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_ARID,
    // Read address. This signal indicates the initial
    // address of a read burst transaction.
    output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
    // Burst length. The burst length gives the exact number of transfers in a burst
    output wire [7 : 0] M_AXI_ARLEN,
    // Burst size. This signal indicates the size of each transfer in the burst
    output wire [2 : 0] M_AXI_ARSIZE,
    // Burst type. The burst type and the size information, 
    // determine how the address for each transfer within the burst is calculated.
    output wire [1 : 0] M_AXI_ARBURST,
    // Lock type. Provides additional information about the
    // atomic characteristics of the transfer.
    output wire  M_AXI_ARLOCK,
    // Memory type. This signal indicates how transactions
    // are required to progress through a system.
    output wire [3 : 0] M_AXI_ARCACHE,
    // Protection type. This signal indicates the privilege
    // and security level of the transaction, and whether
    // the transaction is a data access or an instruction access.
    output wire [2 : 0] M_AXI_ARPROT,
    // Quality of Service, QoS identifier sent for each read transaction
    output wire [3 : 0] M_AXI_ARQOS,
    // Optional User-defined signal in the read address channel.
    output wire [C_M_AXI_ARUSER_WIDTH-1 : 0] M_AXI_ARUSER,
    // Write address valid. This signal indicates that
    // the channel is signaling valid read address and control information
    output wire  M_AXI_ARVALID,
    // Read address ready. This signal indicates that
    // the slave is ready to accept an address and associated control signals
    input wire  M_AXI_ARREADY,
    // Read ID tag. This signal is the identification tag
    // for the read data group of signals generated by the slave.
    input wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_RID,
    // Master Read Data
    input wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
    // Read response. This signal indicates the status of the read transfer
    input wire [1 : 0] M_AXI_RRESP,
    // Read last. This signal indicates the last transfer in a read burst
    input wire  M_AXI_RLAST,
    // Optional User-defined signal in the read address channel.
    input wire [C_M_AXI_RUSER_WIDTH-1 : 0] M_AXI_RUSER,
    // Read valid. This signal indicates that the channel
    // is signaling the required read data.
    input wire  M_AXI_RVALID,
    // Read ready. This signal indicates that the master can
    // accept the read data and response information.
    output wire  M_AXI_RREADY
    );


   assign m_axi_rid = M_AXI_RID;
   assign m_axi_rdata = M_AXI_RDATA;
   assign m_axi_rresp = M_AXI_RRESP;
   assign m_axi_rlast = M_AXI_RLAST;
   assign m_axi_rvalid = M_AXI_RVALID;
   assign M_AXI_RREADY = m_axi_rready;

   assign M_AXI_ARID  = m_axi_arid;
   assign M_AXI_ARADDR = m_axi_araddr;
   assign M_AXI_ARLEN = m_axi_arlen;
   assign M_AXI_ARSIZE = m_axi_arsize;
   assign M_AXI_ARBURST  = m_axi_arburst;
   assign M_AXI_ARLOCK = m_axi_arlock;
   assign M_AXI_ARCACHE = m_axi_arcache;
   assign M_AXI_ARPROT = m_axi_arprot;
   assign M_AXI_ARREGION = m_axi_arregion;
   assign M_AXI_ARQOS = m_axi_arqos;
   assign M_AXI_ARVALID  = m_axi_arvalid;
   assign M_AXI_ARUSER = 0;
   assign m_axi_arready = M_AXI_ARREADY;

   assign M_AXI_WDATA  = m_axi_wdata;
   assign M_AXI_WSTRB  = m_axi_wstrb;
   assign M_AXI_WLAST  = m_axi_wlast;
   assign M_AXI_WVALID = m_axi_wvalid;
   assign M_AXI_WUSER  = 0;
   assign m_axi_wready = M_AXI_WREADY;
   
   assign m_axi_bid = M_AXI_BID;
   assign m_axi_bresp = M_AXI_BRESP;
   assign m_axi_bvalid = M_AXI_BVALID;
   assign M_AXI_BREADY = m_axi_bready;

   assign M_AXI_AWID  = m_axi_awid;
   assign M_AXI_AWADDR = m_axi_awaddr;
   assign M_AXI_AWLEN = m_axi_awlen;
   assign M_AXI_AWSIZE = m_axi_awsize;
   assign M_AXI_AWBURST  = m_axi_awburst;
   assign M_AXI_AWLOCK = m_axi_awlock;
   assign M_AXI_AWCACHE = m_axi_awcache;
   assign M_AXI_AWPROT = m_axi_awprot;
   assign M_AXI_AWREGION = m_axi_awregion;
   assign M_AXI_AWQOS = m_axi_awqos;
   assign M_AXI_AWVALID  = m_axi_awvalid;
   assign M_AXI_AWUSER = 0;
   assign m_axi_awready = M_AXI_AWREADY;
   
   

endmodule


