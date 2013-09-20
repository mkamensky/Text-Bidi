#!perl

use strict;
use warnings;

use Test::More;

eval "use Test::Perl::Critic";
plan skip_all => 'Test::Perl::Critic required to criticise code' if $@;
Test::Perl::Critic->import( -profile => "perlcritic.rc" ) if -e "perlcritic.rc";
my @files = grep { ! /private/ } Test::Perl::Critic::all_code_files();
plan tests => @files;
critic_ok($_) foreach @files;

