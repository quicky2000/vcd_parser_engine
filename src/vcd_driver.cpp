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

#include "vcd_driver.h"
#include "vcd_parser.hpp"
#include "vcd_scanner.h"

namespace vcd_parser_engine
{
    //-------------------------------------------------------------------------
    vcd_driver::vcd_driver(const std::string & p_name)
    : m_name(p_name)
    , m_trace_scanning(true)
    , m_trace_parsing(false)
    {

    }

    //-------------------------------------------------------------------------
    const std::string &
    vcd_driver::get_stream_name() const
    {
        return m_name;
    }

    //-------------------------------------------------------------------------
    void
    vcd_driver::error(const location & loc,
                      const std::string & message
                     )
    {
        std::cerr << "ERROR : " << loc << R"( : ")" << message << R"(")" << std::endl;
    }

    //-------------------------------------------------------------------------
    void
    vcd_driver::error(const std::string & message)
    {
        std::cerr << R"(ERROR : ")" << message << R"(")" << std::endl;
    }

    //-------------------------------------------------------------------------
    int
    vcd_driver::parse()
    {
        flex_prefixlex_init(&m_scanner);
        FILE * in = fopen(m_name.c_str(),"r");
        if (!in)
        {
            error ("cannot open " + m_name + ": " + strerror(errno));
            exit (EXIT_FAILURE);
        }
        flex_prefixset_in(in,m_scanner);
        flex_prefixset_debug(m_trace_scanning,m_scanner);
        vcd_parser parser (m_scanner,*this,&m_loc,NULL);
        parser.set_debug_level (m_trace_parsing);
        int res = parser.parse ();
        flex_prefixlex_destroy(m_scanner);
        fclose(in);
        return res;
    }

}
// EOF