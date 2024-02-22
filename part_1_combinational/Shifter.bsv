import Vector::*;

typedef Bit#(16) Word;

function Vector#(16, Word) naiveShfl(Vector#(16, Word) in, Bit#(4) shftAmnt);
    Vector#(16, Word) resultVector = in; 
    for (Integer i = 0; i < 16; i = i + 1) begin
        Bit#(4) idx = fromInteger(i);
        resultVector[i] = in[shftAmnt+idx];
    end
    return resultVector;
endfunction


function Vector#(16, Word) barrelLeft(Vector#(16, Word) in, Bit#(4) shftAmnt);
    // Implementation of a left barrel shifter
    Vector#(16, Word) resultVector = in;
    for (Integer j = 0; j < 4; j = j + 1) begin
        Vector#(16, Word) prevVector = resultVector;
        if (unpack(shftAmnt[j])) begin
            for (Integer i = 0; i < 16; i = i + 1) begin
                Bit#(4) idx = fromInteger(i);
                Bit#(4) jdx = fromInteger(j);
                resultVector[i] = prevVector[(1<<jdx)+idx];
            end
        end
    end
    return resultVector;
endfunction

