
% Inefficiencies to eliminate %
	% Oxyacids require a stupid test to determine the oxyanion
	% Stop the madness when testing multivalent metals
	% Does the issue come from ionic main or from something else?


ionic(Elems,ElemsR,Formula) --> {var(Formula)}, ionic_fwd(Elems,ElemsR,Formula), {!}.
ionic(_,_,Formula) --> {nonvar(Formula)}, ionic_rev(Formula).

ionic_rev([[MSym,MSub],[NMSym,NMSub]|Appended]) -->
	{
	%  TODO: If the metal is monovalent, don't bother conjuring it up! Just use it.
	%  Also, no need to actually check these charges, is there?

	(charge(NMSym,NMCharge), !),
	!,
	NMTotal is abs(NMSub * NMCharge),
	MCharge is NMTotal / MSub
	},
	ionic_calcdata(_,_,[MSym,MCharge,NMSym,NMCharge],Appended).

ionic_fwd(MElems,FinalRest,[[MSym,MSub],[NMSym,NMSub]|Appended]) --> ionic_calcdata(MElems,FinalRest,[MSym,MCharge,NMSym,NMCharge],Appended),
	{
	GCD is gcd(MCharge,NMCharge),
	MSub is abs(NMCharge / GCD),
	NMSub is abs(MCharge / GCD)
	}.

ionic_calcdata(Elems,Rest,Formula,[]) --> acid(Elems,Rest,Formula).
ionic_calcdata(MElems,FinalRest,[MSym,MCharge,NMSym,NMCharge],Hydrate) --> 
	cation(MElems,MRest,MSym,MCharge), 
	" ", 
	anion(MRest,NMRest,NMSym,NMCharge), 
	optional_hydrate(NMRest,FinalRest,Hydrate).

optional_hydrate(["H","O"|ElemR],ElemR,[[[["H",2],["O",1]],Num]]) --> " ", num_sub(Num,Suffix), Suffix, "hydrate".
optional_hydrate(Pass,Pass,[]) --> [].




metal(Sym,Charge) --> metal_multivalent(Sym,Charge).
metal(Sym,Charge) --> metal_monovalent(Sym,Charge).

metal_multivalent(Sym,Charge) --> 
	element(Sym,_),
	{charge(Sym,Charges), is_list(Charges)},
       	(multivalent_charge(Charge); syntax_stop(charge)), 
	({member(Charge,Charges)}; syntax_stop(charge_invalid)).



metal_monovalent(Sym,Charge) --> element(Sym,_), {charge_check(metal,Sym,Charge)}.


cation(Elems,Rest,Formula,Charge) --> group(Elems,Rest,Formula,_),
	{
	charge_check(metal,Formula,Charge)
	}.


cation([Sym|Rest],Rest,Sym,Charge) --> metal(Sym,Charge).

anion(Elems,Rest,Formula,Charge) --> group(Elems,Rest,Formula,_),
	{
	charge_check(nonmetal,Formula,Charge)
	}.

anion([Sym|Rest],Rest,Sym,Charge) --> ionic_non_metal_ide(Sym,_),
	{
	charge(Sym,Charge)
	}.


ionic_non_metal_ide(Sym,Base) --> 
	(element_base(Sym,Base); syntax_stop(element_or_group)), 
	({charge_check(nonmetal,Sym)}; syntax_stop(nonmetal)),
	("ide"; syntax_stop(ide)).

multivalent_charge(Charge) --> "(", num_roman(Charge), ")".

num_roman(8) --> "VIII".
num_roman(8) --> "IIX".

num_roman(7) --> "VII".
num_roman(6) --> "VI".
num_roman(5) --> "V".
num_roman(4) --> "IV".
num_roman(3) --> "III".
num_roman(2) --> "II".
num_roman(1) --> "I".

acid(["H"|Elems],Rest,["H",1,ASym,ACharge]) --> acid_anion(Elems,Rest,ASym,ACharge), " acid".

acid_anion(Elems,Rest,ASym,ACharge) --> oxyanion_acid(Elems,Rest,ASym,ACharge).
acid_anion(Elems,Rest,ASym,ACharge) --> hydro_acid(Elems,Rest,ASym,ACharge).
acid_anion(Elems,Rest,ASym,ACharge) --> polyatomic_oxy_acid(Elems,Rest,ASym,ACharge).
acid_anion(Elems,Rest,ASym,ACharge) --> polyatomic_hydro_acid(Elems,Rest,ASym,ACharge).

hydro_acid([ASym|Rest],Rest,ASym,ACharge) --> "hydro", acid_base(ASym,_), "ic", {charge_check(nonmetal,ASym,ACharge)}.


oxyanion_acid(Elems,Rest,ASym,ACharge) --> group_base(Elems,Rest,ASym,_), {charge(ASym,ACharge)}, acid_suffix(ASym).

polyatomic_oxy_acid(Elems,Rest,ASym,ACharge) --> group_base(Elems,Rest,ASym,Base), "ic", 
	{
		\+ Base = "n/a", 
		member(["O",_],ASym), !, 
		charge_check(nonmetal,ASym,ACharge)
	}.

/*
Also, perhaps the performance might be better if we put in group base, to avoid wasting our time recognizing "hydro".
*/

polyatomic_hydro_acid(Elems,Rest,ASym,ACharge) --> "hydro", group_base(Elems,Rest,ASym,Base), "ic", 
	{
		\+ Base = "n/a", 
		\+ member(["O",_],ASym), !, 
		charge_check(nonmetal,ASym,ACharge)
	}.
