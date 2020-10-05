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
/*Digit [0-9]*/
Blank [\t]|[\040]

/*DecimalNumber ({Digit})+*/

/* Location tracking */
%{
    #define YY_USER_ACTION yylloc->columns(yyleng);
%}

%x VCD_COMMENT
%x VCD_DATE
%x VCD_VERSION
%x VCD_TIMESCALE

%%

%{
// beginning of yylex()

// reset location
yylloc->step();
%}

\$comment {
    if(yy_flex_debug)
    {
        std::cout << " --> $comment token @" << *yylloc << std::endl;
    }
    //yylloc->lines();
    yylloc->step();
    BEGIN(VCD_COMMENT);
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

<VCD_COMMENT>^(\$end) {
// ignore comment in chunks
}

<VCD_COMMENT>\$end {
    if(yy_flex_debug)
    {
        std::cout << " END OF COMMENT" << std::endl;
    }
    yylloc->lines(yyleng);
    yylloc->step();
    BEGIN(INITIAL);
}

<VCD_DATE,VCD_VERSION>[^\$\n]* {
    std::string l_string(yytext, yyleng);
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
        default:
            throw quicky_exception::quicky_logic_exception("Unknown start condition " + std::to_string(YYSTATE), __LINE__, __FILE__);
    }
    if(yy_flex_debug)
    {
        std::cout << R"( --> After start condition ")" << l_start_condition << R"(" ")" << l_string << R"(" @)" << *yylloc << std::endl;
    }
}

<VCD_TIMESCALE>{Blank}+ {
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
}

<VCD_DATE,VCD_VERSION,VCD_TIMESCALE>\$end {
if(yy_flex_debug)
{
std::cout << " --> End keyword @" << *yylloc << std::endl;
}
BEGIN(INITIAL);
}

\$scope {
    if(yy_flex_debug)
    {
        std::cout << " --> Scope keyword @" << *yylloc << std::endl;
    }
}

<*>\r\n {
    if(yy_flex_debug)
    {
        std::cout << " --> End of line CR @" << *yylloc << std::endl;
    }
    yylloc->lines();
    yylloc->step();
};

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