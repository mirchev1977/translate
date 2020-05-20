#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;
use URI::URL;
use v5.10;
use Data::Dumper;
use JSON;

my ( undef, $mins, $hour, $day, $month, $year ) = localtime;

$day = sprintf( "%02d", $day );
$month++;
$month = sprintf( "%02d", $month );
$hour  = sprintf( "%02d", $hour );
$mins  = sprintf( "%02d", $mins );
$year += 1900;

my $dt = "$year$month$day$hour$mins";

my @source =  split( /\n/, `ls source` );


my @arr;
for my $fl ( @source ) {
    open( my $fh, '<', "./source/$fl" );

    my $buff = '';
    while ( my $ln = <$fh> ) {
        chomp $ln;
        $ln =~ s/^\s*//;
        $ln =~ s/\s*$//;
        $buff .= $ln;
    }

    my $data = decode_json( $buff );

    my $no = 0;
    for my $entry ( @{ $data->{ 'log' }->{ 'entries' } } ) {
        if ( $entry->{ '_resourceType' } eq 'media' ) {
            my $url = $entry->{ 'request' }->{ 'url' };

            next if $url =~ /sorry/;

            $url = URI->new( $url );
            my %query = $url->query_form;

            my $out = "dest/files/${dt}_${no}.mp3";

            my $_url = $entry->{ 'request' }->{ 'url' };


            for ( 1..5 ) {
                my $res = `/bin/bash ./test.sh "$_url" "$out"`;

                my $size = -s $out;

                say "SIZE: $size:$out\n";
                last;
            }

            my $sz = -s $out;
            `rm $out` if $sz < 1000;

            push ( @arr, { 
                    no      => $no,
                    file    => $fl,
                    time    => $entry->{ 'time'    },
                    q       => $query{   'q' },
                    lang    => $query{   'tl'      },
                    textlen => $query{   'textlen' },
                    play    => $entry->{ 'request' }->{ 'url' },
                    audio   => $out,
                    ident   => $dt,
                } );
            $no++;
        }
    }

    close( $fh );
}


my @data;
if ( `ls ./dest/data` ) {
    @data = @{ JSON->new->utf8(0)->decode( `cat ./dest/data` ) };
    @arr = ( @data, @arr );
}

my $json = JSON->new->utf8(0)->encode( \@arr );

open( my $fh, '>', './dest/data' );
print $fh $json;
close( $fh );

$json = 'var arr = ' . $json;


open( my $fh, '>', './dest/source.js' );
print $fh $json;
close( $fh );

say "finished: $dt";
