[![Build Status](https://travis-ci.org/wang-q/App-Rangeops.svg?branch=master)](https://travis-ci.org/wang-q/App-Rangeops)
[![Cpan version](https://img.shields.io/cpan/v/App-Rangeops.svg)](https://metacpan.org/release/App-Rangeops)

# NAME

App::Rangeops - operates ranges and links of ranges on chromosomes

# SYNOPSIS

    rangeops <command> [-?h] [long options...]
        -? -h --help    show help

    Available commands:

      commands: list the application's commands
          help: display a command's help screen

         merge: merge overlapped ranges via overlapping graph
          sort: sort range links

See `rangeops commands` for usage information.

# DESCRIPTION

Types of links:

- Bilateral links

        I(+):13063-17220    I(-):215091-219225
        I(+):139501-141431  XII(+):95564-97485

- Bilateral links with hit strand

        I(+):13327-17227    I(+):215084-218967      -
        I(+):139501-141431  XII(+):95564-97485      +

- Multilateral links

Steps:

    sort
      |
      v
    clean <-- merge
      |
      v
    connect

# AUTHOR

Qiang Wang &lt;wang-q@outlook.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qiang Wang.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
