requires 'App::Cmd', '0.330';
requires 'AlignDB::IntSpan', '1.0.7';
requires 'App::RL', '0.2.25';
requires 'Graph';
requires 'IPC::Cmd';
requires 'List::MoreUtils', '0.413';
requires 'MCE', '1.708';
requires 'Path::Tiny', '0.076';
requires 'YAML::Syck', '1.29';
requires 'perl', '5.010001';

on test => sub {
    requires 'Test::More', 0.88;
};
