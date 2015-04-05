% quantity.pl: Parses user-entered text quantity and query expressions.
% This file is from Chemlogic, a logic programming computer chemistry system
% <http://icebergsystems.ca/chemlogic>
% (C) Copyright 2012-2015 Nicholas Paun



:- module(quantity,[quantity//1,quantity_prefix//1,query//1,queries_convert/2]).
:- use_module(sigfigs_number).
:- set_prolog_flag(double_quotes,chars).


quantity_prefix(Qty) --> quantity(Qty), " ".
quantity_prefix(nil) --> "".

quantity([[Val,Unit]|Tail]) --> value(Val), " ", unit_sym(Unit), !, unit_tail(Unit,Tail), !.

value([Val,SF]) --> 
	({var(Val)} -> 
		(
			value_calc([Val,SF])
		);
		(
			value_display([Val,SF])
		)
	).

value_calc([Val,SF]) --> number(SFDigits,[],Digits,[]), {length(SFDigits,SF), number_chars(Val,Digits)}.
value_display([Val,_],H,T) :- format(chars(H,T),'~w',Val). % When performing output, it is much faster to just use SWI-Prolog's built-in conversion.

queries_convert([],[]).
queries_convert([Var-Input|InputS],[Output|OutputS]) :-
	atom_chars(Input,InputChars),
	query(Output,Var-InputChars,[]),
	queries_convert(InputS,OutputS).

query(nil,nil,[]).
query(Struct,Var-Input,Rest) :- query(Struct,Var,Input,Rest).
query([[[[Var,_],Unit]|Tail],Property],Var) --> unit_sym(Unit), !, property(Property), unit_tail(Unit,Tail), !.

propery(excess) --> " excess".
property(Type,Input,Rest) :- (var(Input) -> Input = [""|Rest]; property_label(Type,Input,Rest)).

property_label(actual) --> " reacted".
property_label(actual) --> " produced".

property_label(excess) --> " excess".


property_label(actual) --> "".

unit_sym(g) --> "g".
unit_sym('M') --> "mol/L".
unit_sym(mol) --> "mol".
unit_sym('L') --> "L".
unit_sym('M') --> "M".

unit_tail('L',[[Val,'M']]) --> " of ",  value(Val), " " ,unit_sym('M').
unit_tail('L',[[Val,'M']]) --> " (",  value(Val), " " ,unit_sym('M'), ")".
unit_tail('M',[[Val,'L']]) --> " (",  value(Val), " " ,unit_sym('L'), ")".

unit_tail('M',[[Val,mol]]) --> " (",  value(Val), " " ,unit_sym(mol), ")".
unit_tail(mol,[[Val,'M']]) --> " (",  value(Val), " " ,unit_sym('M'), ")".

unit_tail('L',[[Val,mol]]) --> " (",  value(Val), " " ,unit_sym(mol), ")".
unit_tail(mol,[[Val,'L']]) --> " (",  value(Val), " " ,unit_sym('L'), ")".

unit_tail(_,[]) --> [].
