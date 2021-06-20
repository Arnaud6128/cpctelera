#include <conversors/BASICConversor.hpp>
#include <iostream>
#include <iomanip>

void
BASICConversor::outputCharDefs_p(
      std::ostream& out, const TArrayChar8x8& chardef
   ,  uint16_t symbol, uint16_t line) const 
{
   out << std::dec << line << " SYMBOL " << symbol;
   for (auto c : chardef) {
      out << ",";
      print8bitNumberFormatted(out, c, true);
   }
   out << "\n";
}

void 
BASICConversor::convert_p(std::ostream& out) const {
   uint16_t sym      = uint16_t(m_firstUDG);
   uint16_t line     = m_firstLine;
   uint32_t numchars = m_width*m_height/64;

   // Ouput header information
   outputTextHeader_p(out, "1 '");

   // Convert characters to BASIC
   start_p();
   while(numchars--) {
      outputCharDefs_p( out, getNextChar_p(), sym, line );
      sym ++;
      line += 10;
   }
}

