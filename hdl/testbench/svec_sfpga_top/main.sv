`include "vme64x_bfm.svh"
`include "svec_vme_buffers.svh"
`include "regs/xloader_regs.vh"

module main;

   reg rst_n = 0;
   reg clk_20m = 0;
   wire cclk, din, program_b, init_b, done, suspend;
   wire [1:0] m;

   
   always #25ns clk_20m <= ~clk_20m;
   
   initial begin
      repeat(20) @(posedge clk_20m);
      rst_n = 1;
   end

   
   IVME64X VME(rst_n);

   `DECLARE_VME_BUFFERS(VME.slave);


   svec_sfpga_top
     
     DUT (
	  .lclk_n_i(clk_20m),
	  .rst_n_i(rst_n),
     
	  `WIRE_VME_PINS(8),

          .boot_clk_o(cclk),
          .boot_config_o(program_b),
          .boot_status_i(init_b),
          .boot_done_i(done),
          .boot_dout_o(din)
	  );

   SIM_CONFIG_S6_SERIAL2
  #(
    .DEVICE_ID(32'h34000093) // 6slx150t
    ) U_serial_sim 
    (
     .DONE(done),
     .CCLK(cclk),
     .DIN(din),
     .INITB(init_b), 
     .M(2'b11),
     .PROGB(program_b)
     );



class CSimDrv_Xloader;

   protected CBusAccessor_VME64x acc;
   protected uint64_t base;
   
   function new(CBusAccessor_VME64x _acc, uint64_t _base);
      acc = _acc;
      base = _base;
   endfunction
     
        
   task enter_boot_mode();
      int i;
      const int boot_seq[8] = '{'hde, 'had, 'hbe, 'hef, 'hca, 'hfe, 'hba, 'hbe};
      
      for(i=0;i<8;i++)
        acc.write(base + `ADDR_XLDR_BTRIGR, boot_seq[i]);
   endtask // enter_boot_mode

   
   task load_bitstream(string filename);
      int f,i, pos=0;
      uint64_t csr;
     
      acc.write(base + `ADDR_XLDR_CSR, `XLDR_CSR_SWRST );
      acc.write(base + `ADDR_XLDR_CSR, `XLDR_CSR_START | `XLDR_CSR_MSBF);
      f  = $fopen(filename, "r");
      
      while(!$feof(f))
        begin
           uint64_t r,r2;
           acc.read(base + `ADDR_XLDR_FIFO_CSR, r);
           
           if(!(r&`XLDR_FIFO_CSR_FULL)) begin
              int n;
              int x;
              
              n  = $fread(x, f);
              pos+=n;

              if((pos % 4000) == 0)
                $display("%d bytes sent", pos);
              
              
              r=x;
              r2=(n - 1) | ($feof(f) ? `XLDR_FIFO_R0_XLAST : 0);
              acc.write(base +`ADDR_XLDR_FIFO_R0, r2);
              acc.write(base +`ADDR_XLDR_FIFO_R1, r);
              end
        end

      $fclose(f);

      while(1) begin
        acc.read (base + `ADDR_XLDR_CSR, csr);
         if(csr & `XLDR_CSR_DONE) begin
            $display("Bitstream loaded, status: %s", (csr & `XLDR_CSR_ERROR ? "ERROR" : "OK"));
            acc.write(base + `ADDR_XLDR_CSR, `XLDR_CSR_EXIT);
            return;
         end
      end

   endtask

endclass
   
   
   
   initial begin
      uint64_t d;
      
      int i, result;
      
      CBusAccessor_VME64x acc = new(VME.master);
      CSimDrv_Xloader drv;
      

      #10us;
      acc.set_default_modifiers(A32 | CR_CSR | D32);
     // acc.write('h70000 + `ADDR_XLDR_GPIOR, 'haa);

      

      drv = new(acc, 'h70000);

      #100us;
      
      drv.enter_boot_mode();

      #100us;
      
      drv.load_bitstream("sample_bitstream/crc_gen.bin");
      
      
   end

  
endmodule // main



