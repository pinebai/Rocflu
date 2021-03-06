/* *******************************************************************
 * Illinois Open Source License                                      *
 *                                                                   *
 * University of Illinois/NCSA                                       * 
 * Open Source License                                               *
 *                                                                   *
 * Copyright@2008, University of Illinois.  All rights reserved.     *
 *                                                                   *
 *  Developed by:                                                    *
 *                                                                   *
 *     Center for Simulation of Advanced Rockets                     *
 *                                                                   *
 *     University of Illinois                                        *
 *                                                                   *
 *     www.csar.uiuc.edu                                             *
 *                                                                   *
 * Permission is hereby granted, free of charge, to any person       *
 * obtaining a copy of this software and associated documentation    *
 * files (the "Software"), to deal with the Software without         *
 * restriction, including without limitation the rights to use,      *
 * copy, modify, merge, publish, distribute, sublicense, and/or      *
 * sell copies of the Software, and to permit persons to whom the    *
 * Software is furnished to do so, subject to the following          *
 * conditions:                                                       *
 *                                                                   *
 *                                                                   *
 * @ Redistributions of source code must retain the above copyright  * 
 *   notice, this list of conditions and the following disclaimers.  *
 *                                                                   * 
 * @ Redistributions in binary form must reproduce the above         *
 *   copyright notice, this list of conditions and the following     *
 *   disclaimers in the documentation and/or other materials         *
 *   provided with the distribution.                                 *
 *                                                                   *
 * @ Neither the names of the Center for Simulation of Advanced      *
 *   Rockets, the University of Illinois, nor the names of its       *
 *   contributors may be used to endorse or promote products derived * 
 *   from this Software without specific prior written permission.   *
 *                                                                   *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,   *
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES   *
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND          *
 * NONINFRINGEMENT.  IN NO EVENT SHALL THE CONTRIBUTORS OR           *
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER       * 
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   *
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE    *
 * USE OR OTHER DEALINGS WITH THE SOFTWARE.                          *
 *********************************************************************
 * Please acknowledge The University of Illinois Center for          *
 * Simulation of Advanced Rockets in works and publications          *
 * resulting from this software or its derivatives.                  *
 *********************************************************************/
#include <iostream>
#include <vector>
#include <list>
#include <sstream>
#include <cstdlib>

using namespace std;

#include "clop.H"

extern "C" {
  void RFLUMAP(const char *,int *,int *,int *,int *,long int);
} 

void
Usage(const string &pn)
{
  cout << endl << "Usage: " << pn << " -c <casename> -r <n> -p <m> [-v 0-2]" << endl << endl
       << "   -c | --casename  : Specifies the casename" << endl
       << "   -m | --mode      : Mapping mode:" << endl
       << "                      1 - Initial mapping" << endl
       << "                      2 - Final mapping" << endl
       << "   -r | --nregions  : Specifies the number of regions" << endl
       << "   -p | --nprocs    : Specifies the number of processes" << endl 
       << "   -v | --verbosity : Verbosity level:" << endl
       << "                      0 - Quiet" << endl
       << "                      1 - Moderately verbose" << endl
       << "                      2 - Ridiculously verbose" << endl
       << endl;
}

int
main(int argc,char *argv[])
{
  // Get the commandline into a string vector - it's easier
  // to deal with that way.
  vector<string> args = Vectize((const char **)argv,argc);

  // Get the name of the executable by stripping off any leading
  // directory names
  string program_name(stripdir(args[0]));

  // Specify the allowable options to the program
  AddOp("casename",'c');
  AddOp("mode",'m');
  AddOp("nregions",'r');  
  AddOp("nprocs",'p');
  AddOp("verbosity",'v');
  AddOp("help",'h');
  
  // Declare some variables for command line argument handling
  string casename;
  string smode,sprocs,sregs,sverb;
  int mode;
  int nprocs;
  int nregions;
  int verbosity;
  bool help;
  bool isset;
  
  // See if the help option is specified, if so give'm the usage text
  if(help = GetOp("help",args)){
    Usage(program_name);
    exit(0);
  }

  // Process casename option, if it's not set then fail
  if(GetOp("casename",casename,args)){
    if(casename.empty()){ // casename was empty
      cerr << program_name 
	   << ": Expected casename after casename option."
	   << " Use -h for usage instructions."
	   << endl;
      exit(1);
    }
  }
  else{ // option not specified (but it's required!)
    cerr << program_name
	 << ": Missing required casename option."
	 << "  Use -h for usage instructions."
	 << endl;
    exit(1);
  }      

  // Process mode option
  if(GetOp("mode",smode,args)){
    if(smode.empty()){
      cerr << program_name
	   << ": Expected mode value. "
	   << "Use -h for usage instructions." << endl;
      exit(1);
    }
    istringstream Istr(smode);
    Istr >> mode;
    if(mode < 1 || mode > 2){ // Some jerk specified an invalid number
      cerr << program_name
	   << ": Invalid mode value.  Use -h for usage "
	   << "instructions." << endl;
      exit(1);
    }
  }
  else{ // option not specified (but it's required!)
    cerr << program_name
	 << ": Missing mode value."
	 << "  Use -h for usage instructions."
	 << endl;
    exit(1);
  }    

  // Process nregions option
  if(GetOp("nregions",sregs,args)){
    if(sregs.empty()){
      cerr << program_name
	   << ": Expected number of regions. "
	   << "Use -h for usage instructions." << endl;
      exit(1);
    }
    istringstream Istr(sregs);
    Istr >> nregions;
    if(nregions < 1){ // Some jerk specified zero or a negative number
      cerr << program_name
	   << ": Invalid number of regions.  Use -h for usage "
	   << "instructions." << endl;
      exit(1);
    }
  }
  else{ // option not specified
    if(mode == 1){  
      cerr << program_name
	   << ": Missing number of regions."
	   << "  Use -h for usage instructions."
	   << endl;
      exit(1);
    }
    else {
      nregions = -1;
    }
  }    

  // Process nprocs option
  if(GetOp("nprocs",sprocs,args)){
    if(sprocs.empty()){
      cerr << program_name
	   << ": Expected number of processes. "
	   << "Use -h for usage instructions." << endl;
      exit(1);
    }
    istringstream Istr(sprocs);
    Istr >> nprocs;
    if(nprocs < 1){ // Some jerk specified zero or a negative number
      cerr << program_name
	   << ": Invalid number of processes.  Use -h for usage "
	   << "instructions." << endl;
      exit(1);
    } 
    if(nprocs > nregions){
      cerr << program_name
           << ": Number of processes must not exceed number of regions." << endl;
      exit(1);
    }
  }
  else{ // option not specified 
    if(mode == 1){
      cerr << program_name
	   << ": Missing number of processes."
	   << "  Use -h for usage instructions."
	   << endl;
      exit(1);
    } 
    else {
      nprocs = -1;
    }
  }    

  // Process verbosity option
  if(GetOp("verbosity",sverb,args)){
    if(sverb.empty()){
      cerr << program_name
	   << ": Expected verbosity level. "
	   << "Use -h for usage instructions." << endl;
      exit(1);
    }
    istringstream Istr(sverb);
    Istr >> verbosity;
    if(verbosity < 0 || verbosity > 2){ // Some jerk specified a non numeric or negative
      cerr << program_name
	   << ": Invalid verbosity value.  Use -h for usage "
	   << "instructions." << endl;
      exit(1);
    }
  }
  else{ // Default verbosity
    verbosity = 1;
  }

  RFLUMAP(casename.c_str(),&mode,&nregions,&nprocs,&verbosity,casename.length());
}

