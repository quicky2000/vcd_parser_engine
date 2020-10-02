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

#ifdef VCD_PARSER_ENGINE_SELF_TEST
#include "parameter_manager.h"
#include "vcd_driver.h"

int main(int p_argc, char ** p_argv)
{
    try
    {
        // Defining application command line parameters
        parameter_manager::parameter_manager l_param_manager("vcd_parser.exe","--",1);
        parameter_manager::parameter_if l_vcd_file_name_parameter("vcd", false);
        l_param_manager.add(l_vcd_file_name_parameter);

        // Treating parameters
        l_param_manager.treat_parameters(p_argc, p_argv);
        vcd_parser_engine::vcd_driver l_driver(l_vcd_file_name_parameter.get_value<std::string>());
        l_driver.parse();
    }
   catch(quicky_exception::quicky_runtime_exception & e)
    {
        std::cout << "ERROR : " << e.what() << " from " << e.get_file() << ":" << e.get_line() << std::endl ;
        return(-1);
    }
    catch(quicky_exception::quicky_logic_exception & e)
    {
        std::cout << "ERROR : " << e.what() << " from " << e.get_file() << ":" << e.get_line() << std::endl ;
        return(-1);
    }

    return 0;
}
#endif // VCD_PARSER_ENGINE_SELF_TEST
// EOF
