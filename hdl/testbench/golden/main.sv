`include "vme64x_bfm.svh"
`include "svec_vme_buffers.svh"

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

   task automatic init_vme64x_core(ref CBusAccessor_VME64x acc);
      uint64_t rv;
      
      /* map func0 to 0x80000000, A32 */

      acc.write('h7ff63, 'h80, A32|CR_CSR|D08Byte3);
      acc.write('h7ff67, 0, CR_CSR|A32|D08Byte3);
      acc.write('h7ff6b, 0, CR_CSR|A32|D08Byte3);
      acc.write('h7ff6f, 36, CR_CSR|A32|D08Byte3);
      acc.write('h7ff33, 1, CR_CSR|A32|D08Byte3);
      acc.write('h7fffb, 'h10, CR_CSR|A32|D08Byte3); /* enable module (BIT_SET = 0x10) */


      acc.set_default_modifiers(A32 | D32 | SINGLE);
   endtask // init_vme64x_core
   
   
   initial begin
      uint64_t d;
      
      int i, result;
      
      CBusAccessor_VME64x acc = new(VME.master);

      
      #20us;
      init_vme64x_core(acc);


      acc.read(0, d, A32|SINGLE|D32);
      $display("Read0: %x\n", d);
      
   end

  
endmodule // main



