//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                                   M25P128 / 
//      _/_/_/_/_/       _/_/_/           /                                           /  
//      _/_/_/_/_/_/     _/_/_/          /                                   128Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.1 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2008 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              


`timescale 1ns/1ps

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           TOP LEVEL MODULE                            --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/



module M25Pxxx (S, C, HOLD, D, Q, Vcc, Vpp_W);  //P128



`include "include/DevParam.h"


input S;
input C;
input [`VoltageRange] Vcc;

`ifdef DUAL
  inout DQ0; 
  inout DQ1;
`else
  input  D; 
  output Q; 
`endif

`ifdef Vpp_pin //M25PX32
  input [`VoltageRange] Vpp; `endif  

`ifdef HOLD_pin //M25PX32, M25P128 
  input HOLD; `endif

`ifdef W_pin //M25PE16
  input W; `endif

`ifdef RESET_pin //M25PE16
  input RESET; `endif

`ifdef Vpp_W_pin //M25P128
  input [`VoltageRange] Vpp_W; `endif


parameter [40*8:1] memory_file = "";







//----------------------
// HOLD signal
//----------------------

`ifdef HOLD_pin

    reg intHOLD=1;

    always @(HOLD) if (S==0 && C==0)
        intHOLD = HOLD;

    always @(negedge C) if(S==0 && intHOLD!=HOLD)
        intHOLD = HOLD;

    always @(posedge HOLD) if(S==1)
        intHOLD = 1;

    always @intHOLD 
        if(intHOLD==0)
            $display("[%0t ns] ==INFO== Hold condition enabled: communication with the device has been paused.", $time);
        else if(intHOLD==1)
            $display("[%0t ns] ==INFO== Hold condition disabled: communication with the device has been activated.", $time);  

`endif





//-------------------------
// Internal signals
//-------------------------

reg busy=0;

reg [2:0] ck_count = 0; //clock counter (modulo 8) 

reg reset_by_powerOn = 1; //reset_by_powerOn is updated in "Power Up & Voltage check" section

`ifdef RESET_pin
  assign int_reset = !RESET || reset_by_powerOn;
`else
  assign int_reset = reset_by_powerOn;
`endif  

`ifdef HOLD_pin
  assign logicOn = !int_reset && !S && intHOLD; 
`else
  assign logicOn = !int_reset && !S;
`endif  

reg deep_power_down = 0; //updated in "Deep power down" processes
reg ReadAccessOn = 0;
wire WriteAccessOn; 

// indicate type of data that will be latched by the model:
//  C=command , A=address , D=data, N=none, Y=dummy, F=dual_input(F=fast) 
reg [8:1] latchingMode = "N";  


reg [cmdDim-1:0] cmd='h0;
reg [addrDimLatch-1:0] addrLatch='h0;
reg [addrDim-1:0] addr='h0;
reg [dataDim-1:0] data='h0;
reg [dataDim-1:0] dataOut='h0;




//---------------------------------------
//  Vpp_W signal : write protect feature
//---------------------------------------

`ifdef Vpp_W_pin
    assign W_int = ( Vpp_W>=Vcc_min && Vpp_W!=='hX && Vpp_W!=='hZ ) ?  1  :  0;
`endif





//----------------------------
// CUI decoders istantiation
//----------------------------

`include "include/Decoders.h"




//---------------------------
// Modules istantiations
//---------------------------

Memory          mem ();

UtilFunctions   f ();

Program         prog ();

StatusRegister  stat ();

Read            read ();

LockManager     lock ();

`ifdef timingChecks
  `ifdef M25PX32
    TimingCheck     timeCheck (S, C, `D, `Q, HOLD); 
  `elsif M25PE16  
    TimingCheck     timeCheck (S, C, `D, `Q, W, RESET);
  `elsif M25P128
    TimingCheck     timeCheck (S, C, `D, `Q, W_int, HOLD);
  `endif
`endif    
  
`ifdef DUAL
  DualOps         dual (S, C, ck_count, `D, `Q); `endif

`ifdef OTP
  OTP_memory      OTP (); `endif




//----------------------------------
//  Signals for latching control
//----------------------------------

integer iCmd, iAddr, iData;

always @(negedge S) begin : CP_latchInit
    latchingMode = "C";
    ck_count = 0;
    iCmd = cmdDim - 1;
    iAddr = addrDimLatch - 1;
    iData = dataDim - 1;
end


always @(posedge C) if(logicOn)
    ck_count = ck_count + 1;





//-------------------------
// Latching commands
//-------------------------


event cmdLatched;


always @(posedge C) if(logicOn && latchingMode=="C") begin : CP_latchCmd

    cmd[iCmd] = `D;

    if (iCmd>0)
        iCmd = iCmd - 1;
    else if(iCmd==0) begin
        latchingMode = "N";
        -> cmdLatched;
    end    
        
end





//-------------------------
// Latching address
//-------------------------


event addrLatched;


always @(posedge C) if (logicOn && latchingMode=="A") begin : CP_latchAddr

    addrLatch[iAddr] = `D;

    if (iAddr>0)
        iAddr = iAddr - 1;
    else if(iAddr==0) begin
        latchingMode = "N";
        addr = addrLatch[addrDim-1:0];
        -> addrLatched;
    end

end





//-----------------
// Latching data
//-----------------


event dataLatched;


always @(posedge C) if (logicOn && latchingMode=="D") begin : CP_latchData

    data[iData] = `D;

    if (iData>0)
        iData = iData-1;
    else begin
        -> dataLatched;
        $display("  [%0t ns] Data latched: %h", $time, data);
        iData=dataDim-1;
    end    

end






//-----------------
// Latching dummy
//-----------------


event dummyLatched;


always @(posedge C) if (logicOn && latchingMode=="Y") begin : CP_latchDummy

    data[iData] = `D;

    if (iData>0)
        iData = iData-1;
    else begin
        -> dummyLatched;
        $display("  [%0t ns] Dummy byte latched.", $time);
        iData=dataDim-1;
    end    

end








//------------------------------
// Commands recognition control
//------------------------------


event codeRecognized, seqRecognized, startCUIdec;
reg [30*8:1] cmdRecName;


always @(cmdLatched) fork : CP_cmdRecControl

    -> startCUIdec; // i CUI decoders si devono attivare solo dopo
                    // che e' partito il presente processo

    begin : ok
        @(codeRecognized or seqRecognized) 
          disable error;
    end
    
    
    begin : error
        #0; 
        #0; //wait until CUI decoders execute recognition process (2 delta time maximum)
        if (busy)   
            $display("[%0t ns] **WARNING** Device is busy. Command not accepted.", $time);
        else if (deep_power_down)
            $display("[%0t ns] **WARNING** Deep power down mode. Command not accepted.", $time);
        else if (!ReadAccessOn || !WriteAccessOn)   
            $display("[%0t ns] **WARNING** Power up is ongoing. Command not accepted.", $time);    
        else if (!busy)  
            $display("[%0t ns] **ERROR** Command Not Recognized.", $time);
        disable ok;
    end    

join








//--------------------------
// Power Up & Voltage check
//--------------------------



//--- Reset internal logic (latching disabled when Vcc<Vcc_wi)

assign Vcc_L1 = (Vcc>=Vcc_wi) ?  1 : 0 ;

always @Vcc_L1 
  if (reset_by_powerOn && Vcc_L1)
    reset_by_powerOn = 0;
  else if (!reset_by_powerOn && !Vcc_L1) 
    reset_by_powerOn = 1;
    


//--- Read access 

assign Vcc_L2 = (Vcc>=Vcc_min) ?  1 : 0 ;

always @Vcc_L2 if(Vcc_L2 && ReadAccessOn==0) fork : CP_powUp_ReadAccess
    
    begin : p1
      #read_access_power_up_delay;
      $display("[%0t ns] ==INFO== Power up: read access enabled.", $time);
      ReadAccessOn=1;
      deep_power_down=0;
      disable p2;
    end 

    begin : p2
      @Vcc_L2 if(!Vcc_L2)
        disable p1;
    end

join    



//--- Write access

reg WriteAccessCondition = 0;

always @Vcc_L1 if (WriteAccessCondition==0 && Vcc_L1) fork : CP_powUp_WriteAccess
    
    begin : p1
      #write_access_power_up_delay;
      $display("[%0t ns] ==INFO== Power up: write access enabled (device fully accessible).", $time);
      WriteAccessCondition=1;
      disable p2;
    end

    begin : p2
      @Vcc_L1 if(!Vcc_L1)
        disable p1;
    end

join    

assign WriteAccessOn = ReadAccessOn && WriteAccessCondition;



//--- Voltage drop (power down)

always @Vcc_L1 if (!Vcc_L1 && (ReadAccessOn || WriteAccessCondition)) begin : CP_powerDown
    $display("[%0t ns] ==INFO== Voltage below the threshold value: device not accessible.", $time);
    ReadAccessOn=0;
    WriteAccessCondition=0;
end    




//--- Voltage fault (used during program and erase operations)

event voltageFault; //used in Program and erase dynamic check (see also "CP_voltageCheck" process)

assign VccOk = (Vcc>=Vcc_min && Vcc<=Vcc_max) ?  1 : 0 ;

always @VccOk if (!VccOk) ->voltageFault; //check is active when device is not reset
                                          //(this is a dynamic check used during program and erase operations)
        






//---------------------------------
// Vpp (auxiliary voltage) checks
//---------------------------------


`ifdef Vpp_pin

    // VppOk true if Vpp is in the range allowing enhanced program/erase
    assign VppOk = ( (Vpp>=Vpp_min && Vpp<=Vpp_max) && Vpp!=='dX && Vpp!=='dZ ) ?  
                   1  :  0;

    always @(VppOk) if (VppOk)
        $display("[%0t ns] ==INFO== Enhanced Program Supply Voltage is OK (%0d mV).", $time, Vpp);


    assign VppError =  ( !( Vpp===0 || (Vpp>=Vcc_min && Vpp<=Vcc_max) || (Vpp>=Vpp_min && Vpp<=Vpp_max) ) || Vpp==='dX || Vpp==='dZ ) ?  
                       1  :  0;

    always @(VppError or ReadAccessOn)  if(ReadAccessOn && VppError) 
      $display("[%0t ns] **WARNING** Vpp should be in VPPH range, or connected to ground, or connected in Vcc range!", $time);

`endif


`ifdef Vpp_W_pin

    // VppOk true if Vpp is in the range allowing enhanced program/erase
    assign VppOk = ( (Vpp_W>=Vpp_min && Vpp_W<=Vpp_max) && Vpp_W!=='dX && Vpp_W!=='dZ ) ?  
                   1  :  0;

    always @(VppOk) if (VppOk)
        $display("[%0t ns] ==INFO== Enhanced Program Supply Voltage is OK (%0d mV).", $time, Vpp_W);


    assign VppError =  ( !( Vpp_W===0 || (Vpp_W>=Vcc_min && Vpp_W<=Vcc_max) || (Vpp_W>=Vpp_min && Vpp_W<=Vpp_max) ) || Vpp_W==='dX || Vpp_W==='dZ ) ?  
                       1  :  0;

    always @(VppError or ReadAccessOn)  if(ReadAccessOn && VppError) 
      $display("[%0t ns] **WARNING** Vpp should be in VPPH range, or connected to ground, or connected in Vcc range!", $time);

`endif





//-----------------
// Read execution
//-----------------


reg [addrDim-1:0] readAddr;
reg bitOut='hZ;

event sendToBus;


// values assumed by `D and `Q, when they are not forced
assign `D = 1'bZ;
assign `Q = 1'bZ;


// `Q : release of values assigned with "force statement"
always @(posedge S) #tSHQZ release `Q;


// effect on `Q by HOLD signal
`ifdef HOLD_pin
    
    reg temp;
    
    always @(intHOLD) if(intHOLD===0) begin : CP_HOLD_out_effect 
        
        begin : out_effect
            temp = `Q;
            #tHLQZ;
            disable guardian;
            release `Q;
            @(posedge intHOLD) #tHHQX force `Q=temp;
        end  

        begin : guardian 
            @(posedge intHOLD)
            disable out_effect;
        end
        
    end   

`endif    




// read with `Q out bit

always @(negedge(C)) if(logicOn) begin : CP_read

    if(read.enable==1 || read.enable_fast==1) begin    
        
        if(ck_count==0) begin
            readAddr = mem.memAddr;
            mem.readData(dataOut); //read data and increments address
            f.out_info(readAddr, dataOut);
        end

        bitOut = dataOut[dataDim-1-ck_count];
        -> sendToBus;

    end else if (stat.enable_SR_read==1) begin
        
        if(ck_count==0) begin
            dataOut = stat.SR;
            f.out_info(readAddr, dataOut);
        end    
        
        bitOut = dataOut[dataDim-1-ck_count];
        -> sendToBus;

    `ifdef LockReg
      
      end else if (lock.enable_lockReg_read==1) begin

          if(ck_count==0) begin 
              readAddr = f.sec(addr);
              f.out_info(readAddr, dataOut);
          end
          // dataOut is set in LockManager module
        
          bitOut = dataOut[dataDim-1-ck_count];
          -> sendToBus;
    
    `endif      

    `ifdef OTP 
    
      end else if (read.enable_OTP==1) begin 

          if(ck_count==0) begin
              readAddr = 'h0;
              readAddr = OTP.addr;
              OTP.readData(dataOut); //read data and increments address
              f.out_info(readAddr, dataOut);
          end

          bitOut = dataOut[dataDim-1-ck_count];
          -> sendToBus;

    `endif    
    
    end else if (read.enable_ID==1) begin 

        if(ck_count==0) begin
        
            readAddr = 'h0;
            readAddr = read.ID_index;
            
            if (read.ID_index==0)      dataOut=Manufacturer_ID;
            else if (read.ID_index==1) dataOut=MemoryType_ID;
            else if (read.ID_index==2) dataOut=MemoryCapacity_ID;
            
            if (read.ID_index<=1) read.ID_index=read.ID_index+1;
            else read.ID_index=0;

            f.out_info(readAddr, dataOut);
        
        end

        bitOut = dataOut[dataDim-1-ck_count];
        -> sendToBus;

    end
   
end





always @sendToBus fork : CP_sendToBus

    #tCLQX force `Q = 1'bX;
    
    #tCLQV  
        force `Q = bitOut;

join







//-----------------------
//  Reset Signal
//-----------------------


event resetEvent; //Activated only in devices with RESET pin.

reg resetDuringDecoding=0; //These two boolean variables are used in TimingCheck 
reg resetDuringBusy=0;     //entity to check tRHSL timing constraint

`ifdef RESET_pin 

    always @RESET if (!RESET) begin : CP_reset

        ->resetEvent;
        
        if(S===0 && !busy) 
            resetDuringDecoding=1; 
        else if (busy)
            resetDuringBusy=1; 
        
        release `Q;

        ck_count = 0;
        latchingMode = "N";
        cmd='h0;
        addrLatch='h0;
        addr='h0;
        data='h0;
        dataOut='h0;

        iCmd = cmdDim - 1;
        iAddr = addrDimLatch - 1;
        iData = dataDim - 1;

        // commands waiting to be executed are disabled internally
        
        // read enabler are resetted internally, in the read processes
        
        // CUIdecoders are internally disabled by reset signal
        
        #0 $display("[%0t ns] ==INFO== Reset Signal has been driven low : internal logic will be reset.", $time);

    end

`endif    






//-----------------------
//  Deep power down 
//-----------------------


`ifdef PowDown


    always @seqRecognized if (cmdRecName=="Deep Power Down") fork : CP_deepPowerDown

        begin : exe
          @(posedge S);
          disable reset;
          busy=1;
          $display("  [%0t ns] Device is entering in deep power down mode...",$time);
          #deep_power_down_delay;
          $display("  [%0t ns] ...power down mode activated.",$time);
          busy=0;
          deep_power_down=1;
        end

        begin : reset
          @resetEvent;
          disable exe;
        end

    join


    always @seqRecognized if (cmdRecName=="Release Deep Power Down") fork : CP_releaseDeepPowerDown

        begin : exe
          @(posedge S);
          disable reset;
          busy=1;
          $display("  [%0t ns] Release from deep power down is ongoing...",$time);
          #release_power_down_delay;
          $display("  [%0t ns] ...release from power down mode completed.",$time);
          busy=0;
          deep_power_down=0;
        end 

        begin : reset
          @resetEvent;
          disable exe;
        end

    join


`endif









endmodule















/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           CUI DECODER                                 --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/




module CUIdecoder (cmdAllowed);


    `include "include/DevParam.h" 

    input cmdAllowed;

    parameter [30*8:1] cmdName = "Write Enable";
    parameter [cmdDim-1:0] cmdCode = 'h06;
    parameter withAddr = 1'b0; // 0 -> command with address  /  1 -> without address 



    always @M25Pxxx.startCUIdec if (cmdAllowed && cmdCode==M25Pxxx.cmd) begin

        if(!withAddr) begin
            
            M25Pxxx.cmdRecName = cmdName;
            $display("[%0t ns] COMMAND RECOGNIZED: %0s.", $time, cmdName);
            -> M25Pxxx.seqRecognized; 
        
        end else if (withAddr) begin
            
            M25Pxxx.latchingMode = "A";
            $display("[%0t ns] COMMAND RECOGNIZED: %0s. Address expected ...", $time, cmdName);
            -> M25Pxxx.codeRecognized;
            
            fork : proc1 

                @(M25Pxxx.addrLatched) begin
                    if (cmdName!="Read OTP" && cmdName!="Program OTP")
                        $display("  [%0t ns] Address latched: %h (byte %0d of page %0d, sector %0d)", $time, 
                                 M25Pxxx.addr, f.col(M25Pxxx.addr), f.pag(M25Pxxx.addr), f.sec(M25Pxxx.addr));
                    else
                        $display("  [%0t ns] Address latched: column %0d", $time, M25Pxxx.addr);
                    M25Pxxx.cmdRecName = cmdName;
                    -> M25Pxxx.seqRecognized;
                    disable proc1;
                end

                @(posedge M25Pxxx.S) begin
                    $display("  - [%0t ns] S high: command aborted", $time);
                    disable proc1;
                end

                @(M25Pxxx.resetEvent or M25Pxxx.voltageFault) begin
                    disable proc1;
                end
            
            join


        end    


    end


endmodule    













/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           MEMORY MODULE                               --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/




module Memory;

    

    `include "include/DevParam.h"



    //-----------------------------
    // data structures definition
    //-----------------------------

    reg [dataDim-1:0] memory [0:memDim-1];
    reg [dataDim-1:0] page [0:pageDim];




    //------------------------------
    // Memory management variables
    //------------------------------

    reg [addrDim-1:0] memAddr;
    reg [addrDim-1:0] pageStartAddr;
    reg [colAddrDim-1:0] pageIndex = 'h0;
    reg [colAddrDim-1:0] zeroIndex = 'h0;

    integer i;




    //-----------
    //  Init
    //-----------

    initial begin 

        for (i=0; i<=memDim-1; i=i+1) 
            memory[i] = data_NP;
        
        if ( M25Pxxx.memory_file!="" && M25Pxxx.memory_file!=" ") begin
            $readmemh(M25Pxxx.memory_file, memory);
            $display("[%0t ns] ==INFO== Load memory content from file: \"%0s\".", $time, M25Pxxx.memory_file);
        end    
    
    end





    //-----------------------------------------
    //  Task used in program & read operations  
    //-----------------------------------------
    

    
    // set start address & page index
    // (for program and read operations)
    
    task setAddr;

    input [addrDim-1:0] addr;

    begin

        memAddr = addr;
        pageStartAddr = {addr[addrDim-1:pageAddr_inf], zeroIndex};
        pageIndex = addr[colAddrDim-1:0];
    
    end
    
    endtask



    
    // reset page with FF data

    task resetPage;

    for (i=0; i<=pageDim-1; i=i+1) 
        page[i] = data_NP;

    endtask    


    

    // in program operations data latched 
    // are written in page buffer

    task writeDataToPage;

    input [dataDim-1:0] data;

    reg [addrDim-1:0] destAddr;

    begin

        page[pageIndex] = data;
        pageIndex = pageIndex + 1; 

    end

    endtask



    // page buffer is written to the memory

    task programPageToMemory; //logic and between old_data and new_data

    for (i=0; i<=pageDim-1; i=i+1)
        memory[pageStartAddr+i] = memory[pageStartAddr+i] & page[i];
        // before page program the page should be reset
    endtask





    // in read operations data are readed directly from the memory

    task readData;

    output [dataDim-1:0] data;

    begin

        data = memory[memAddr];
        if (memAddr < memDim-1)
            memAddr = memAddr + 1;
        else begin
            memAddr=0;
            $display("  [%0t ns] **WARNING** Highest address reached. Next read will be at the beginning of the memory!", $time);
        end    

    end

    endtask




    //---------------------------------------
    //  Tasks used for Page Write operation
    //---------------------------------------


    // page is written into the memory (old_data are over_written)
    
    task writePageToMemory; 

    for (i=0; i<=pageDim-1; i=i+1)
        memory[pageStartAddr+i] = page[i];
        // before page program the page should be reset
    endtask


    // pageMemory is loaded into the pageBuffer
    
    task loadPageBuffer; 

    for (i=0; i<=pageDim-1; i=i+1)
        page[i] = memory[pageStartAddr+i];
        // before page program the page should be reset
    endtask





    //-----------------------------
    //  Tasks for erase operations
    //-----------------------------

    task eraseSector;
    input [addrDim-1:0] A;
    reg [sectorAddrDim-1:0] sect;
    reg [sectorAddr_inf-1:0] zeros;
    reg [addrDim-1:0] mAddr;
    begin
    
        sect = f.sec(A);
        zeros = 'h0;
        mAddr = {sect, zeros};
        for(i=mAddr; i<=(mAddr+sectorSize-1); i=i+1)
            memory[i] = data_NP;
    
    end
    endtask



    `ifdef SubSect 
    
     task eraseSubsector;
     input [addrDim-1:0] A;
     reg [subsecAddrDim-1:0] subsect;
     reg [subsecAddr_inf-1:0] zeros;
     reg [addrDim-1:0] mAddr;
     begin
    
         subsect = f.sub(A);
         zeros = 'h0;
         mAddr = {subsect, zeros};
         for(i=mAddr; i<=(mAddr+subsecSize-1); i=i+1)
             memory[i] = data_NP;
    
     end
     endtask

    `endif



    task eraseBulk;

        for (i=0; i<=memDim-1; i=i+1) 
            memory[i] = data_NP;
    
    endtask



    task erasePage;
    input [addrDim-1:0] A;
    reg [pageAddrDim-1:0] page;
    reg [pageAddr_inf-1:0] zeros;
    reg [addrDim-1:0] mAddr;
    begin
    
        page = f.pag(A);
        zeros = 'h0;
        mAddr = {page, zeros}; 
        for(i=mAddr; i<=(mAddr+pageDim-1); i=i+1)
            memory[i] = data_NP;
    
    end
    endtask






    

endmodule













/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           UTILITY FUNCTIONS                           --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/




module UtilFunctions;

    `include "include/DevParam.h"

    integer i;

    
    //----------------------------------
    // Utility functions for addresses 
    //----------------------------------


    function [sectorAddrDim-1:0] sec;
    input [addrDim-1:0] A;
        sec = A[sectorAddr_sup:sectorAddr_inf];
    endfunction   

    `ifdef SubSect
      function [subsecAddrDim-1:0] sub;
      input [addrDim-1:0] A;
          sub = A[subsecAddr_sup:subsecAddr_inf];
      endfunction
    `endif

    function [pageAddrDim-1:0] pag;
    input [addrDim-1:0] A;
        pag = A[pageAddr_sup:pageAddr_inf];
    endfunction

    function [pageAddrDim-1:0] col;
    input [addrDim-1:0] A;
        col = A[colAddr_sup:0];
    endfunction
    
    
    
    
    
    //----------------------------------
    // Console messages 
    //----------------------------------

    task clock_error;

        $display("  [%0t ns] **WARNING** Number of clock pulse isn't multiple of eight: operation aborted!", $time);

    endtask



    task WEL_error;

        $display("  [%0t ns] **WARNING** WEL bit not set: operation aborted!", $time);

    endtask



    task out_info;
    
        input [addrDim-1:0] A;
        input [dataDim-1:0] D;

        if (read.enable || read.enable_fast)
        $display("  [%0t ns] Data are going to be output: %h. [Read Memory. Address %h (byte %0d of page %0d, sector %0d)] ",
                  $time, D, A, col(A), pag(A), sec(A)); 
        
        `ifdef DUAL
          else if (read.enable_dual)
          $display("  [%0t ns] Data are going to be output: %h. [Read Memory. Address %h (byte %0d of page %0d, sector %0d)] ",
                    $time, D, A, col(A), pag(A), sec(A));
        `endif          
                  
        
        else if (stat.enable_SR_read)          
        $display("  [%0t ns] Data are going to be output: %b. [Read Status Register]",
                  $time, D);

        `ifdef LockReg
          else if (lock.enable_lockReg_read)
          $display("  [%0t ns] Data are going to be output: %h. [Read Lock Register of sector %0d]",
                    $time, D, A);
        `endif            

        else if (read.enable_ID)
            $display("  [%0t ns] Data are going to be output: %h. [Read ID, byte %0d]", $time, D, A);
        
        `ifdef OTP
          else if (read.enable_OTP) begin
              if (A!=OTP_dim-1)
                  $display("  [%0t ns] Data are going to be output: %h. [Read OTP memory, column %0d]", $time, D, A);
              else  
                  $display("  [%0t ns] Data are going to be output: %b. [Read OTP memory, column %0d (control byte)]", $time, D, A);
          end
        `endif  

    endtask





    //----------------------------------------------------
    // Special tasks used for testing and debug the model
    //----------------------------------------------------
    

    //
    // erase the whole memory, and resets pageBuffer and cacheBuffer
    //
    
    task fullErase;
    begin
    
        for (i=0; i<=memDim-1; i=i+1) 
            mem.memory[i] = data_NP; 
        
        $display("[%0t ns] ==INFO== The whole memory has been erased.", $time);

    end
    endtask




    //
    // unlock all sectors of the memory
    //
    
    task unlockAll;
    begin

        for (i=0; i<=nSector-1; i=i+1) begin
            `ifdef LockReg
              lock.LockReg_WL[i] = 0;
              lock.LockReg_LD[i] = 0;
            `endif
            lock.lock_by_SR[i] = 0;
        end

        $display("[%0t ns] ==INFO== The whole memory has been unlocked.", $time);

    end
    endtask




    //
    // load memory file
    //

    task load_memory_file;

    input [40*8:1] memory_file;

    begin
    
        for (i=0; i<=memDim-1; i=i+1) 
            mem.memory[i] = data_NP;
        
        $readmemh(memory_file, mem.memory);
        $display("[%0t ns] ==INFO== Load memory content from file: \"%0s\".", $time, M25Pxxx.memory_file);
    
    end
    endtask





endmodule












/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           PROGRAM MODULE                              --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/



module Program;

    

    `include "include/DevParam.h"

    

    
    event errorCheck, error, noError;
    
    reg [30*8:1] operation; //get the value of the command currently decoded by CUI decoders
    time delay;                 
                                 




    //----------------------------
    //  Page Program & Page Write
    //----------------------------


    reg writePage_en=0;
    reg [addrDim-1:0] destAddr;



    always @M25Pxxx.seqRecognized 
    if(M25Pxxx.cmdRecName==="Page Program" || M25Pxxx.cmdRecName==="Dual Program" || M25Pxxx.cmdRecName==="Page Write") 
    fork : program_ops

        begin
        
            operation = M25Pxxx.cmdRecName;
            
            if(operation!="Page Write")
                mem.resetPage;
            
            destAddr = M25Pxxx.addr;
            mem.setAddr(destAddr);
            
            if(operation=="Page Write")
                mem.loadPageBuffer;
            
            if(operation=="Page Program" || operation=="Page Write")
                M25Pxxx.latchingMode="D";
            else if(operation=="Dual Program") begin
                M25Pxxx.latchingMode="F";
                release M25Pxxx.`Q;
            end    
            
            writePage_en = 1;
        
        end


        begin : exe
            
           @(posedge M25Pxxx.S);
            
            disable reset;
            writePage_en=0;
            M25Pxxx.latchingMode="N";
            M25Pxxx.busy=1;
            
            $display("  [%0t ns] Command execution begins: %0s.", $time, operation);
            
            if (operation!="Page Write")
                delay=program_delay;
            `ifdef M25PE16
            else if (operation=="Page Write") 
                delay=page_write_delay; `endif
            
            -> errorCheck;

            @(noError) begin
                mem.writePageToMemory;
                $display("  [%0t ns] Command execution completed: %0s.", $time, operation);
            end
                
        end 


        begin : reset
        
          @M25Pxxx.resetEvent;
            writePage_en=0;
            operation = "None";
            disable exe;    
        
        end

    join





    always @M25Pxxx.dataLatched if(writePage_en) begin

        mem.writeDataToPage(M25Pxxx.data);
    
    end








    //------------------------
    //  Write Status register
    //------------------------


    reg [dataDim-1:0] SR_data;


    always @(M25Pxxx.seqRecognized) if (M25Pxxx.cmdRecName=="Write SR") begin : write_SR_ops

        M25Pxxx.latchingMode="D";
        
        @(posedge M25Pxxx.S) begin
            operation=M25Pxxx.cmdRecName;
            SR_data=M25Pxxx.data;
            M25Pxxx.latchingMode="N";
            M25Pxxx.busy=1;
            $display("  [%0t ns] Command execution begins: Write SR.",$time);
            delay=write_SR_delay;
            -> errorCheck;

            @(noError) begin
                
                `ifdef M25PX32
                  `LOTP=SR_data[7];
                `else //M25PE16, M25P128
                  `SRWD=SR_data[7]; `endif  
                  
                `ifdef M25PX32
                  `TB=SR_data[5]; `endif //(TB is not used in M25PE16) 
                
                `BP2=SR_data[4]; 
                `BP1=SR_data[3]; 
                `BP0=SR_data[2]; 
                
                `ifdef M25PX32
                  $display("  [%0t ns] Command execution completed: Write SR. SR=%h, (LOTP,TB,BP2,BP1,BP0)=%b",
                           $time, stat.SR, {`LOTP,`TB,`BP2,`BP1,`BP0} );
                `else //M25PE16, M25P128
                  $display("  [%0t ns] Command execution completed: Write SR. SR=%h, (SRWD,BP2,BP1,BP0)=%b",
                           $time, stat.SR, {`SRWD,`BP2,`BP1,`BP0} );
                `endif           
            
            end
                
        end
    
    end





    //--------------
    // Erase
    //--------------

    always @M25Pxxx.seqRecognized 
    
    if (M25Pxxx.cmdRecName==="Sector Erase" || M25Pxxx.cmdRecName==="Subsector Erase" ||
        M25Pxxx.cmdRecName==="Bulk Erase" || M25Pxxx.cmdRecName==="Page Erase") fork : erase_ops
    
        
        begin : exe
        
           @(posedge M25Pxxx.S);

            disable reset;
            
            operation = M25Pxxx.cmdRecName;
            destAddr = M25Pxxx.addr;
            M25Pxxx.latchingMode="N";
            M25Pxxx.busy = 1;
            $display("  [%0t ns] Command execution begins: %0s.", $time, operation);
            
            if (operation=="Sector Erase")          delay=erase_delay;
            else if (operation=="Bulk Erase")       delay=erase_bulk_delay;
            `ifdef M25PE16
              else if (operation=="Page Erase")       delay=erase_page_delay; `endif
            `ifdef SubSect
              else if (operation=="Subsector Erase")  delay=erase_ss_delay; `endif  
            
            -> errorCheck;

            @(noError) begin
                if (operation=="Sector Erase")          mem.eraseSector(destAddr);
                else if (operation=="Bulk Erase")       mem.eraseBulk;
                else if (operation=="Page Erase")       mem.erasePage(destAddr);
                `ifdef SubSect
                  else if (operation=="Subsector Erase")  mem.eraseSubsector(destAddr); `endif
                $display("  [%0t ns] Command execution completed: %0s.", $time, operation);
            end

        end


        begin : reset
        
          @M25Pxxx.resetEvent;
            operation = "None";
            disable exe;    
        
        end

            
    join




    //---------------------------
    //  Program OTP (ifdef OTP)
    //---------------------------

    `ifdef OTP
    
        reg write_OTP_buffer_en=0;
        `define OTP_lockBit M25Pxxx.OTP.mem[OTP_dim-1][0]



        always @M25Pxxx.seqRecognized if(M25Pxxx.cmdRecName=="Program OTP") 
        fork : OTP_prog_ops

            begin
                OTP.resetBuffer;
                OTP.setAddr(M25Pxxx.addr);
                M25Pxxx.latchingMode="D";
                write_OTP_buffer_en = 1;
            end

            begin : exe
               @(posedge M25Pxxx.S);
                disable reset;
                operation=M25Pxxx.cmdRecName;
                write_OTP_buffer_en=0;
                M25Pxxx.latchingMode="N";
                M25Pxxx.busy=1;
                $display("  [%0t ns] Command execution begins: OTP Program.",$time);
                delay=program_delay;
                -> errorCheck;

                @(noError) begin
                    OTP.writeBufferToMemory;
                    $display("  [%0t ns] Command execution completed: OTP Program.",$time);
                end
            end  

            begin : reset
               @M25Pxxx.resetEvent;
                write_OTP_buffer_en=0;
                operation = "None";
                disable exe;    
            end
        
        join



        always @M25Pxxx.dataLatched if(write_OTP_buffer_en) begin

            OTP.writeDataToBuffer(M25Pxxx.data);
        
        end


    `endif    







    //------------------------
    //  Error check
    //------------------------
    // This process also models  
    // the operation delays
    

    always @(errorCheck) fork : errorCheck_ops
    
    
        begin : static_check

            if(M25Pxxx.ck_count!=0) begin 
                
                M25Pxxx.f.clock_error;
                -> error; 
            
            end else if(`WEL==0) begin
               
                M25Pxxx.f.WEL_error;
                -> error;
            
            end else if ( (operation=="Page Program" || operation=="Dual Program" || operation=="Page Write" || 
                           operation=="Sector Erase" || operation=="Subsector Erase" || operation=="Page Erase") 
                                                        &&
                          (lock.isProtected_by_SR(destAddr)!==0 || lock.isProtected_by_lockReg(destAddr)!==0) ) begin
           
                -> error;

                if (lock.isProtected_by_SR(destAddr)!==0 && lock.isProtected_by_lockReg(destAddr)!==0)
                $display("  [%0t ns] **WARNING** Sector locked by Status Register and by Lock Register: operation aborted.", $time);
            
                else if (lock.isProtected_by_SR(destAddr)!==0)
                $display("  [%0t ns] **WARNING** Sector locked by Status Register: operation aborted.", $time);
            
                else if (lock.isProtected_by_lockReg(destAddr)!==0) 
                $display("  [%0t ns] **WARNING** Sector locked by Lock Register: operation aborted.", $time);
            
            end else if (operation=="Bulk Erase" && lock.isAnySectorProtected(0)) begin
                
                $display("  [%0t ns] **WARNING** Some sectors are locked: bulk erase aborted.", $time);
                -> error;
            
            end    
            
            
            `ifdef M25PX32
              else if(operation=="Write SR" && `LOTP==1) begin
                  $display("  [%0t ns] **WARNING** Lock OTP bit set to 1: write SR isn't allowed!", $time);
                  -> error;
              end 
            `elsif M25PE16 
              else if(operation=="Write SR" && `SRWD==1 && M25Pxxx.W===0) begin
                  $display("  [%0t ns] **WARNING** SRWD bit set to 1, and W=0: write SR isn't allowed!", $time);
                  -> error;
              end
            `elsif M25P128 
              else if(operation=="Write SR" && `SRWD==1 && M25Pxxx.W_int===0) begin
                  $display("  [%0t ns] **WARNING** SRWD bit set to 1, and W=0: write SR isn't allowed!", $time);
                  -> error;
              end
            `endif
            
            
            `ifdef OTP
              else if (operation=="Program OTP" && `OTP_lockBit==0) begin 
                  $display("  [%0t ns] **WARNING** OTP is read only, because lock bit has been programmed to 0: operation aborted.", $time);
                  -> error;    
              end
            `endif
            
            
        end


        fork : dynamicCheck

            @(M25Pxxx.voltageFault) begin
                $display("  [%0t ns] **WARNING** Operation Fault because of Vcc Out of Range!", $time);
                -> error;
            end
            
            `ifdef RESET_pin
              if (operation!="Write SR") @(M25Pxxx.resetEvent) begin
                $display("  [%0t ns] **WARNING** Operation Fault because of Device Reset!", $time);
                -> error;
              end
            `endif  

            #delay begin
                M25Pxxx.busy=0;
                -> stat.WEL_reset;
                -> noError;
                disable dynamicCheck;
                disable errorCheck_ops;
            end
            
        join

        
    join




    always @(error) begin

        M25Pxxx.busy = 0;
        -> stat.WEL_reset;
        disable errorCheck_ops;
        if (operation=="Page Program" || operation=="Dual Program" || operation=="Page Write") disable program_ops;
        else if (operation=="Sector Erase" || operation=="Subsector Erase" || operation=="Bulk Erase") disable erase_ops;
        else if (operation=="Write SR") disable write_SR_ops;
        `ifdef OTP
          else if (operation=="Program OTP") disable OTP_prog_ops;
        `endif  

    end






endmodule












/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           STATUS REGISTER MODULE                      --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/



module StatusRegister;


    `include "include/DevParam.h"



    // status register
    reg [7:0] SR;
    




    //--------------
    // Init
    //--------------


    initial begin
        
        //see alias in DevParam.h
        
        SR[2] = 0; // BP0 - block protect bit 0 
        SR[3] = 0; // BP1 - block protect bit 1
        SR[4] = 0; // BP2 - block protect bit 2
        SR[5] = 0;  // M25PX32: TB (block protect top/bottom)  --  M25PE16, M25P128: not used 
        SR[6] = 0;   // not used
        SR[7] = 0; // M25PX32: LOTP - M25PE16, M25P128: SRWD

    end


    always @(M25Pxxx.ReadAccessOn) if(M25Pxxx.ReadAccessOn) begin
        
        SR[0] = 0; // WIP - write in progress
        SR[1] = 0; // WEL - write enable latch

    end





    //----------
    // WIP bit
    //----------
    
    always @(M25Pxxx.busy)
        `WIP = M25Pxxx.busy;



    //----------
    // WEL bit 
    //----------
    
    always @(M25Pxxx.seqRecognized) if (M25Pxxx.cmdRecName=="Write Enable") fork : WREN 
        
        begin : exe
          @(posedge M25Pxxx.S); 
          disable reset;
          `WEL = 1;
          $display("  [%0t ns] Command execution: WEL bit set.", $time);
        end

        begin : reset
          @M25Pxxx.resetEvent;
          disable exe;
        end
    
    join


    always @(M25Pxxx.seqRecognized) if (M25Pxxx.cmdRecName=="Write Disable") fork : WRDI 
        
        begin : exe
          @(posedge M25Pxxx.S);
          disable reset;
          `WEL = 0;
          $display("  [%0t ns] Command execution: WEL bit reset.", $time);
        end
        
        begin : reset
          @M25Pxxx.resetEvent;
          disable exe;
        end
        
    join


    event WEL_reset;
    always @(WEL_reset)
        `WEL = 0;


    

    //------------------------
    // write status register
    //------------------------

    // see "Program" module



    //----------------------
    // read status register
    //----------------------
    // NB : "Read SR" operation is also modelled in M25Pxxx.module

    reg enable_SR_read;
    
    always @(M25Pxxx.seqRecognized) if (M25Pxxx.cmdRecName=="Read SR") fork 
        
        enable_SR_read=1;

        @(posedge(M25Pxxx.S) or M25Pxxx.resetEvent or M25Pxxx.voltageFault)
            enable_SR_read=0;
        
    join    

    


    



endmodule   














/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           READ MODULE                                 --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/



module Read;


    `include "include/DevParam.h"
    
   
   
    reg enable, enable_fast = 0;




    //--------------
    //  Read
    //--------------
    // NB : "Read" operation is also modelled in M25Pxxx.module
    
    always @(M25Pxxx.seqRecognized) if (M25Pxxx.cmdRecName=="Read") fork 
        
        begin
            enable = 1;
            mem.setAddr(M25Pxxx.addr);
        end
        
        @(posedge(M25Pxxx.S) or M25Pxxx.resetEvent or M25Pxxx.voltageFault) 
            enable=0;
        
    join




    //--------------
    //  Read Fast
    //--------------

    always @(M25Pxxx.seqRecognized) if (M25Pxxx.cmdRecName=="Read Fast") fork

        begin
            mem.setAddr(M25Pxxx.addr);
            $display("  [%0t ns] Dummy byte expected ...",$time);
            M25Pxxx.latchingMode="Y"; //Y=dummy
            @M25Pxxx.dummyLatched;
            enable_fast = 1;
            M25Pxxx.latchingMode="N";
        end

        @(posedge(M25Pxxx.S) or M25Pxxx.resetEvent or M25Pxxx.voltageFault)
            enable_fast=0;
    
    join







    //-----------------
    //  Read ID
    //-----------------

    reg enable_ID;
    reg [1:0] ID_index;

    always @(M25Pxxx.seqRecognized) if (M25Pxxx.cmdRecName=="Read ID") fork 
        
        begin
            enable_ID = 1;
            ID_index=0;
        end
        
        @(posedge(M25Pxxx.S) or M25Pxxx.resetEvent or M25Pxxx.voltageFault)
            enable_ID=0;
        
    join




    //-------------------------
    //  Dual Read (ifdef DUAL) 
    //-------------------------

    reg enable_dual=0;
    
    `ifdef DUAL    
    
      always @(M25Pxxx.seqRecognized) if (M25Pxxx.cmdRecName=="Dual Read") fork

          begin
              mem.setAddr(M25Pxxx.addr);
              $display("  [%0t ns] Dummy byte expected ...",$time);
              M25Pxxx.latchingMode="Y"; //Y=dummy
              @M25Pxxx.dummyLatched;
              enable_dual = 1;
              M25Pxxx.latchingMode="N";
          end

          @(posedge(M25Pxxx.S) or M25Pxxx.resetEvent or M25Pxxx.voltageFault)
              enable_dual=0;
    
      join

    `endif





    //-------------------------
    //  Read OTP (ifdef OTP)
    //-------------------------
    // NB : "Read OTP" operation is also modelled in M25Pxxx.module

    reg enable_OTP=0;
    
    `ifdef OTP
    
      always @(M25Pxxx.seqRecognized) if (M25Pxxx.cmdRecName=="Read OTP") fork 
        
          begin
              enable_OTP = 1;
              OTP.setAddr(M25Pxxx.addr);
          end
        
          @(posedge(M25Pxxx.S) or M25Pxxx.resetEvent or M25Pxxx.voltageFault)
              enable_OTP=0;
        
      join
    
    `endif


    


    


endmodule












/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           LOCK MANAGER MODULE                         --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


module LockManager;


`include "include/DevParam.h"




//---------------------------------------------------
// Data structures for protection status modelling
//---------------------------------------------------


// array of sectors lock status (status determinated by Block Protect Status Register bits)
reg [nSector-1:0] lock_by_SR; //(1=locked)

`ifdef LockReg
  // Lock Registers (there is a pair of Lock Registers for each sector)
  reg LockReg_WL [nSector-1:0];   // Lock Register Write Lock bit (1=lock enabled)
  reg LockReg_LD [nSector-1:0];   // Lock Register Lock Down bit (1=lock down enabled)
`endif

integer i;






//----------------------------
// Initial protection status
//----------------------------

initial
    for (i=0; i<=nSector-1; i=i+1)
        lock_by_SR[i] = 0;
        //LockReg_WL & LockReg_LD are initialized by powerUp  
    


//------------------------
// Reset signal effects
//------------------------

`ifdef LockReg
  
  always @M25Pxxx.resetEvent 
      for (i=0; i<=nSector-1; i=i+1) begin
          `ifdef M25PX32
            LockReg_WL[i]=1;
          `elsif M25PE16
            LockReg_WL[i]=0;
          `endif 
          LockReg_LD[i] = 0;
      end    

`endif




//----------------------------------
// Power up : reset lock registers
//----------------------------------

`ifdef LockReg

  always @(M25Pxxx.ReadAccessOn) if(M25Pxxx.ReadAccessOn) 
      for (i=0; i<=nSector-1; i=i+1) begin
          `ifdef M25PX32
            LockReg_WL[i]=1;
          `elsif M25PE16
            LockReg_WL[i]=0;
          `endif  
          LockReg_LD[i] = 0;
      end

`endif    






//------------------------------------------------
// Protection managed by BP status register bits
//------------------------------------------------

integer nLockedSector;
integer temp;


`ifdef M25PX32
  
  always @(`TB or `BP2 or `BP1 or `BP0) begin

      for (i=0; i<=nSector-1; i=i+1) //reset lock status of all sectors
          lock_by_SR[i] = 0;
    
      temp = {`BP2, `BP1, `BP0};
      nLockedSector = 2**(temp-1); 

      if (nLockedSector>0 && `TB==0) // upper sectors protected
          for ( i=nSector-1 ; i>=nSector-nLockedSector ; i=i-1 ) begin
              lock_by_SR[i] = 1;
              $display("  [%0t ns] ==INFO== Sector %0d locked", $time, i);
          end
    
      else if (nLockedSector>0 && `TB==1) // lower sectors protected 
          for ( i = 0 ; i <= nLockedSector-1 ; i = i+1 ) begin
              lock_by_SR[i] = 1;
              $display("  [%0t ns] ==INFO== Sector %0d locked", $time, i);
          end

  end

`else // M25PE16, M25P128

  always @(`BP2 or `BP1 or `BP0) begin

      for (i=0; i<=nSector-1; i=i+1) //reset lock status of all sectors
          lock_by_SR[i] = 0;
    
      temp = {`BP2, `BP1, `BP0};
      nLockedSector = 2**(temp-1); 

      if (nLockedSector>0) // upper sectors protected
          for ( i=nSector-1 ; i>=nSector-nLockedSector && i>=0 ; i=i-1 ) begin
              lock_by_SR[i] = 1;
              $display("  [%0t ns] ==INFO== Sector %0d locked", $time, i);
          end
    
  end

`endif




//--------------------------------------
// Protection managed by Lock Register
//--------------------------------------

reg enable_lockReg_read=0;


`ifdef LockReg


    reg [sectorAddrDim-1:0] sect;
    reg [dataDim-1:0] sectLockReg;



    always @(M25Pxxx.seqRecognized) if (M25Pxxx.cmdRecName=="Write Lock Reg") fork : WRLR

        begin : exe1
            sect = f.sec(M25Pxxx.addr);
            M25Pxxx.latchingMode = "D";
            @(M25Pxxx.dataLatched) sectLockReg = M25Pxxx.data;
        end

        begin : exe2
            @(posedge M25Pxxx.S);
            disable exe1;
            disable reset;
            -> stat.WEL_reset;
            if(`WEL==0)
                M25Pxxx.f.WEL_error;
            else if (LockReg_LD[sect]==1)
                $display("  [%0t ns] **WARNING** Lock Down bit is set. Write lock register is not allowed!", $time);
            else begin
                LockReg_LD[sect]=sectLockReg[1];
                LockReg_WL[sect]=sectLockReg[0];
                $display("  [%0t ns] Command execution: lock register of sector %0d set to (%b,%b)", 
                          $time, sect, LockReg_LD[sect], LockReg_WL[sect] );
            end    
        end

        begin : reset
            @M25Pxxx.resetEvent;
            disable exe1;
            disable exe2;
        end
        
    join




    // Read lock register

    
    always @(M25Pxxx.seqRecognized) if (M25Pxxx.cmdRecName=="Read Lock Reg") fork

        begin
          sect = f.sec(M25Pxxx.addr); 
          M25Pxxx.dataOut = {4'b0, LockReg_LD[sect], LockReg_WL[sect]};
          enable_lockReg_read=1;
        end   
        
        @(posedge(M25Pxxx.S) or M25Pxxx.resetEvent or M25Pxxx.voltageFault)
            enable_lockReg_read=0;
        
    join



`endif




//-------------------------------------------
// Function to test sector protection status
//-------------------------------------------

function isProtected_by_SR;
input [addrDim-1:0] byteAddr;
reg [sectorAddrDim-1:0] sectAddr;
begin

    sectAddr = f.sec(byteAddr);
    isProtected_by_SR = lock_by_SR[sectAddr]; 

end
endfunction





function isProtected_by_lockReg;
input [addrDim-1:0] byteAddr;
reg [sectorAddrDim-1:0] sectAddr;
begin

    `ifdef LockReg
      sectAddr = f.sec(byteAddr);
      isProtected_by_lockReg = LockReg_WL[sectAddr];
    `else
      isProtected_by_lockReg = 0; //if LockReg is not defined the function return always zero
    `endif

end
endfunction





function isAnySectorProtected;
input required;
begin

    i=0;   
    isAnySectorProtected=0;
    while(isAnySectorProtected==0 && i<=nSector-1) begin 
        `ifdef LockReg
          isAnySectorProtected=lock_by_SR[i] || LockReg_WL[i];
        `else
          isAnySectorProtected=lock_by_SR[i]; `endif
        i=i+1;
    end    

end
endfunction







endmodule













/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           TIMING CHECK                                --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/



module TimingCheck (S, C, D, Q, W, H); //P128


    `include "include/DevParam.h"

    input S, C, D, Q;
    `ifdef HOLD_pin
      input H; `endif
    `ifdef W_pin
      input W; `endif
    `ifdef Vpp_W_pin
      input W; `endif  
    `ifdef RESET_pin
      input R; `endif

    `ifdef W_pin
      `define W_feature
    `elsif Vpp_W_pin    
      `define W_feature 
     `endif
    
    time delta; //used for interval measuring
    
   

    //--------------------------
    //  Task for timing check
    //--------------------------

    task check;
        
        input [8*8:1] name;  //constraint check
        input time interval;
        input time constr;
        
        begin
        
            if (interval<constr)
                $display("[%0t ns] --TIMING ERROR-- %0s constraint violation. Measured time: %0t ns - Constraint: %0t ns",
                          $time, name, interval, constr);
            
        
        end
    
    endtask



    //----------------------------
    // Istants to be measured
    //----------------------------

    parameter initialTime = -1000;

    time C_high=initialTime, C_low=initialTime;
    time S_low=initialTime, S_high=initialTime;
    time D_valid=initialTime;
     
    `ifdef HOLD_pin
        time H_low=initialTime, H_high=initialTime; `endif

    `ifdef RESET_pin
        time R_low=initialTime, R_high=initialTime; `endif

    `ifdef W_feature
        time W_low=initialTime, W_high=initialTime; `endif


    //------------------------
    //  C signal checks
    //------------------------


    always 
    @C if(C===0) //posedge(C)
    @C if(C===1)
    begin
        
        delta = $time - C_low; 
        check("tCL", delta, tCL);

        delta = $time - S_low; 
        check("tSLCH", delta, tSLCH);

        delta = $time - D_valid; 
        check("tDVCH", delta, tDVCH);

        delta = $time - S_high; 
        check("tSHCH", delta, tSHCH);

        // clock frequency checks
        delta = $time - C_high;
        if (read.enable && delta<TR)
           $display("[%0t ns] --TIMING ERROR-- Violation of Max clock frequency (%0d MHz) during READ operation. T_ck_measured=%0d ns, T_clock_min=%0d ns.",
                      $time, fR, delta, TR);
        else if ( (read.enable_fast || read.enable_ID || read.enable_dual || read.enable_OTP || 
                   stat.enable_SR_read || lock.enable_lockReg_read )   
                          && 
                        delta<TC  )
                        //else if ( !read.enable && delta<TC ) da verificare
           $display("[%0t ns] --TIMING ERROR-- Violation of Max clock frequency (%0d MHz). T_ck_measured=%0d ns, T_clock_min=%0d ns.",
                      $time, fC, delta, TC);
        
        `ifdef HOLD_pin
        
            delta = $time - H_low; 
            check("tHLCH", delta, tHLCH);

            delta = $time - H_high; 
            check("tHHCH", delta, tHHCH);
        
        `endif
        
        C_high = $time;
        
    end



    always 
    @C if(C===1) //negedge(C)
    @C if(C===0)
    begin
        
        delta = $time - C_high; 
        check("tCH", delta, tCH);
        
        C_low = $time;
        
    end




    //------------------------
    //  S signal checks
    //------------------------


    always 
    @S if(S===1) //negedge(S)
    @S if(S===0)
    begin
        
        delta = $time - C_high; 
        check("tCHSL", delta, tCHSL);

        delta = $time - S_high; 
        check("tSHSL", delta, tSHSL);

        `ifdef W_feature
          delta = $time - W_high; 
          check("tWHSL", delta, tWHSL);
        `endif


        `ifdef RESET_pin
            //check during decoding
            if (M25Pxxx.resetDuringDecoding) begin 
                delta = $time - R_high; 
                check("tRHSL", delta, tRHSL_1);
                M25Pxxx.resetDuringDecoding = 0;
            end 
            //check during program-erase operation
            else if ( M25Pxxx.resetDuringBusy && (prog.operation=="Page Program" || prog.operation=="Page Write" ||  
                      prog.operation=="Sector Erase" || prog.operation=="Bulk Erase"  || prog.operation=="Page Erase") )   
            begin 
                delta = $time - R_high; 
                check("tRHSL", delta, tRHSL_2);
                M25Pxxx.resetDuringBusy = 0;
            end
            //check during subsector erase
            else if ( M25Pxxx.resetDuringBusy && prog.operation=="Subsector Erase" ) begin 
                delta = $time - R_high; 
                check("tRHSL", delta, tRHSL_3);
                M25Pxxx.resetDuringBusy = 0;
            end
            //check during WRSR
            else if ( M25Pxxx.resetDuringBusy && prog.operation=="Write SR" ) begin 
                delta = $time - R_high; 
                check("tRHSL", delta, tRHSL_4);
                M25Pxxx.resetDuringBusy = 0;
            end
        `endif


        S_low = $time;


    end




    always 
    @S if(S===0) //posedge(S)
    @S if(S===1)
    begin
        
        delta = $time - C_high; 
        check("tCHSH", delta, tCHSH);
        
        S_high = $time;
        
    end



    //----------------------------
    //  D signal (data in) checks
    //----------------------------

    always @D 
    begin

        delta = $time - C_high;
        check("tCHDX", delta, tCHDX);

        if (isValid(D)) D_valid = $time;

    end



    //------------------------
    //  Hold signal checks
    //------------------------


    `ifdef HOLD_pin    
    

        always 
        @H if(H===1) //negedge(H)
        @H if(H===0)
        begin
            
            delta = $time - C_high; 
            check("tCHHL", delta, tCHHL);

            H_low = $time;
            
        end



        always 
        @H if(H===0) //posedge(H)
        @H if(H===1)
        begin
            
            delta = $time - C_high; 
            check("tCHHH", delta, tCHHH);
            
            H_high = $time;
            
        end


    `endif




    //------------------------
    //  W signal checks
    //------------------------


    `ifdef W_feature

        always 
        @W if(W===1) //negedge(W)
        @W if(W===0)
        begin
            
            delta = $time - S_high; 
            check("tSHWL", delta, tSHWL);

            W_low = $time;
            
        end

        always 
        @W if(W===0) //posedge(W)
        @W if(W===1)
            W_high = $time;
            
    `endif




    //------------------------
    //  RESET signal checks
    //------------------------


    `ifdef RESET_pin

        always 
        @R if(R===1) //negedge(R)
        @R if(R===0)
            R_low = $time;
            
        always 
        @R if(R===0) //posedge(R)
        @R if(R===1)
        begin
            
            delta = $time - S_high; 
            check("tSHRH", delta, tSHRH);
            
            delta = $time - R_low; 
            check("tRLRH", delta, tRLRH);
            
            R_high = $time;
            
        end

    `endif




    //----------------
    // Others tasks
    //----------------

    function isValid;
    input bit;
      if (bit!==0 && bit!==1) isValid=0;
      else isValid=1;
    endfunction




    

endmodule   












