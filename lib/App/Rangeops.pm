package App::Rangeops;

our $VERSION = '0.0.6';

use strict;
use warnings;
use App::Cmd::Setup -app;

# TODO: nest (java)
#   remove locations fully contained by others. egas/blastn_genome.pl
# TODO: bundle links
# TODO: filter
#   * difference of lengthes. egas/proc_cc_chop.pl
#   * copy numbers.

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
