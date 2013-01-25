`include "vme64x_bfm.svh"
`include "svec_vme_buffers.svh"
`include "regs/sxldr_regs.vh"

`define WIRE_VME_PINS2(slot_id) \
    .VME_AS_n_i(VME_AS_n),\
    .VME_RST_n_i(VME_RST_n),\
    .VME_WRITE_n_i(VME_WRITE_n),\
    .VME_AM_i(VME_AM),\
    .VME_DS_n_i(VME_DS_n),\
    .VME_GA_i(_gen_ga(slot_id)),\
    .VME_DTACK_n_o(VME_DTACK_n),\
    .VME_LWORD_n_b(VME_LWORD_n),\
    .VME_ADDR_b(VME_ADDR),\
    .VME_DATA_b(VME_DATA),\
    .VME_BBSY_n_i(VME_BBSY_n),\
    .VME_DTACK_OE_o(VME_DTACK_OE),\
    .VME_DATA_DIR_o(VME_DATA_DIR),\
    .VME_DATA_OE_N_o(VME_DATA_OE_N),\
    .VME_ADDR_DIR_o(VME_ADDR_DIR),\
    .VME_ADDR_OE_N_o(VME_ADDR_OE_N)


		
module main;

   reg rst_n = 0;
   reg clk_20m = 0;
   wire cclk, din, program_b, init_b, done, suspend;
   wire [1:0] m;

   
   always #25ns clk_20m <= ~clk_20m;
   
   initial begin
      repeat(10000) @(posedge clk_20m);
      rst_n = 1;
   end

   
   IVME64X VME(rst_n);

   `DECLARE_VME_BUFFERS(VME.slave);


   svec_sfpga_top
     
     DUT (
	  .lclk_n_i(clk_20m),
	  .rst_n_i(rst_n),
     
	  `WIRE_VME_PINS2(8),

          .boot_clk_o(cclk),
          .boot_config_o(program_b),
          .boot_status_i(init_b),
          .boot_done_i(done),
          .boot_dout_o(din),

           .spi_cs_n_o(spi_cs),
          .spi_sclk_o(spi_sclk),
          .spi_mosi_o(spi_mosi),
          .spi_miso_i(spi_miso)
      
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


   M25Pxxx Flash(.S(spi_cs), .C(spi_sclk), .HOLD(1'b1), .D(spi_mosi), .Q(spi_miso), .Vpp_W(32'h0), .Vcc(32'd3000));

   parameter [12*8:1] mem = "../../../software/sdb-flash/image.vmf";
   defparam Flash.memory_file = mem;
   
class CSimDrv_Xloader;

   protected CBusAccessor_VME64x acc;
   protected uint64_t base;
   protected byte _dummy;
   
   function new(CBusAccessor_VME64x _acc, uint64_t _base);
      acc = _acc;
      base = _base;
   endfunction

   protected task flash_xfer(bit cs, byte data_in, ref byte data_out = _dummy);
      uint64_t rv;
      
      while(1) begin
         acc.read(base + `ADDR_SXLDR_FAR, rv);
         if(rv & `SXLDR_FAR_READY)
           break;
      end

      acc.write(base + `ADDR_SXLDR_FAR, data_in | (cs ? `SXLDR_FAR_CS:0) | `SXLDR_FAR_XFER);
      
      while(1) begin
         acc.read(base + `ADDR_SXLDR_FAR, rv);
         if(rv & `SXLDR_FAR_READY)
           break;
      end

      data_out = rv & 'hff;
         
   endtask // flash_xfer
   
   
   task flash_command(int cmd, byte data_in[], output byte data_out[], input int size);
      int i;
      flash_xfer(0, 0);
      flash_xfer(1, cmd);
      for(i=0;i<size;i++)
        begin
           byte t;
           flash_xfer(1, data_in[i], t);
           data_out[i] = t;
        end
      
      flash_xfer(0, 0);
   endtask // flash_command
   
     
   
   task enter_boot_mode();
      int i;
      const int boot_seq[8] = '{'hde, 'had, 'hbe, 'hef, 'hca, 'hfe, 'hba, 'hbe};
      
      for(i=0;i<8;i++)
        acc.write(base + `ADDR_SXLDR_BTRIGR, boot_seq[i]);
   endtask // enter_boot_mode

   
   task load_bitstream(string filename);
      int f,i, pos=0;
      uint64_t csr;
     
      acc.write(base + `ADDR_SXLDR_CSR, `SXLDR_CSR_SWRST );
      acc.write(base + `ADDR_SXLDR_CSR, `SXLDR_CSR_START | `SXLDR_CSR_MSBF);
      f  = $fopen(filename, "r");
      
      while(!$feof(f))
        begin
           uint64_t r,r2;
           acc.read(base + `ADDR_SXLDR_FIFO_CSR, r);
           
           if(!(r&`SXLDR_FIFO_CSR_FULL)) begin
              int n;
              int x;
              
              n  = $fread(x, f);
              pos+=n;

              if((pos % 4000) == 0)
                $display("%d bytes sent", pos);
              
              
              r=x;
              r2=(n - 1) | ($feof(f) ? `SXLDR_FIFO_R0_XLAST : 0);
              acc.write(base +`ADDR_SXLDR_FIFO_R0, r2);
              acc.write(base +`ADDR_SXLDR_FIFO_R1, r);
              end
        end

      $fclose(f);

      while(1) begin
        acc.read (base + `ADDR_SXLDR_CSR, csr);
         if(csr & `SXLDR_CSR_DONE) begin
            $display("Bitstream loaded, status: %s", (csr & `SXLDR_CSR_ERROR ? "ERROR" : "OK"));
            acc.write(base + `ADDR_SXLDR_CSR, `SXLDR_CSR_EXIT);
            return;
         end
      end

   endtask

endclass
   
   
   
   initial begin
      uint64_t d;
      byte payload[];

      
      int i, result;

      
      CBusAccessor_VME64x acc = new(VME.master);
      CSimDrv_Xloader drv;

      payload[0] = 0;
      payload[1] = 0;
      payload[2] = 0;
      
      

      #600us;
      acc.set_default_modifiers(A32 | CR_CSR | D32);

      drv = new(acc, 'h70000);

      #100us;
      
      drv.enter_boot_mode();

      #100us;

      // read ID from the flash
      drv.flash_command('h9f, payload, payload, 3);

      $display("Flash ID: %02x %02x %02x\n", payload[0], payload[1], payload[2]);
      
    //  drv.load_bitstream("sample_bitstream/crc_gen.bin");
      
      
   end

  
endmodule // main



