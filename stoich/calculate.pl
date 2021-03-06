% calculate.pl: Performs stoichiometric calculations, including the stoichiometry of excess quantities.
% This file is from Chemlogic, a logic programming computer chemistry system
% <http://icebergsystems.ca/chemlogic>
% (C) Copyright 2012-2015 Nicholas Paun



:- module(calculate,[stoich/5,stoich_queries/5,stoich_queries/6]).

% Super irritating style check
:- style_check(-atom).



combine_structs([],[],[],[]) :- !.
combine_structs([Qty|QtyS],[Coeff|CoeffS],[Formula|FormulaS],[Struct|StructS]) :-
	(Qty = nil -> Struct = nil; Struct = [Qty,Coeff,Formula]),
	combine_structs(QtyS,CoeffS,FormulaS,StructS).

limitation_exists(InputS) :-
	subtract(InputS,[nil],Values),
	length(Values,Count),
	Count > 1.

no_input(NilS) :-
	subtract(NilS,[nil],[]).

single_input(InputS,Struct) :-
	subtract(InputS,[nil],[Struct]).

mol_ratio([],[],[]).
mol_ratio([nil|StructS],[nil|MolRatioS],[nil|NewStructS]) :-
	mol_ratio(StructS,MolRatioS,NewStructS).
mol_ratio([[QtyIn,CoeffIn,FormulaIn]|StructS],[MolRatio|MolRatioS],[[[[[Mol,SF],mol]],CoeffIn,FormulaIn]|NewStructS]) :-
	convert(input,FormulaIn,QtyIn,[[[Mol,SF],mol]]),
	MolRatio is Mol / CoeffIn,
	mol_ratio(StructS,MolRatioS,NewStructS).

limitant(StructS,NewStructS,LimitantStruct) :-
	mol_ratio(StructS,MolRatioS,NewStructS),
	min_member(MinMolRatio,MolRatioS),
	nth0(Index,MolRatioS,MinMolRatio), !,
	nth0(Index,NewStructS,LimitantStruct).

stoich_limited(_,[],[]) :- !.
stoich_limited(Limitant,[_|InputS],[nil|QueryS]) :-
	stoich_limited(Limitant,InputS,QueryS), !.
stoich_limited(Limitant,[Input|InputS],[[[QtyOut,CalcTypeOut],CoeffOut,FormulaOut]|QueryS]) :-
	Limitant = [[[[MolLim,SFLim],mol]],CoeffLim,_],
	(
		CalcTypeOut = excess ->
			(
				(
					Input = [[[[MolIn,SFIn],mol]],_,_];
					throw(error(logic_error(calculate:excess_missing_input,

						(
							'Property to be determined: ', CalcTypeOut,
							'No quantity provided for this substance: ', FormulaOut
						)
					),_))
				),
				SF is min(SFLim,SFIn),
				MolOut is MolIn - MolLim * CoeffOut / CoeffLim
			);
			(
				MolOut is MolLim * CoeffOut / CoeffLim,
				SF = SFLim
			)
	),
	convert(output,FormulaOut,[[[MolOut,SF],mol]],QtyOut), !,
	stoich_limited(Limitant,InputS,QueryS).

stoich_simple(_,[]) :- !.
stoich_simple(Input,[nil|QueryS]) :-
	stoich_simple(Input,QueryS), !.
stoich_simple(Input,[[[QtyOut,CalcTypeOut],CoeffOut,FormulaOut]|QueryS]) :-
	(CalcTypeOut = excess ->
		throw(error(logic_error(calculate:excess_no_comparison,
				(
					'Excess quantity to be determined: ', FormulaOut
				)
			),_));
		true
	),

	Input = [QtyIn,CoeffIn,FormulaIn],
	convert(input,FormulaIn,QtyIn,[[[MolIn,SF],mol]]), !,
	MolOut is MolIn * CoeffOut / CoeffIn,
	convert(output,FormulaOut,[[[MolOut,SF],mol]],QtyOut), !,
	stoich_simple(Input,QueryS).


stoich_queries_real(InGrammar,Equation,OutGrammar,Balanced,Struct,OutQtyS) :-
	balance_equation(InGrammar,Equation,OutGrammar,Balanced,CoeffS,FormulaS,Struct,stoich,InQtyS),
	combine_structs(InQtyS,CoeffS,FormulaS,InputS),
	combine_structs(OutQtyS,CoeffS,FormulaS,QueryS),
	(	no_input(InputS) ->
			throw(error(logic_error(calculate:no_input,
				(
					'Attempted to calculate the following quantities: ', QueryS
				)
			),_));
			true
	),
	(
		single_input(InputS,Input) ->
			(
				stoich_simple(Input,QueryS)
			);
			(

				limitant(InputS,InputMolS,Limitant),
				stoich_limited(Limitant,InputMolS,QueryS)
			)
	).

stoich_queries(InGrammar,Equation,OutGrammar,Balanced,Struct,OutQtyS):-
	catch(
		stoich_queries_real(InGrammar,Equation,OutGrammar,Balanced,Struct,OutQtyS),
		error(logic_error(Type,Data),_),
		explain_general_rethrow(logic_error,Equation,Type,Data)
	).

stoich_queries(InGrammar,Equation,OutGrammar,Balanced,OutQtyS) :-
	stoich_queries(InGrammar,Equation,OutGrammar,Balanced,_,OutQtyS).

stoich(InGrammar,Equation,OutGrammar,Balanced,OutQtyS) :-
	queries_convert(OutQtyS,OutQtyStructS),
	stoich_queries(InGrammar,Equation,OutGrammar,Balanced,_,OutQtyStructS).

%%%%% GUIDANCE FOR ERRORS %%%%%

guidance_general(excess_missing_input,
	'The amount in excess of this substance cannot be calculated because the quantity present is unknown.
	 Excess amounts are calculated by comparing the provided quantity of a substance with the amount of substance that actually reacted.

	 For example, for the reaction FeCl2 + KNO3 + HCl --> FeCl3 + NO + H2O + KCL, the amount of FeCl2 in excess could only be calculated if the amount of FeCl2 initially present was provided (e.g. 56.8 g).

	 Please ensure that you have entered all of the known quantities in this reaction.

	 ').

guidance_general(excess_no_comparison,
	'You have instructed the program to calculate the amount in excess of a given quantity, but you have provided only one known quantity for this reaction.

	Therefore, no comparison can be made between the actual (given limiting reactants) and theoretical amounts reacted.

	Please ensure that you have entered all of the known quantities in this reaction.

	').

guidance_general(no_input,
	'You have attempted to perform a stoichiometric calculation without providing any known quantities.
	 Therefore, it is impossible to produce any results.

	 Please enter any known quantities for this reaction.

	 ').
explain_general_data([],[]).
