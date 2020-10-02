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

typedef vcd_parser_engine::vcd_parser::token      token;
typedef vcd_parser_engine::vcd_parser::token_type token_type;

// Redefine yyterminate to return a token_type instead of int
#define yyterminate() return vcd_parser_engine::vcd_parser::make_END_OF_STREAM(*yylloc)

//#define state_begin(p_state)  begin_state(p_state,#p_state)

// No need for unistd, as we use C++ streams
//#define YY_NO_UNISTD_H

%}

%option bison-bridge bison-locations reentrant
%option noyywrap nounput batch debug noinput
%option prefix="flex_prefix"


/* Location tracking */
%{
    #define YY_USER_ACTION yylloc->columns(yyleng);
%}

%x VCD_COMMENT
%x VCD_DATE
%x IPTG_DIRECTIVE_COMMENT
%x INCLUDE_DIRECTIVE

%%

%{
// beginning of yylex()

// reset location
yylloc->step();
%}

<INITIAL>\$comment {
    //std::cout << "ICI" << std::endl;
                  BEGIN(VCD_COMMENT);
}

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

\$date {

    if(yy_flex_debug)
    {
        std::cout << " $date token @" << *yylloc << std::endl;
    }

};

\r\n {
yylloc->lines();
yylloc->step();
};

\n {
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