package App::Rangeops;

our $VERSION = '0.0.7';

use strict;
use warnings;
use App::Cmd::Setup -app;

# TODO: nest (java)
#   remove locations fully contained by others. egas/blastn_genome.pl
# TODO: bundle links
# TODO: circos
#
##----------------------------#
## write circos link files
##----------------------------#
#{
#    print "Write circos link files\n";
#
#    # linkN is actually hightlight file
#    my $link_fh_of = {};
#    for ( 2 .. $low_cut, 'N' ) {
#        open my $fh, ">", "$output.cc.link$_.txt";
#        $link_fh_of->{$_} = $fh;
#    }
#
#    my @colors = reverse map {"paired-12-qual-$_"} ( 1 .. 12 );
#    my $color_idx = 0;
#    for my $c (@cc) {
#        my $copy = scalar @{$c};
#        next if $copy < 2;
#
#        if ( $copy > $low_cut ) {
#            for ( @{$c} ) {
#                my ( $chr, $set, $strand ) = string_to_set($_);
#                print { $link_fh_of->{N} }
#                    join( " ", $chr, $set->min, $set->max, "fill_color=" . $colors[$color_idx] ),
#                    "\n";
#            }
#
#            # rotate color
#            $color_idx++;
#            $color_idx = 0 if $color_idx > 11;
#            next;
#        }
#
#        for my $idx1 ( 0 .. $copy - 1 ) {
#            for my $idx2 ( $idx1 + 1 .. $copy - 1 ) {
#                my @fields;
#                for ( $idx1, $idx2 ) {
#                    my ( $chr, $set, $strand ) = string_to_set( $c->[$_] );
#                    push @fields,
#                        (
#                            $chr, $strand eq "+"
#                                ? ( $set->min, $set->max )
#                                : ( $set->max, $set->min )
#                        );
#                }
#                print { $link_fh_of->{$copy} } join( " ", @fields ), "\n";
#            }
#        }
#    }
#
#    close $link_fh_of->{$_} for ( 2 .. $low_cut, 'N' );
#    print "\n";
#}


1;

__END__

=head1 NAME

App::Rangeops - operates ranges and links of ranges on chromosomes

=head1 SYNOPSIS

    rangeops <command> [-?h] [long options...]
        -? -h --help    show help

    Available commands:

      commands: list the application's commands
          help: display a command's help screen

         merge: merge overlapped ranges via overlapping graph
          sort: sort range links

See C<rangeops commands> for usage information.

=head1 DESCRIPTION

Types of links:

=over 8

=item Bilateral links

    I(+):13063-17220	I(-):215091-219225
    I(+):139501-141431	XII(+):95564-97485

=item Bilateral links with hit strand

    I(+):13327-17227	I(+):215084-218967	-
    I(+):139501-141431	XII(+):95564-97485	+

=item Multilateral links

    II(+):186984-190356	IX(+):12652-16010	X(+):12635-15993

=item Merge files aren't links

    I(-):13327-17227	I(+):13327-17227

=back

Steps:

    sort
      |
      v
    clean <-- merge
      |
      v
    connect
      |
      v
    filter

=head1 AUTHOR

Qiang Wang <wang-q@outlook.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qiang Wang.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
