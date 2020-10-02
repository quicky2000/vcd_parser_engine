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

#ifndef VCD_DRIVER_H
#define VCD_DRIVER_H
#include "vcd_parser.hpp"
#include <string>
#include <iostream>

namespace vcd_parser_engine
{
    class vcd_scanner;

    class vcd_driver
    {
      public:

        vcd_driver(const std::string & p_name);

        const std::string & get_stream_name() const;

        int parse();

        void error( const class location & loc
                , const std::string & message
                  );

        void error(const std::string & message);

      private:
        std::string m_name;
        yyscan_t m_scanner;
        vcd_parser::location_type m_loc;
        vcd_parser::semantic_type m_val;
        bool m_trace_scanning;
        bool m_trace_parsing;
    };

}

#endif // VCD_DRIVER_H
// EOF