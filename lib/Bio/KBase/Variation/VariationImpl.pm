package Bio::KBase::Variation::VariationImpl;
use strict;
use Bio::KBase::Exceptions;
# Use Semantic Versioning (2.0.0-rc.1)
# http://semver.org 
our $VERSION = "0.1.0";

=head1 NAME

Variation

=head1 DESCRIPTION



=cut

#BEGIN_HEADER
#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR
    #END_CONSTRUCTOR

    if ($self->can('_init_instance'))
    {
	$self->_init_instance();
    }
    return $self;
}

=head1 METHODS



=head2 picard_qual_metrics

  $return = $obj->picard_qual_metrics($arg_1)

=over 4

=item Parameter and return types

=begin html

<pre>
$arg_1 is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a reference to a list where each element is a float

</pre>

=end html

=begin text

$arg_1 is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a reference to a list where each element is a float


=end text



=item Description

This function computes a tab delimited output that can be used to
plot the Mismatch Rate, HQ Error Rate, and INDEL RATE for a set of
alignments. 

The output column 1 is the name of the bam.qual file and represents
an alignment. The output column 2 is the Mismatch Rate, column 3 is
the HQ Error Rate, and column 4 is the INDEL RATE.

The input could be a set of awe job ids.

=back

=cut

sub picard_qual_metrics
{
    my $self = shift;
    my($arg_1) = @_;

    my @_bad_arguments;
    (ref($arg_1) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"arg_1\" (value was \"$arg_1\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to picard_qual_metrics:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'picard_qual_metrics');
    }

    my $ctx = $Bio::KBase::Variation::Service::CallContext;
    my($return);
    #BEGIN picard_qual_metrics

	# given an awe job handle, get the bam file handle
	# given a bam file, run picard
	# given picard output, parse into return value

    #END picard_qual_metrics
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to picard_qual_metrics:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'picard_qual_metrics');
    }
    return($return);
}




=head2 translate_handles

  $return = $obj->translate_handles($handles, $converter)

=over 4

=item Parameter and return types

=begin html

<pre>
$handles is a reference to a list where each element is a Handle
$converter is a string
$return is a reference to a list where each element is a Handle
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is a HandleId
	file_name has a value which is a string
	id has a value which is a string
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string
HandleId is a string

</pre>

=end html

=begin text

$handles is a reference to a list where each element is a Handle
$converter is a string
$return is a reference to a list where each element is a Handle
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is a HandleId
	file_name has a value which is a string
	id has a value which is a string
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string
HandleId is a string


=end text



=item Description

The translate_handles function takes as input a list of handles
of the same type, and returns a list of handles as specified by
the translator behavior. In the first example, an AWE
translator translates a AWE job handle into a set of SHOCK
handles that represent the data inputs and outputs of the job.

=back

=cut

sub translate_handles
{
    my $self = shift;
    my($handles, $converter) = @_;

    my @_bad_arguments;
    (ref($handles) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"handles\" (value was \"$handles\")");
    (!ref($converter)) or push(@_bad_arguments, "Invalid type for argument \"converter\" (value was \"$converter\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to translate_handles:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'translate_handles');
    }

    my $ctx = $Bio::KBase::Variation::Service::CallContext;
    my($return);
    #BEGIN translate_handles

	# contact the awe server retreiving job document
	# parse out input and output urls
	# construct return value

    #END translate_handles
    my @_bad_returns;
    (ref($return) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to translate_handles:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'translate_handles');
    }
    return($return);
}




=head2 version 

  $return = $obj->version()

=over 4

=item Parameter and return types

=begin html

<pre>
$return is a string
</pre>

=end html

=begin text

$return is a string

=end text

=item Description

Return the module version. This is a Semantic Versioning number.

=back

=cut

sub version {
    return $VERSION;
}

=head1 TYPES



=head2 HandleId

=over 4



=item Description

Handle provides a unique reference that enables
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


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 Handle

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
hid has a value which is a HandleId
file_name has a value which is a string
id has a value which is a string
type has a value which is a string
url has a value which is a string
remote_md5 has a value which is a string
remote_sha1 has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
hid has a value which is a HandleId
file_name has a value which is a string
id has a value which is a string
type has a value which is a string
url has a value which is a string
remote_md5 has a value which is a string
remote_sha1 has a value which is a string


=end text

=back



=head2 AWE_id

=over 4



=item Description

The AWE_id is a uuid that uniquely represents the compute job
on an awe client.


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=cut

1;
