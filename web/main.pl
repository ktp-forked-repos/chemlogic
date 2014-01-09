:- set_prolog_flag(double_quotes,chars).
:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_parameters)).
:- use_module(library(http/html_write)).

:- initialization server(8000,[]).

server(Port, Options) :-
        http_server(http_dispatch,
                    [ port(Port)
                    | Options
                    ]).

set_html_format :-
	retractall(output(output,_,_,_)),
	dcg_translate_rule(output(output,X) --> symbol(html,X),Rule),
	assertz(Rule).

:- include('style.pl').

:- ensure_loaded('../io/format-out.pl').
:- initialization set_output_format(html).

:- include('../balance/balancer').

:- include('compounder.pl').
:- include('balancer.pl').


