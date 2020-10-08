/* -*- C++ -*- */
/*
      This file is part of vcd_parser
      Copyright (C) 2020 Julien Thevenon ( julien_thevenon at yahoo.fr )

      This program is free software: you can redistribute it and/or modify
      it under the terms of the GNU General Public License as published by
      the Free Software Foundation, either version 3 of the License, or
      (at your option) any later version.

      This program is distributed in the hope that it will be useful,
      but WITHOUT ANY WARRANTY; without even the implied warranty of
      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
      GNU General Public License for more details.

      You should have received a copy of the GNU General Public License
      along with this program.  If not, see <http://www.gnu.org/licenses/>
*/

%{

#include <stdio.h> // Needed to have the flex generated code compile
#include <sstream>

#include "vcd_driver.h"
#include "vcd_parser.hpp"
#include "quicky_exception.h"

typedef vcd_parser_engine::vcd_parser::token      token;
typedef vcd_parser_engine::vcd_parser::token_type token_type;

// Redefine yyterminate to return a token_type instead of int
#define yyterminate() return vcd_parser_engine::vcd_parser::make_END_OF_STREAM(*yylloc)

#define BEGIN_STATE(p_state) if(yy_flex_debug)                      \
    {                                                               \
    flex_prefix_change_start_condition(YYSTATE, p_state, #p_state); \
    }                                                               \
    BEGIN(p_state)

#define DEBUG_KEYWORD() do                                      \
{                                                               \
    if(yy_flex_debug)                                           \
    {                                                           \
        std::string l_keyword(yytext, yyleng);                  \
        flex_prefix_debug_keyword(l_keyword, YYSTATE, *yylloc); \
    }                                                           \
} while(0)

#define DEBUG_TOKEN(p_name) do                             \
{                                                          \
    if(yy_flex_debug)                                      \
    {                                                      \
        flex_prefix_debug_token(p_name, YYSTATE, *yylloc); \
    }                                                      \
} while(0)

#define DEBUG_TOKEN_CONTENT(p_name) do                                        \
{                                                                             \
    if(yy_flex_debug)                                                         \
    {                                                                         \
        std::string l_content(yytext, yyleng);                                \
        flex_prefix_debug_token_content(p_name, l_content, YYSTATE, *yylloc); \
    }                                                                         \
} while(0)

#define DEBUG_BLOCK_CONTENT() do                                      \
{                                                                     \
    if(yy_flex_debug)                                                 \
    {                                                                 \
        std::string l_content(yytext, yyleng);                        \
        flex_prefix_debug_block_content(l_content, YYSTATE, *yylloc); \
    }                                                                 \
} while(0)

// No need for unistd, as we use C++ streams
//#define YY_NO_UNISTD_H

void flex_prefix_change_start_condition( int p_old_start_condition
                                       , int p_new_start_condition
                                       , const std::string & p_name
                                       );

std::string flex_prefix_start_condition_to_string(int p_start_condition);

void flex_prefix_debug_keyword( const std::string & p_name
                  , int p_start_condition
                  , const YYLTYPE & p_location
                  );

void flex_prefix_debug_token( const std::string & p_name
                            , int p_start_condition
                            , const YYLTYPE & p_location
                            );

void flex_prefix_debug_block_content( const std::string & p_content
                                    , int p_start_condition
                                    , const YYLTYPE & p_location
                                    );

void flex_prefix_debug_token_content( const std::string & p_name
                                    , const std::string & p_content
                                    , int p_start_condition
                                    , const YYLTYPE & p_location
                                    );

%}

%option bison-bridge bison-locations reentrant warn
%option noyywrap nounput batch debug noinput nodefault
%option prefix="flex_prefix"

/* Definitions */
Digit [0-9]
Blank [\t]|[\040]
LowerCaseLetter [a-z]
UpperCaseLetter [A-Z]
Letter {LowerCaseLetter}|{UpperCaseLetter}
Identifier ({Letter}|{Digit})({Letter}|{Digit}|\/|_|\[|\])*
DecimalNumber ({Digit})+
Exponent (E|e)(\+|-)?{DecimalNumber}
RealNumber -?({Digit})+(\.{Digit}+)?({Exponent})?
PrintableCharacters [\41-\176]
GenericIdentifier {PrintableCharacters}+
SingleValue 0|1|x|X|z|Z|u|U|l|L|-
VectorValue {SingleValue}+

/* Location tracking */
%{
    #define YY_USER_ACTION yylloc->columns(yyleng);
%}

%x VCD_COMMENT
%x VCD_DATE
%x VCD_VERSION
%x VCD_TIMESCALE
%x VCD_SCOPE
%x VCD_VAR
%x VCD_VAR_NAME
%x VCD_VAR_REFERENCE
%x VCD_SIMULATION
%x VCD_SIMULATION_COMMENT
%x VCD_VALUE_CHANGE
%x VCD_VECTOR_VALUE_CHANGE
%x VCD_REAL_VALUE_CHANGE
%x VCD_TIMESTAMP
%%

%{
// beginning of yylex()

// reset location
yylloc->step();
%}

<INITIAL,VCD_SIMULATION>\$comment {
    DEBUG_KEYWORD();
    yylloc->step();
    switch(YYSTATE)
    {
        case INITIAL:
            BEGIN_STATE(VCD_COMMENT);
            break;
        case VCD_SIMULATION:
            BEGIN_STATE(VCD_SIMULATION_COMMENT);
            break;
        default:
            throw quicky_exception::quicky_logic_exception("Unknown start condition " + std::to_string(YYSTATE) + " for $comment", __LINE__, __FILE__);
    }
}

\$timescale {
    DEBUG_KEYWORD();
    yylloc->step();
    BEGIN_STATE(VCD_TIMESCALE);
}

\$date {
    DEBUG_KEYWORD();
    yylloc->step();
    BEGIN_STATE(VCD_DATE);
};

\$version {
    DEBUG_KEYWORD();
    yylloc->step();
    BEGIN_STATE(VCD_VERSION);
};

\$var {
    DEBUG_KEYWORD();
    yylloc->step();
    BEGIN_STATE(VCD_VAR);
};

<VCD_DATE,VCD_VERSION,VCD_COMMENT,VCD_SIMULATION_COMMENT>[^\$\n]* {
    std::string l_string(yytext, yyleng);
    DEBUG_BLOCK_CONTENT();
    yylloc->step();
}

<*>{Blank}+ {
    DEBUG_TOKEN(std::to_string(yyleng) + " spaces");
    yylloc->step();
}

<VCD_TIMESCALE>10{0,2} {
    std::string l_string(yytext, yyleng);
    DEBUG_TOKEN_CONTENT("Timescale number");
    yylloc->step();
}

<VCD_TIMESCALE>(m|u|n|p|f)?s {
    std::string l_string(yytext, yyleng);
    DEBUG_TOKEN_CONTENT("Timescale unit");
    yylloc->step();
}

<*>\$end {
    DEBUG_KEYWORD();
    switch(YYSTATE)
    {
        case VCD_SIMULATION:
            // Do Nothing
            break;
        case VCD_SIMULATION_COMMENT:
            BEGIN_STATE(VCD_SIMULATION);
            break;
        default:
            BEGIN_STATE(INITIAL);
    }
    yylloc->step();
}

\$enddefinitions {
    DEBUG_KEYWORD();
    BEGIN_STATE(VCD_SIMULATION);
    yylloc->step();
}

<VCD_SIMULATION>\$dumpvars {
    DEBUG_KEYWORD();
    yylloc->step();
}

<VCD_SIMULATION>\$dumpall {
    DEBUG_KEYWORD();
    yylloc->step();
}

<VCD_SIMULATION>\$dumpon {
    DEBUG_KEYWORD();
    yylloc->step();
}

<VCD_SIMULATION>\$dumpoff {
    DEBUG_KEYWORD();
    yylloc->step();
}

\$scope {
    DEBUG_KEYWORD();
    BEGIN_STATE(VCD_SCOPE);
    yylloc->step();
}

\$upscope {
    DEBUG_KEYWORD();
    yylloc->step();
}

<VCD_SCOPE>begin {
        DEBUG_KEYWORD();
        yylloc->step();
};

<VCD_SCOPE>fork {
        DEBUG_KEYWORD();
        yylloc->step();
};

<VCD_SCOPE>function {
        DEBUG_KEYWORD();
        yylloc->step();
};

<VCD_SCOPE>module {
        DEBUG_KEYWORD();
        yylloc->step();
};

<VCD_SCOPE>task {
        DEBUG_KEYWORD();
        yylloc->step();
};

<VCD_VAR>event {
        DEBUG_KEYWORD();
        yylloc->step();
};

<VCD_VAR>integer {
        DEBUG_KEYWORD();
        yylloc->step();
};

<VCD_VAR>parameter {
        DEBUG_KEYWORD();
        yylloc->step();
};

<VCD_VAR>real {
        DEBUG_KEYWORD();
        yylloc->step();
};

<VCD_VAR>reg {
        DEBUG_KEYWORD();
        yylloc->step();
};

<VCD_VAR>supply0 {
        DEBUG_KEYWORD();
        yylloc->step();
};

<VCD_VAR>supply1 {
        DEBUG_KEYWORD();
        yylloc->step();
};

<VCD_VAR>time {
        DEBUG_KEYWORD();
        yylloc->step();
};

<VCD_VAR>tri {
        DEBUG_KEYWORD();
        yylloc->step();
};

<VCD_VAR>triand {
        DEBUG_KEYWORD();
        yylloc->step();
};

<VCD_VAR>trior {
        DEBUG_KEYWORD();
        yylloc->step();
};

<VCD_VAR>trireg {
        DEBUG_KEYWORD();
        yylloc->step();
};

<VCD_VAR>tri0 {
        DEBUG_KEYWORD();
        yylloc->step();
};

<VCD_VAR>tri1 {
        DEBUG_KEYWORD();
        yylloc->step();
};

<VCD_VAR>wand {
        DEBUG_KEYWORD();
        yylloc->step();
};

<VCD_VAR>wire {
        DEBUG_KEYWORD();
        yylloc->step();
};

<VCD_VAR>wor {
        DEBUG_KEYWORD();
        yylloc->step();
};

<VCD_SIMULATION>{SingleValue} {
    std::string l_string(yytext, yyleng);
    DEBUG_TOKEN_CONTENT("Single value");
    BEGIN_STATE(VCD_VALUE_CHANGE);
    yylloc->step();
}

<VCD_VAR,VCD_VAR_REFERENCE,VCD_TIMESTAMP>{DecimalNumber} {
    std::string l_string(yytext, yyleng);
    DEBUG_TOKEN_CONTENT("Decimal number");
    yylloc->step();
    if(VCD_TIMESTAMP == YYSTATE)
    {
        BEGIN_STATE(VCD_SIMULATION);
    }
}

<VCD_VECTOR_VALUE_CHANGE>{VectorValue} {
    std::string l_string(yytext, yyleng);
    DEBUG_TOKEN_CONTENT("Vector value");
    BEGIN_STATE(VCD_VALUE_CHANGE);
    yylloc->step();
}

<VCD_REAL_VALUE_CHANGE>{RealNumber}|x|X {
    std::string l_string(yytext, yyleng);
    DEBUG_TOKEN_CONTENT("Real value");
    BEGIN_STATE(VCD_VALUE_CHANGE);
    yylloc->step();
}

<VCD_SIMULATION>b|B {
    DEBUG_TOKEN("Binary vector value change");
    BEGIN_STATE(VCD_VECTOR_VALUE_CHANGE);
    yylloc->step();
}

<VCD_SIMULATION>r|R {
    DEBUG_TOKEN("Real Value change");
    BEGIN_STATE(VCD_REAL_VALUE_CHANGE);
    yylloc->step();
}

<VCD_SIMULATION># {
    DEBUG_TOKEN("Timestamp marker");
    BEGIN_STATE(VCD_TIMESTAMP);
    yylloc->step();
}

<VCD_SIMULATION>\<Out\ of\ memory\> {
    DEBUG_KEYWORD();
    yylloc->step();
}

<*>\r\n {
    DEBUG_TOKEN(R"(End of line \r\n)");
    yylloc->lines();
    yylloc->step();
};

<VCD_VAR_REFERENCE>\[ {
    DEBUG_TOKEN("'['");
    yylloc->step();
}

<VCD_VAR_REFERENCE>\] {
    DEBUG_TOKEN("']'");
    yylloc->step();
}

<VCD_VAR_REFERENCE>\: {
    DEBUG_TOKEN("':'");
    yylloc->step();
}

<VCD_VAR,VCD_VAR_NAME,VCD_VALUE_CHANGE>{GenericIdentifier} {
    std::string l_string(yytext, yyleng);
    DEBUG_TOKEN_CONTENT("Var Identifier code");
    switch(YYSTATE)
    {
        case VCD_VAR:
            BEGIN_STATE(VCD_VAR_NAME);
            break;
        case VCD_VAR_NAME:
            BEGIN_STATE(VCD_VAR_REFERENCE);
            break;
        case VCD_VALUE_CHANGE:
            BEGIN_STATE(VCD_SIMULATION);
            break;
        default:
            BEGIN_STATE(VCD_VAR);
    }
    yylloc->step();
}

<VCD_SCOPE>{Identifier} {
    std::string l_string(yytext, yyleng);
    DEBUG_TOKEN_CONTENT("Identifier");
    yylloc->step();
}

<*>\n {
    DEBUG_TOKEN(R"(End of line \n)");
    yylloc->lines();
    yylloc->step();
};

. {
    DEBUG_TOKEN_CONTENT("UNKNOWN TOKEN");
    driver.error("Unknown token");
    //return token::UNKNOWN;
}

%% /* Implementation of scanner class */

//-----------------------------------------------------------------------------
void flex_prefix_change_start_condition( int p_old_start_condition
                                       , int p_new_start_condition
                                       , const std::string & p_name
                                       )
{
    std::cout << " ==> [" << flex_prefix_start_condition_to_string(p_old_start_condition) << "] -> New start condition " << p_name  << std::endl;
}

//-----------------------------------------------------------------------------
std::string flex_prefix_start_condition_to_string(int p_start_condition)
{
    switch(p_start_condition)
    {
        case INITIAL:
            return "INITIAL";
            break;
        case VCD_COMMENT:
            return "VCD_COMMENT";
            break;
        case VCD_DATE:
            return "VCD_DATE";
            break;
        case VCD_VERSION:
            return "VCD_VERSION";
            break;
        case VCD_TIMESCALE:
            return "VCD_TIMESCALE";
            break;
        case VCD_SCOPE:
            return "VCD_SCOPE";
            break;
        case VCD_VAR:
            return "VCD_VAR";
            break;
        case VCD_VAR_NAME:
            return "VCD_VAR_NAME";
            break;
        case VCD_VAR_REFERENCE:
            return "VCD_VAR_REFERENCE";
            break;
        case VCD_SIMULATION:
            return "VCD_SIMULATION";
            break;
        case VCD_SIMULATION_COMMENT:
            return "VCD_SIMULATION_COMMENT";
            break;
        case VCD_VALUE_CHANGE:
            return "VCD_VALUE_CHANGE";
            break;
        case VCD_VECTOR_VALUE_CHANGE:
            return "VCD_VECTOR_VALUE_CHANGE";
            break;
        case VCD_REAL_VALUE_CHANGE:
            return "VCD_REAL_VALUE_CHANGE";
            break;
        case VCD_TIMESTAMP:
            return "VCD_TIMESTAMP";
            break;
        default:
            quicky_exception::quicky_logic_exception("Unknown start condition value : " + std::to_string(p_start_condition), __LINE__, __FILE__);
    }
    return "";
}

//-----------------------------------------------------------------------------
void flex_prefix_debug_keyword( const std::string & p_name
                              , int p_start_condition
                              , const YYLTYPE & p_location
                              )
{
    std::cout << " --> [" << flex_prefix_start_condition_to_string(p_start_condition) << "] " << p_name << " keyword @" << p_location << std::endl;
}

//-----------------------------------------------------------------------------
void flex_prefix_debug_token( const std::string & p_name
                            , int p_start_condition
                            , const YYLTYPE & p_location
                            )
{
    std::cout << " --> [" << flex_prefix_start_condition_to_string(p_start_condition) << "] " << p_name << " @" << p_location << std::endl;
}

//-----------------------------------------------------------------------------
void flex_prefix_debug_token_content( const std::string & p_name
                                    , const std::string & p_content
                                    , int p_start_condition
                                    , const YYLTYPE & p_location
                                    )
{
    std::cout << " --> [" << flex_prefix_start_condition_to_string(p_start_condition) << "] " << p_name << R"( : ")" << p_content << R"(" @)" << p_location << std::endl;
}

//-----------------------------------------------------------------------------
void flex_prefix_debug_block_content( const std::string & p_content
                                    , int p_start_condition
                                    , const YYLTYPE & p_location
                                    )
{
    std::cout << " --> [" << flex_prefix_start_condition_to_string(p_start_condition) << R"(] block content ")" << p_content << R"(" @)" << p_location << std::endl;
}

//EOF