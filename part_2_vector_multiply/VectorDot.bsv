import Vector::*;
import BRAM::*;

// Time spent on VectorDot: 2-3h

// Please annotate the bugs you find.

interface VD;
    method Action start(Bit#(8) dim_in, Bit#(2) i);
    method ActionValue#(Bit#(32)) response();
endinterface

(* synthesize *)
module mkVectorDot (VD);
    BRAM_Configure cfg1 = defaultValue;
    cfg1.loadFormat = tagged Hex "v1.hex";
    BRAM1Port#(Bit#(8), Bit#(32)) a <- mkBRAM1Server(cfg1);
    BRAM_Configure cfg2 = defaultValue;
    cfg2.loadFormat = tagged Hex "v2.hex";
    BRAM1Port#(Bit#(8), Bit#(32)) b <- mkBRAM1Server(cfg2);

    Reg#(Bit#(32)) output_res <- mkReg(unpack(0));
    Reg#(Bit#(8)) dim <- mkReg(0);

    Reg#(Bool) ready_start <- mkReg(False);
    // TODO: these registers probably need to be bigger?
    // if we can store dim * i then we need sz(dim) + sz(i)
    Reg#(Bit#(8)) pos_a <- mkReg(unpack(0));
    Reg#(Bit#(8)) pos_b <- mkReg(unpack(0));
    Reg#(Bit#(8)) pos_out <- mkReg(unpack(0));
    Reg#(Bool) done_all <- mkReg(False);
    Reg#(Bool) done_a <- mkReg(False);
    Reg#(Bool) done_b <- mkReg(False);
    Reg#(Bool) req_a_ready <- mkReg(False);
    Reg#(Bool) req_b_ready <- mkReg(False);

    Reg#(Bit#(2)) i <- mkReg(0);


    rule process_a (ready_start && !done_a && !req_a_ready && !done_all);
        a.portA.request.put(BRAMRequest{write: False, // False for read
                            responseOnWrite: False,
                            address: zeroExtend(pos_a),
                            datain: ?});
        // BUG #2: wrong comparison, should be + dim
        if (pos_a < dim*zeroExtend(i)+dim) begin
            pos_a <= pos_a + 1;
        end else begin
            done_a <= True;
        end

        req_a_ready <= True;

    endrule

    rule process_b (ready_start && !done_b && !req_b_ready && !done_all);
        b.portA.request.put(BRAMRequest{write: False, // False for read
                responseOnWrite: False,
                address: zeroExtend(pos_b),
                datain: ?});
        if (pos_b < dim*zeroExtend(i)+dim) begin
            pos_b <= pos_b + 1;
        end else begin 
            done_b <= True;
        end
    
        req_b_ready <= True;
    endrule

    rule mult_inputs (req_a_ready && req_b_ready && !done_all);
        let out_a <- a.portA.response.get();
        let out_b <- b.portA.response.get();

        // BUG #1: doesn't actually compute dot product, only overwrites
        output_res <= output_res + out_a*out_b;     
        pos_out <= pos_out + 1;
        
        if (pos_out == dim-1) begin
            done_all <= True;
        end

        req_a_ready <= False;
        req_b_ready <= False;
    endrule



    method Action start(Bit#(8) dim_in, Bit#(2) i_in) if (!ready_start);
        ready_start <= True;
        dim <= dim_in;
        done_all <= False;
        i <= i_in;
        // BUG #5: i hasn't updated here yet so we need to use i_in
        pos_a <= dim_in*zeroExtend(i_in);
        pos_b <= dim_in*zeroExtend(i_in);
        done_a <= False;
        done_b <= False;
        pos_out <= 0;
        // BUG #4: need to reset output_res
        output_res <= 0;
    endmethod

    method ActionValue#(Bit#(32)) response() if (done_all);
        // BUG #3: ready_start is never reset
        ready_start <= False;
        return output_res;
    endmethod

endmodule


