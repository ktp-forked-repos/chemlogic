:- dynamic output//2.


symbol(user,arrow) --> " --> ".
symbol(html,arrow) --> " &rarr; ".
symbol(latex,arrow) --> " \\rightarrow ".

symbol(user,sub_start) --> "".
symbol(user,sub_end) --> "".

symbol(html,sub_start) --> "<sub>".
symbol(html,sub_end) --> "</sub>".

symbol(latex,sub_start) --> "_{".
symbol(latex,sub_end) --> "}".

symbol(user,dot) --> " . ".
symbol(html,dot) --> " &middot; ".
symbol(latex,dot) --> " \\cdot ".

/** set_output_format(+Format) is det.

Causes side-effects. Causes all output from parsers to be in Format, unless overriden elsewhere.
*/
set_output_format(Format) :-
	write('Set '),
	writeln(Format),
	retractall(output(_,_,_,_)),
	dcg_translate_rule((output(output,Symbol) --> symbol(Format,Symbol), !),DefaultRule),
	assertz(DefaultRule),
	dcg_translate_rule((output(Other,Symbol) --> symbol(Other,Symbol),!),OtherRule),
	assertz(OtherRule).

:- initialization set_output_format(user).