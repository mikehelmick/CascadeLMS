#!/bin/sh
ssh -fNL 4000:uml3.sanclass.org:3306 helmicmt@easlnx01.eas.muohio.edu
ssh -fNL 4001:ldapsun1.muohio.edu:389 helmicmt@easlnx01.eas.muohio.edu