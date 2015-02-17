module Variation {

  /* A Handle, copied from the Handle Service spec */

  /* Handle provides a unique reference that enables
     access to the data files through functions provided
     as part of the HandleService. In the case of using
     shock, the id is the node id. In the case of using
     shock the value of type is shock. In the future
     these values should enumerated. The value of url is
     the http address of the shock server, including the
     protocol (http or https) and if necessary the port.
     The values of remote_md5 and remote_sha1 are those
     computed on the file in the remote data store. These
     can be used to verify uploads and downloads.
  */

  typedef string HandleId;
  typedef structure {
          HandleId hid;
          string file_name;
          string id;
          string type;
          string url;
          string remote_md5;
          string remote_sha1;
  } Handle;


  /* The AWE_id is a uuid that uniquely represents the compute job
     on an awe client.
  */

  typedef string AWE_id;

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


  /* This section contains helper methods, those methods that would
     be private by default.
  */

  /* The translate_handles function takes as input a list of handles
     of the same type, and returns a list of handles as specified by
     the translator behavior. In the first example, an AWE
     translator translates a AWE job handle into a set of SHOCK
     handles that represent the data inputs and outputs of the job.
  */
     
  funcdef translate_handles (list<Handle> handles, string converter )
    returns (list<Handle>);
};
