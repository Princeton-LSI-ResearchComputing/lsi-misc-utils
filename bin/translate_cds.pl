#!/usr/bin/perl -w

=head1 NAME

translate_cds.pl

=head1 SYNOPSIS

translate_cds.pl -gff orf.gff -fasta sequence.fa [-id gene] [-notrans] [-help]

 Required arguments:
    -gff      GFF file of coding sequences
    -fasta    Fasta sequence file

 Options:
    -id       GFF Attribute to use to collapse exons to genes (default=gene)
    -notrans  Do not transalte regions to AA
    -help -h  Help

=head1 DESCRIPTION 

Extract CDS regions from fasta reference and gff file and (optionally) translate.

=head1 AUTHOR

Lance Parsons <lparsons@princeton.edu>

=head1 LICENSE

This script is licensed by the Simplified BSD License
See LICENSE.TXT and <http://www.opensource.org/licenses/bsd-license>

Copyright (c) 2011, Lance Parsons
All rights reserved.

=cut

use strict;

use Bio::Seq;
use Bio::SeqIO;
use Bio::Tools::GFF;
use Data::Dumper;
use Getopt::Long;
use English;
use Carp;
use Pod::Usage;

############
### Init ###
############

# Variables set in response to command line arguments
# (with defaults)

my $needsHelp = '';
my $gff_filename;
my $fasta_filename;
my $id_annotatation = 'gene';
my $no_translate    = 0;

my $options_okay = &Getopt::Long::GetOptions(
	'gff=s'     => \$gff_filename,
	'fasta=s'   => \$fasta_filename,
	'id|i=s'    => \$id_annotatation,
	'notrans|t' => \$no_translate,
	'help|h'    => \$needsHelp
);
&check_opts();

# Read FASTA files
my $fasta_seqs = {};
my $fasta      = Bio::SeqIO->new(
	-file   => $fasta_filename,
	-format => 'fasta'
);

while ( my $seq = $fasta->next_seq() ) {

 #	print "Sequence ", $seq->id, " first 10 bases ", $seq->subseq( 1, 10 ), "\n";
	$fasta_seqs->{ $seq->id } = $seq;
}

# Read in GFF of coding regions for reference
my %gfffeatures;
my $gffio = Bio::Tools::GFF->new( -file => $gff_filename, -gff_version => 3 );

# loop over the input stream
while ( my $feature = $gffio->next_feature() ) {

	# Store in hash by name
	my $annotationCollection = $feature->annotation();
	my @tags                 = $feature->get_tag_values($id_annotatation);
	if ( scalar @tags < 1 ) {
		croak
"Feature in GFF file '$gff_filename' does not have the specified id annotation attribute: '"
		  . $id_annotatation . "'.";
	}
	my $feature_name = trim( $tags[0] );

	# Create ARRAY of feature locations to account for splits
	my @locations = ();
	if ( exists $gfffeatures{ $feature_name . "(" . $feature->strand() . ")" } )
	{
		my $locref =
		  $gfffeatures{ $feature_name . "(" . $feature->strand() . ")" };
		@locations = @$locref;
		push( @locations, $feature );
	} else {
		@locations = ($feature);
	}
	$gfffeatures{ $feature_name . "(" . $feature->strand() . ")" } =
	  \@locations;

}
$gffio->close();

# For each feature in gff1_features
while ( my ( $feature_name, $subfeaturesref ) = each(%gfffeatures) ) {

	my @subfeatures = @$subfeaturesref;
	my $feature_seq = "";
	my $seq_id;

	# For each location of feature1
	foreach my $feature (@subfeatures) {
		$seq_id = $feature->seq_id();

		if ( defined( $fasta_seqs->{ $feature->seq_id() } ) ) {

			# If rev_strand
			if ( $feature->strand() == -1 ) {
				$feature_seq =
				  $fasta_seqs->{ $feature->seq_id() }
				  ->trunc( $feature->start, $feature->end )->revcom()->seq()
				  . $feature_seq;
			} else {
				$feature_seq .=
				  $fasta_seqs->{ $feature->seq_id() }
				  ->trunc( $feature->start, $feature->end )->seq();
			}
		} else {
			warn(   "Can't find sequence '"
				  . $feature->seq_id()
				  . "' from gff feature '"
				  . $feature_name
				  . "' in fasta file!" );
		}
	}
	my $output_seq = Bio::PrimarySeq->new(
		-seq => $feature_seq,
		-id  => $seq_id . " " . $feature_name
	);
	my $feature_translation = $output_seq->translate( -complete => 1 );
	if ( !$no_translate ) {
		$output_seq = $feature_translation;
	}
	printf( "%s\t%s\t%s\n", $seq_id, $feature_name, $output_seq->seq() );
}

# Perl trim function to remove whitespace from the start and end of the string
sub trim {
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

# Left trim function to remove leading whitespace
sub ltrim {
	my $string = shift;
	$string =~ s/^\s+//;
	return $string;
}

# Right trim function to remove trailing whitespace
sub rtrim {
	my $string = shift;
	$string =~ s/\s+$//;
	return $string;
}

# Check for problem with the options or if user requests help
sub check_opts {
	if ($needsHelp) {
		pod2usage( -verbose => 2 );
	}

	if ( !$options_okay ) {
		pod2usage(
			-exitval => 2,
			-verbose => 1,
			-message => "Error specifying options."
		);
	}
	if ( !-e $gff_filename ) {
		pod2usage(
			-exitval => 2,
			-verbose => 1,
			-message => "Cannot read gff file: '$gff_filename!'\n"
		);
	}
	if ( !-e $fasta_filename ) {
		pod2usage(
			-exitval => 2,
			-verbose => 1,
			-message => "Cannot read fasta file: '$fasta_filename!'\n"
		);
	}
}

