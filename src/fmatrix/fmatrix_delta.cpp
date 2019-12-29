#include <fstream>
#include <vector>
#include <string>
#include <iostream>
#include <sstream>
#include <unistd.h> //getopt function, to parse options

#include "matrix.h"

using namespace std;
using namespace upc;

int usage(const char *prog) {
  cout << prog << " -f fields input_fmatrix output_fmatrix\n";
  return -1;
}

int get_options(int ArgC, const char *ArgV[], string &ifname, string &ofname, vector<unsigned int> &colsel) {

  char option;
  colsel.clear();

  //optarg and optind are global variables declared and set by the getopt() function

  string s;
  stringstream ss;
  int i;

  while ((option = getopt(ArgC, (char **)ArgV, "hf:")) != -1) {
    switch (option) {
    case 'f': 
      s = optarg;      
      replace(s.begin(), s.end(), ',', ' ');
      ss.str(s);
       while (ss >> i) {
	 if (i<1) {
	   cerr << "Invalid field selector <1: " << i << endl; 
	   return -1;
	 }
	 colsel.push_back(i-1);
      }
      break;

    case 'h':
    default:
      return -1;
    }
  }
  if (optind+1 != ArgC-1)
    return -1;

  ifname = ArgV[optind];
  ofname = ArgV[optind+1];
  return 0;
  
}

int main(int argc, const char *argv[]) {

  string input_filename, output_filename;
  vector<unsigned int> row_selector;
  if (get_options(argc, argv, input_filename, output_filename, row_selector)) {
    return usage(argv[0]);
  }

  ifstream is(input_filename.c_str(), ios::binary);
  if (!is.good()) {
    cerr << "Error opening input file: " << input_filename << endl;
    return -2;
  }
  
  fmatrix m;
  is >> m;
  if (!is.good()) {
    cerr << "Error reading file: " << input_filename << endl;
    return -3;
  }


  //check columns
  int nrow = 0;
  for (unsigned int i=0; i<row_selector.size(); i++) {
    if (row_selector[i] > m.nrow()) {
      cerr << "Error: invalid column selector for matrix " 
	   << m.ncol() << 'x' << m.nrow() << ": " << row_selector[i] << endl;
    } else
      nrow++;
  }

  fmatrix m2(m.nrow()/3, m.ncol());

  for (unsigned int c=0; c<m.ncol(); ++c)
    for (unsigned int i=0; i<m2.nrow(); i++)
      //m2[i][c] = m[3*i][c]*m[(3*i)+1][c]*m[(3*i)+2][c];
      m2[i][c] = m[3*i][c];
  ofstream os(output_filename.c_str(), ios::binary);
  if (!os.good()) {
    cerr << "Error opening output file: " << output_filename << endl;
    return -2;
  }
  
  os << m2;
  if (!os.good()) {
    cerr << "Error reading file: " << output_filename << endl;
    return -3;
  }


  return 0;
}
