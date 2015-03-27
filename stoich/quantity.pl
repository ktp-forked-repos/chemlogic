:- set_prolog_flag(double_quotes,chars).
:- consult(sigfigs_number).
:- use_module(library(dcg/basics)).

quantity(qty([[Val,Unit|Tail]]),Num-Input,InputR) :- number_chars(Num,Chars),
							value(Val,Chars,[]),
							Input = [" "|InputR0],
							unit_sym(Unit,InputR0,InputR1),
							unit_tail(Unit,Tail,InputR1,InputR).

quantity(qty([[Val,Unit]|Tail])) --> value(Val), " ", unit_sym(Unit), !, unit_tail(Unit,Tail), !.

value(value(Val,SF)) --> 
	({var(Val)} -> 
		(
			value_calc(value(Val,SF))
		);
		(
			value_display(value(Val,SF))
		)
	).

value_calc(value(Val,SF)) --> sigfigs:number(SFDigits,[],Digits,[]), {length(SFDigits,SF), number_chars(Val,Digits)}.
value_display(value(Val,SF),H,T) :- format(chars(H,T),'~w',Val). % When performing output, it is much faster to just use SWI-Prolog's built-in conversion.

query(query([Unit|Tail],Property)) --> unit_sym(Unit), !, property(Property), unit_tail(Unit,Tail), !.

property(property(actual)) --> " reacted".
property(property(actual)) --> " produced".

property(property(excess)) --> " excess".

property(property(actual)) --> "".

unit_sym(unit(g)) --> "g".
unit_sym(unit('M')) --> "mol/L".
unit_sym(unit(mol)) --> "mol".
unit_sym(unit('L')) --> "L".
unit_sym(unit('M')) --> "M".

unit_tail(unit('L'),[[Val,unit('M')]]) --> " of ",  value(Val), " " ,unit_sym(unit('M')).
unit_tail(unit('L'),[[Val,unit('M')]]) --> " (",  value(Val), " " ,unit_sym(unit('M')), ")".
unit_tail(unit('M'),[[Val,unit('L')]]) --> " (",  value(Val), " " ,unit_sym(unit('L')), ")".

unit_tail(unit('M'),[[Val,unit(mol)]]) --> " (",  value(Val), " " ,unit_sym(unit(mol)), ")".
unit_tail(unit(mol),[[Val,unit('M')]]) --> " (",  value(Val), " " ,unit_sym(unit('M')), ")".

unit_tail(unit('L'),[[Val,unit(mol)]]) --> " (",  value(Val), " " ,unit_sym(unit(mol)), ")".
unit_tail(unit(mol),[[Val,unit('L')]]) --> " (",  value(Val), " " ,unit_sym(unit('L')), ")".

unit_tail(_,[]) --> [].
