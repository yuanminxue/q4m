#! /usr/bin/perl

use Test::More tests => 2051;

use strict;
use warnings;

use DBI;

my $TEST_ROWS = 1024;

my $dbh = DBI->connect(
    $ENV{DBI} || 'dbi:mysql:database=test;host=localhost',
    $ENV{DBI_USER} || 'root',
    $ENV{DBI_PASSWORD} || '',
) or die 'connection failed:';

ok($dbh->do('drop table if exists q4m_t'));
ok($dbh->do('create table q4m_t (v int not null) engine=queue'));

for (my $i = 0; $i < $TEST_ROWS; $i++) {
    ok($dbh->do("insert into q4m_t (v) values ($i)"));
}

my %exp = map { $_ => 1 } (0 .. ($TEST_ROWS - 1));

is_deeply(
    $dbh->selectall_arrayref('select v from q4m_t'),
    [ map { [ $_ ] } sort { $a <=> $b } keys %exp ],
);

for (my $i = 0; $i < $TEST_ROWS / 2; $i++) {
    my $r = ($i * 2) % $TEST_ROWS;
    ok($dbh->do("delete from q4m_t where v=$r"));
    delete $exp{$r};
    is_deeply(
        $dbh->selectall_arrayref('select v from q4m_t'),
        [ map { [ $_ ] } sort { $a <=> $b } keys %exp ],
    );
}
