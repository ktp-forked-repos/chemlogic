% solve.pl: Converts a provided matrix to a system of linear equations which is solved using CLP(q).
% This file is from Chemlogic, a logic programming computer chemistry system
% <http://icebergsystems.ca/chemlogic>
% (C) Copyright 2012-2015 Nicholas Paun



:- module(solve,[system/3,solve/2]).
:- use_module(library(clpq)).




% Build a system of linear equations

/** system(+Matrix:list,-VarS:list,-System:list) is det.

Transforms a matrix into a system of linear equations. Rather inefficient, given that a matrix can be solved directly.

@arg	Matrix	A matrix created from the element occurences per molecule.
@arg	Row	A row in that matrix	Carbon = [1 in CH4, 0 in O2, -1 in CO2, -0 H2O], etc.
@arg	VarS	An unstantiated list that will later hold the equation coefficients
@arg	Systems	A system of linear equations

**/

system([],_,[]).

system([Row|RowS],VarS,[Equation|EquationS]) :-
        equation_terms(Row,VarS,LTermS),
        equation_expression(LTermS,LHS),
        !,
        Equation =.. [=,LHS,0],
        system(RowS,VarS,EquationS).

equation_terms([],[],[]).

equation_terms([Coeff|CoeffS],[Var|VarS],[Term|TermS]) :-
	Term =.. [*,Coeff,Var],
	equation_terms(CoeffS,VarS,TermS).


equation_expression([TermS|[]],TermS) :- !.

equation_expression([TermL,TermR|TermS],Expr) :-
        Sum = TermL + TermR,
        equation_expression([Sum|TermS],Expr).


/** system_eval(+Equations:list,-VarS:list) is det.

Adds an Equation to the constraint store.
**/

system_eval([],_).

system_eval([Equation|EquationS],VarS) :-
	{Equation}, % Add Equation to the CLP(Q) constraint store)
	system_eval(EquationS,VarS).


/** solve(+Matrix:list,-Solution:list) is semidet.

Converts a Matrix describing a chemical equation into a system of linear equations and produces the simplest, positive solution.

@error TODO	If there is no possible solution, this function will fail.
**/

solve(Matrix,Solution) :-
	VarS = [FirstVar|_], % We use the first variable when putting the solution in simplest form
	system(Matrix,VarS,System),
	(
		require_positive(VarS); % Requires all variables to be positive
		throw(error(domain_error(solve:positive,System),_))
	),
	(
		system_eval(System,VarS);
		throw(error(domain_error(solve:eval,System),_))
	),
	(
		bb_inf(VarS,FirstVar,_,Solution); % Takes the lowest solution that satisfies all of the constraints.
		throw(error(domain_error(solve:bb_inf,System)))
	),
	!.


/** require_positive(-VarS:list) is det.

Requires that every variable (representing a chemical equation coefficient) by positive in order for a solution to be valid.
**/

require_positive([]).

require_positive([Var|VarS]) :-
	{Var > 0},
	require_positive(VarS).


%%%%% GUIDANCE FOR ERRORS %%%%%

guidance_general(positive,
	'Your chemical equation has no solution with all coefficients positive.

	 Your equation has been converted to the following system of linear equations, which cannot be solved: ').

guidance_general(eval,
 	'Your chemical equation is in the correct format, but is logically invalid.
	 Therefore, the equation cannot be balanced.

	 e.g: CuCl2 + KBr --> CuBr + KCl
	 This equation is in the correct format, but cannot be balanced becuase the copper ion cannot change its charge in this reaction.

	 e.g: C4N2H --> CH + N
	 This equation follows all of the rules, but is clearly nonsensical and cannot be made to balance.

	 The following system of linear equations has no solution: ').

guidance_general(bb_inf,
	'The coefficients for your chemical equation cannot be reduced to lowest terms.
	 This is a very unusual error and may represent a bug in the program.

 	 Your equation has been converted to the following system of linear equations: ').

explain_general_data([],[]).
