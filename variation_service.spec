module Variation {

  /* This function computes a tab delimited output that can be used to
     plot the Mismatch Rate, HQ Error Rate, and INDEL RATE for a set of
     alignments. 

     The output column 1 is the name of the bam.qual file and represents
     an alignment. The output column 2 is the Mismatch Rate, column 3 is
     the HQ Error Rate, and column 4 is the INDEL RATE.

     The input could be a set of awe job ids.
  */

  funcdef picard_qual_metrics(list<string>)
    returns(mapping<string, list<float>>); 

};
