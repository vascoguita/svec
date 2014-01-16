`include "vme64x_bfm.svh"
`include "svec_vme_buffers.svh"
`include "../regs/golden_regs.vh"

module main;

   reg rst_n = 0;
   reg clk_20m = 0;
   
   always #25ns clk_20m <= ~clk_20m;
   
   initial begin
      repeat(20) @(posedge clk_20m);
      rst_n = 1;
   end
   
   IVME64X VME(rst_n);

   `DECLARE_VME_BUFFERS(VME.slave);

   svec_top
     
     DUT (
	  .clk_20m_vcxo_i(clk_20m),
	  .rst_n_i(rst_n),
     
	  `WIRE_VME_PINS(8)
  	  );

   task automatic config_vme_function(ref CBusAccessor_VME64x acc, input int func, uint64_t base, int am);
      uint64_t addr = 'h7ff63 + func * 'h10;
      uint64_t val = (base) | (am << 2);

      $display("Func%d ADER=0x%x", func, val);
      
      
      acc.write(addr + 0, (val >> 24) & 'hff, CR_CSR|A32|D08Byte3);
      acc.write(addr + 4, (val >> 16) & 'hff, CR_CSR|A32|D08Byte3);
      acc.write(addr + 8, (val >> 8)  & 'hff, CR_CSR|A32|D08Byte3);
      acc.write(addr + 12, (val >> 0) & 'hff, CR_CSR|A32|D08Byte3);
 
      
   endtask // config_vme_function
   
   
   task automatic init_vme64x_core(ref CBusAccessor_VME64x acc);
      uint64_t rv;


      /* map func0 to 0x80000000, A32 */
      config_vme_function(acc, 0, 'h80000000, 'h09);
      /* map func1 to 0xc00000, A24 */
      config_vme_function(acc, 1, 'hc00000, 'h39);
      
      acc.write('h7ff33, 1, CR_CSR|A32|D08Byte3);
      acc.write('h7fffb, 'h10, CR_CSR|A32|D08Byte3); /* enable module (BIT_SET = 0x10) */

      acc.set_default_modifiers(A24 | D32 | SINGLE);
   endtask // init_vme64x_core
   
   
   initial begin
      uint64_t d;
      
      int i, result;
      
      CBusAccessor_VME64x acc = new(VME.master);

      
      #20us;
      init_vme64x_core(acc);


//      acc.read('h80000000, d, A32|SINGLE|D32);
  //    $display("Read0: %x\n", d);
      $display("pre-read");
      acc.read('hc00000, d, A24|SINGLE|D32);
      $display("Read0: %x\n", d);
      acc.read('h80000000, d, A32|SINGLE|D32);
      $display("Read1: %x\n", d);

/*
       acc.write('h80010000, d, A24|SINGLE|D32);
      acc.read('h80010000, d, A24|SINGLE|D32);

      acc.write('h80010000 + `ADDR_GLD_I2CR0, ~`GLD_I2CR0_SCL_OUT, A24|SINGLE|D32);
      acc.write('h80010000 + `ADDR_GLD_I2CR0, ~`GLD_I2CR0_SDA_OUT, A24|SINGLE|D32);

      acc.write('h810000 + `ADDR_GLD_I2CR1, ~`GLD_I2CR0_SCL_OUT, A24|SINGLE|D32);
      acc.write('h810000 + `ADDR_GLD_I2CR1, ~`GLD_I2CR0_SDA_OUT, A24|SINGLE|D32);
      
      $display("Read1: %x\n", d);
  */    
   end

  
endmodule // main



