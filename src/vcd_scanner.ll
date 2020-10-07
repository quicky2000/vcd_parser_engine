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

//#define state_begin(p_state)  begin_state(p_state,#p_state)

// No need for unistd, as we use C++ streams
//#define YY_NO_UNISTD_H

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
Identifier {Letter}({Letter}|Digit)*
DecimalNumber ({Digit})+
Exponent (E|e)(\+|-)?{DecimalNumber}
RealNumber ({Digit})+(\.{Digit}+)?({Exponent})?
PrintableCharacters [\41-\176]
GenericIdentifier {PrintableCharacters}+
SingleValue 0|1|x|X|z|Z
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
%%

%{
// beginning of yylex()

// reset location
yylloc->step();
%}

<INITIAL,VCD_SIMULATION>\$comment {
    if(yy_flex_debug)
    {
        std::cout << " --> $comment token @" << *yylloc << std::endl;
    }
    //yylloc->lines();
    yylloc->step();
    switch(YYSTATE)
    {
        case INITIAL:
            BEGIN(VCD_COMMENT);
            break;
        case VCD_SIMULATION:
            BEGIN(VCD_SIMULATION_COMMENT);
            break;
        default:
            throw quicky_exception::quicky_logic_exception("Unknown start condition " + std::to_string(YYSTATE) + " for $comment", __LINE__, __FILE__);
    }
}

\$timescale {
    if(yy_flex_debug)
    {
        std::cout << " --> $timescale token @" << *yylloc << std::endl;
    }
    //yylloc->lines();
    yylloc->step();
    BEGIN(VCD_TIMESCALE);
}

\$date {
    if(yy_flex_debug)
    {
        std::cout << " --> $date token @" << *yylloc << std::endl;
    }
    //yylloc->lines();
    yylloc->step();
    BEGIN(VCD_DATE);
};

\$version {
    if(yy_flex_debug)
    {
        std::cout << " --> $version token @" << *yylloc << std::endl;
    }
    yylloc->step();
    BEGIN(VCD_VERSION);
};

\$var {
    if(yy_flex_debug)
    {
        std::cout << " --> $var token @" << *yylloc << std::endl;
    }
    yylloc->step();
    BEGIN(VCD_VAR);
};

<VCD_DATE,VCD_VERSION,VCD_COMMENT,VCD_SIMULATION_COMMENT>[^\$\n]* {
    std::string l_string(yytext, yyleng);
    if(yy_flex_debug)
    {
        std::string l_start_condition;
        switch(YYSTATE)
        {
            case INITIAL:
                l_start_condition = "INITIAL";
                break;
            case VCD_COMMENT:
                l_start_condition = "VCD_COMMENT";
                break;
            case VCD_DATE:
                l_start_condition = "VCD_DATE";
                break;
            case VCD_VERSION:
                l_start_condition = "VCD_VERSION";
                break;
            case VCD_SIMULATION_COMMENT:
                l_start_condition = "VCD_SIMULATION_COMMENT";
                break;
            default:
                throw quicky_exception::quicky_logic_exception("Unknown start condition " + std::to_string(YYSTATE), __LINE__, __FILE__);
        }
        std::cout << R"( --> After start condition ")" << l_start_condition << R"(" ")" << l_string << R"(" @)" << *yylloc << std::endl;
    }
    yylloc->step();
}

<*>{Blank}+ {
    if(yy_flex_debug)
    {
        std::cout << " --> " << yyleng << " spaces @ " << *yylloc << std::endl;
    }
}

<VCD_TIMESCALE>10{0,2} {
    std::string l_string(yytext, yyleng);
    if(yy_flex_debug)
    {
        std::cout << " --> Timescale number " << l_string << " @" << *yylloc << std::endl;
    }
}

<VCD_TIMESCALE>(m|u|n|p|f)?s {
    std::string l_string(yytext, yyleng);
    if(yy_flex_debug)
    {
        std::cout << R"( --> Timescale unit ")" << l_string << R"(" @)" << *yylloc << std::endl;
    }
    yylloc->step();
}

<*>\$end {
    if(yy_flex_debug)
    {
        std::cout << " --> $end keyword @" << *yylloc << std::endl;
    }
    switch(YYSTATE)
    {
        case VCD_SIMULATION:
            // Do Nothing
            break;
        case VCD_SIMULATION_COMMENT:
            BEGIN(VCD_SIMULATION);
            break;
        default:
            BEGIN(INITIAL);
    }
    yylloc->step();
}

\$enddefinitions {
    if(yy_flex_debug)
    {
        std::cout << " --> $enddefinitions keyword @" << *yylloc << std::endl;
    }
    BEGIN(VCD_SIMULATION);
}

<VCD_SIMULATION>\$dumpvars {
    if(yy_flex_debug)
    {
        std::cout << " --> $dumpvars keyword @" << *yylloc << std::endl;
    }
}

<VCD_SIMULATION>\$dumpall {
    if(yy_flex_debug)
    {
        std::cout << " --> $dumpall keyword @" << *yylloc << std::endl;
    }
}

<VCD_SIMULATION>\$dumpon {
    if(yy_flex_debug)
    {
        std::cout << " --> $dumpon keyword @" << *yylloc << std::endl;
    }
}

<VCD_SIMULATION>\$dumpoff {
    if(yy_flex_debug)
    {
        std::cout << " --> $dumpoff keyword @" << *yylloc << std::endl;
    }
}

\$scope {
    if(yy_flex_debug)
    {
        std::cout << " --> Scope keyword @" << *yylloc << std::endl;
    }
    BEGIN(VCD_SCOPE);
}

\$upscope {
    if(yy_flex_debug)
    {
        std::cout << " --> Upscope keyword @" << *yylloc << std::endl;
    }
}

<VCD_SCOPE>begin {
        if(yy_flex_debug)
        {
            std::cout << " --> Begin keyword @" << *yylloc << std::endl;
        }
};

<VCD_SCOPE>fork {
        if(yy_flex_debug)
        {
            std::cout << " --> Fork keyword @" << *yylloc << std::endl;
        }
};

<VCD_SCOPE>function {
        if(yy_flex_debug)
        {
            std::cout << " --> Function keyword @" << *yylloc << std::endl;
        }
};

<VCD_SCOPE>module {
        if(yy_flex_debug)
        {
            std::cout << " --> Module keyword @" << *yylloc << std::endl;
        }
};

<VCD_SCOPE>task {
        if(yy_flex_debug)
        {
            std::cout << " --> Task keyword @" << *yylloc << std::endl;
        }
};

<VCD_VAR>event {
        if(yy_flex_debug)
        {
            std::cout << " --> Event keyword @" << *yylloc << std::endl;
        }
};

<VCD_VAR>integer {
        if(yy_flex_debug)
        {
            std::cout << " --> Integer keyword @" << *yylloc << std::endl;
        }
};

<VCD_VAR>parameter {
        if(yy_flex_debug)
        {
            std::cout << " --> Parameter keyword @" << *yylloc << std::endl;
        }
};

<VCD_VAR>real {
        if(yy_flex_debug)
        {
            std::cout << " --> Real keyword @" << *yylloc << std::endl;
        }
};

<VCD_VAR>reg {
        if(yy_flex_debug)
        {
            std::cout << " --> Reg keyword @" << *yylloc << std::endl;
        }
};

<VCD_VAR>supply0 {
        if(yy_flex_debug)
        {
            std::cout << " --> Supply0 keyword @" << *yylloc << std::endl;
        }
};

<VCD_VAR>supply1 {
        if(yy_flex_debug)
        {
            std::cout << " --> Supply1 keyword @" << *yylloc << std::endl;
        }
};

<VCD_VAR>time {
        if(yy_flex_debug)
        {
            std::cout << " --> Time keyword @" << *yylloc << std::endl;
        }
};

<VCD_VAR>tri {
        if(yy_flex_debug)
        {
            std::cout << " --> Tir keyword @" << *yylloc << std::endl;
        }
};

<VCD_VAR>triand {
        if(yy_flex_debug)
        {
            std::cout << " --> Triand keyword @" << *yylloc << std::endl;
        }
};

<VCD_VAR>trior {
        if(yy_flex_debug)
        {
            std::cout << " --> Trior keyword @" << *yylloc << std::endl;
        }
};

<VCD_VAR>trireg {
        if(yy_flex_debug)
        {
            std::cout << " --> Trireg keyword @" << *yylloc << std::endl;
        }
};

<VCD_VAR>tri0 {
        if(yy_flex_debug)
        {
            std::cout << " --> Tri0 keyword @" << *yylloc << std::endl;
        }
};

<VCD_VAR>tri1 {
        if(yy_flex_debug)
        {
            std::cout << " --> Tri1 keyword @" << *yylloc << std::endl;
        }
};

<VCD_VAR>wand {
        if(yy_flex_debug)
        {
            std::cout << " --> Wand keyword @" << *yylloc << std::endl;
        }
};

<VCD_VAR>wire {
        if(yy_flex_debug)
        {
            std::cout << " --> Wire keyword @" << *yylloc << std::endl;
        }
};

<VCD_VAR>wor {
        if(yy_flex_debug)
        {
            std::cout << " --> Wor keyword @" << *yylloc << std::endl;
        }
};

<VCD_SIMULATION>{SingleValue} {
    std::string l_string(yytext, yyleng);
    if(yy_flex_debug)
    {
        std::cout << " --> Single Value " << l_string << " @" << *yylloc << std::endl;
    }
    BEGIN(VCD_VALUE_CHANGE);
}

<VCD_VAR,VCD_VAR_REFERENCE,VCD_SIMULATION>{DecimalNumber} {
    std::string l_string(yytext, yyleng);
    if(yy_flex_debug)
    {
        std::cout << " --> Decimal number " << l_string << " @" << *yylloc << std::endl;
    }
}

<VCD_VECTOR_VALUE_CHANGE>{VectorValue} {
    std::string l_string(yytext, yyleng);
    if(yy_flex_debug)
    {
        std::cout << " --> Vector Value " << l_string << " @" << *yylloc << std::endl;
    }
    BEGIN(VCD_VALUE_CHANGE);
}

<VCD_REAL_VALUE_CHANGE>{RealNumber}|x|X {
    std::string l_string(yytext, yyleng);
    if(yy_flex_debug)
    {
        std::cout << " --> Real Value " << l_string << " @" << *yylloc << std::endl;
    }
    BEGIN(VCD_VALUE_CHANGE);
}

<VCD_SIMULATION>b|B {
    if(yy_flex_debug)
    {
        std::cout << " --> Binary vector value change @" << *yylloc << std::endl;
    }
    BEGIN(VCD_VECTOR_VALUE_CHANGE);
}

<VCD_SIMULATION>r|R {
    if(yy_flex_debug)
    {
        std::cout << " --> Real Value change @" << *yylloc << std::endl;
    }
    BEGIN(VCD_REAL_VALUE_CHANGE);
}

<VCD_SIMULATION># {
    if(yy_flex_debug)
    {
        std::cout << " --> Timestamp marker @" << *yylloc << std::endl;
    }
}

<VCD_SIMULATION>\<Out\ of\ memory\> {

}

<*>\r\n {
    if(yy_flex_debug)
    {
        std::cout << " --> End of line CR @" << *yylloc << std::endl;
    }
    yylloc->lines();
    yylloc->step();
};

<VCD_VAR_REFERENCE>\[ {
    if(yy_flex_debug)
    {
        std::cout << " --> '[' @" << *yylloc << std::endl;
    }
}

<VCD_VAR_REFERENCE>\] {
if(yy_flex_debug)
{
std::cout << " --> ']' @" << *yylloc << std::endl;
}
}

<VCD_VAR_REFERENCE>\: {
    if(yy_flex_debug)
    {
        std::cout << " --> ':' @" << *yylloc << std::endl;
    }
}

<VCD_VAR,VCD_VAR_NAME,VCD_VALUE_CHANGE>{GenericIdentifier} {
    std::string l_string(yytext, yyleng);
    if(yy_flex_debug)
    {
        std::cout << R"( --> Var Identifier code ")" << l_string << R"(" @)" << *yylloc << std::endl;
    }
    switch(YYSTATE)
    {
        case VCD_VAR:
            BEGIN(VCD_VAR_NAME);
            break;
        case VCD_VAR_NAME:
            BEGIN(VCD_VAR_REFERENCE);
            break;
        case VCD_VALUE_CHANGE:
            BEGIN(VCD_SIMULATION);
            break;
        default:
            BEGIN(VCD_VAR);
    }
}

<VCD_SCOPE>{Identifier} {
    std::string l_string(yytext, yyleng);
    if(yy_flex_debug)
    {
        std::cout << R"( --> Identifier ")" << l_string << R"(" @)" << *yylloc << std::endl;
    }
}
<*>\n {
    if(yy_flex_debug)
    {
        std::cout << " --> End of line R @" << *yylloc << std::endl;
    }
    yylloc->lines();
    yylloc->step();
};

. {
    if(yy_flex_debug)
    {
        std::string l_string(yytext, yyleng);
        std::cout << R"(UNKNOWN TOKEN ")" << l_string << R"(" @ )" << *yylloc << std::endl ;
    }
    driver.error("Unknown token");
    //return token::UNKNOWN;
}

%% /* Implementation of scanner class */


//EOF