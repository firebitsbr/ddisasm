.symbol_type name
.symbol_type reg

.number_type address
.number_type op_code

// 'Symbols'
.decl symbol(ea:address,n:number,type:symbol,scope:symbol,name:symbol)
.input symbol


.decl instruction(ea:address,size:number,opcode:symbol,op1:op_code,op2:op_code,op3:op_code)
.input instruction

.decl op_regdirect(code:op_code,reg:reg)
.input op_regdirect

.decl op_immediate(code:op_code,num:number)
.input op_immediate

.decl op_indirect(code:op_code,reg1:reg,reg2:reg,reg3:reg,multiplier:number,offset:number,noidea:number)
.input op_indirect


// 'Invalid adresses'
.decl invalid(n:address)
.input invalid

// possible target
.decl possible_target(ea:address)
.input possible_target





possible_target(Val):-
	op_immediate(_,Val).
	
// 'Next'
.decl next(n:address,m:address)
.input next

next(EA,EA+Size):-
	instruction(EA,Size,_,_,_,_).
	

.decl jump_operation(n:symbol)

jump_operation("JMP").
jump_operation("JNZ").
jump_operation("JN").
jump_operation("JGE").
jump_operation("JNA").	
	
// 'Jumps'
.decl inconditional_jump(n:address)
.input inconditional_jump


inconditional_jump(EA):-
	instruction(EA,_,"JMP",_,_,_).	
	
// direct jumps
.decl direct_jump(n:address,m:address)
.input direct_jump

direct_jump(EA,Dest):-
	instruction(EA,_,Operation,Op1,_,_),
	jump_operation(Operation),
	op_immediate(Op1,Dest).
	
    

		
// 'Calls'
.decl direct_call(n:address,m:address)
.input direct_call

direct_call(EA,Dest):-
	instruction(EA,_,"CALL",Op1,_,_),
	op_immediate(Op1,Dest).


.decl maybe_valid(a:address)
    
maybe_valid(EA):-
	instruction(EA,_,_,_,_,_).
	

// 'Returns'
.decl return(n:address)

return(EA):-
	instruction(EA,_,"Ret",_,_,_).




.decl function_symbol(ea:address,name:symbol)
.output function_symbol

function_symbol(EA,Name):-
	symbol(EA,_,"func",_,Name).

possible_target(EA):-
	function_symbol(EA,_).
		
		
.decl fallthrough(o:address,d:address)

fallthrough(From,To):-
	next(From,To),
	!return(From),
	!inconditional_jump(From).
			
// I am faced with two options, cosider possible targets of things that I know are code
// or consider all possible targets of possibly not code
// If I restrict the targets I might get a circular definition (non-monotonic)
// because I am using !possible_target to compute valid4sure

// propagate from entry points
// following direct jumps and direct calls

.decl valid4sure(n:address,start:address)
.output valid4sure

//for sure might be an overstatement
valid4sure(EA,EA):-
	possible_target(EA),
	maybe_valid(EA).

valid4sure(EA,Start):-
	valid4sure(EA2,Start),
	fallthrough(EA2,EA),
	!possible_target(EA),
	maybe_valid(EA).
	
valid4sure(EA,EA):-
	valid4sure(EA2,_),
	direct_jump(EA2,EA),
	maybe_valid(EA).
	
valid4sure(EA,EA):-
	valid4sure(EA2,_),
	direct_call(EA2,EA),
	maybe_valid(EA).	


// forbid overlaps with valid4sure instructions
// grow the initial invalid set 
// there are many ways of doing this, many possible orders

.decl overlap(ea:address,ea_origin:address)


//this is kind of ugly but for now it seems to achieve much better performance
overlap(EA2+1,EA2):-
	//this should limit the scope even more
	valid4sure(EA2,_),
	next(EA2,End),
	EA2+1 < End.
overlap(EA+1,EA2):-
	overlap(EA,EA2),
	next(EA2,End),
	EA+1 < End.

// the starting point of EA is in the middle of a valid instruction	
invalid(EA):- 
	valid4sure(Ini,_),
	overlap(EA,Ini),
	maybe_valid(EA),
	!valid4sure(EA,_).

// the ending point of EA is in the middle of a valid instruction
invalid(EA):- 
	valid4sure(Ini,_),
	overlap(EA_f,Ini),
	next(EA,EA_f),
	maybe_valid(EA),
	!valid4sure(EA,_).	
	

//transitively invalid

.decl invalid_transitive(n:address)
//.output invalid_transitive(IO=stdout)

invalid_transitive(EA):-invalid(EA).
invalid_transitive(From):-
	invalid_transitive(To),
	(
		fallthrough(From,To)
	;
		direct_jump(From,To)
	;
		direct_call(From,To)
	).
	



.decl maybe_valid2(n:address)
.output maybe_valid2

maybe_valid2(EA):-
	maybe_valid(EA),
	!invalid_transitive(EA).
	
	
.decl block_start(n:address)
.output block_start

block_start(EA):-valid4sure(_,EA).

