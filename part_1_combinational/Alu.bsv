typedef enum {
	Add,
	ShiftL,
	And,
	Not
} InstructionType deriving (Eq,FShow, Bits);

function Bit#(32) alu (InstructionType ins, Bit#(32) v1, Bit#(32) v2);
	case (ins) matches
		Add: return v1 + v2;
		ShiftL: return v1 << v2;
		And: return v1 & v2;
		Not: return ~v1;
	endcase
endfunction

