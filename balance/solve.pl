:- module(solve,[system/3,solve/2]).
:- use_module(library(clpq)).

% Build a system of linear equations

/** system(+Matrix,-VarS,-System) is det.

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


/** system_eval(+Equations,-VarS) is det.

Adds an Equation to the constraint store.
**/

system_eval([],_).

system_eval([Equation|EquationS],VarS) :-
	{Equation}, % Add Equation to the CLP(Q) constraint store)
	system_eval(EquationS,VarS).


/** solve(+Matrix,-Solution) is semidet.

Converts a Matrix describing a chemical equation into a system of linear equations and produces the simplest, positive solution.

@error TODO	If there is no possible solution, this function will fail.
**/

solve(Matrix,Solution) :-
	VarS = [FirstVar|_], % We use the first variable when putting the solution in simplest form
	system(Matrix,VarS,System),
	(require_positive(VarS); throw(error(domain_error(positive,System),_))), % Requires all variables to be positive
	(system_eval(System,VarS); throw(error(domain_error(eval,System),_))),
	(bb_inf(VarS,FirstVar,_,Solution); throw(error(domain_error(bb_inf,System)))), % Takes the lowest solution that satisfies all of the constraints.
	!.


/** require_positive(-VarS) is det.

Requires that every variable (representing a chemical equation coefficient) by positive in order for a solution to be valid.
**/

require_positive([]).

require_positive([Var|VarS]) :-
	{Var > 0},
	require_positive(VarS).


