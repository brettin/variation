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



=cut

1;
