package App::Rangeops;

our $VERSION = '0.0.2';

use App::Cmd::Setup -app;

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

       merge: merge runlist yaml files

See C<rangeops commands> for usage information.

=head1 AUTHOR

Qiang Wang <wang-q@outlook.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qiang Wang.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
