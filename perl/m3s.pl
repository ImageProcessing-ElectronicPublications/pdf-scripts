#!/usr/bin/perl -W
#
# Copyright (C) 2009 Rogério Brito <rbrito@users.sf.net>
#
# $Id$
#
# This program is Free Software and is distributed under the terms of
# the GNU General Public License version 2 or, at your option, any
# latter version.
#

use strict 'vars';
use warnings;
use utf8;

use Encode qw(encode decode);
use MP3::Tag;


# ==============================================================================
# Auxiliary functions for generation of the output
sub pr_header {
print FH <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Current Version</key><integer>1</integer>
	<key>Compatible Version</key><integer>1</integer>
	<key>Application</key><string>m3s v0.0</string>
	<key>Burner Info</key><string>$_[0]</string>
	<key>Disc ID</key><string>$_[1]</string>
	<key>Disc Name</key><string>$_[2]</string>
	<key>tracks</key>
	<array>
EOF
}
sub pr_footer { print FH "\t</array>\n</dict>\n</plist>\n"; }


# ==============================================================================
# Functions to generate the proper XML tags for iTunes.
sub pr_open_dict  { print FH "\t\t<dict>\n"; }
sub pr_key        { print FH "\t\t\t<key>", my_utf8_encode($_[0]), "</key>"; }
sub pr_string     { print FH "<string>", my_utf8_encode($_[0]), "</string>\n"; }
sub pr_integer    { print FH "<integer>", my_utf8_encode($_[0]), "</integer>\n"; }
sub pr_date       { print FH "<date>", my_utf8_encode($_[0]), "</date>\n"; }
sub pr_boolean    { print FH ($_[0])?"<true/>\n":"<false/>\n"; }
sub pr_close_dict { print FH "\t\t</dict>\n"; }


# ==============================================================================
# Auxiliary functions
sub gen_serial_no {
    return sprintf("%04X%04X%04X%04X", rand(0xffff), rand(0xffff),
		   rand(0xffff), rand(0xffff));
}

sub escape_char { my $st = shift; $st =~ s/&/&#38;/g; return $st; }
sub my_utf8_encode { return escape_char(encode("utf8", $_[0])); }

sub recurse_dir {
    my $dh;

    opendir($dh, $_[0]) or die("Error opening dir $_[0]: $!\n");

    my $par_name = $_[1];
    my $file_no = 0;
    my $dir_no = 0;

    # grep {!/\.|\.\./}
    foreach (sort readdir($dh)) { # for each entry
	my $name = "$_[0]/$_";
	if (-d $name and $_ ne "." and $_ ne "..") {
	    ++$dir_no;
	    recurse_dir($name, $par_name?"$par_name:$dir_no":$dir_no, $dir_no);
	} elsif ($_ ne "." and $_ ne "..") {
	    ++$file_no;

	    my $filename = $_[0];
	    if (m!\.mp3$!i) {
		generate_song_entry("$_[0]/$_",
				    $par_name?"$par_name:$file_no":$file_no,
				    $file_no);
	    }
	}
    }
    closedir($dh) or die("Error closing dir $_[0]: $!\n");
}


# ==============================================================================
# Function to grab information from an MP3 file
sub generate_song_entry {
    # initialize mp3 object
    my $mp3 = new MP3::Tag $_[0];

    # Perform the information gathering from the file:
    my ($title, $track, $artist, $album, $comment, $year, $genre) = $mp3->autoinfo();

    my ($track1, $track2, $disc1, $disc2) = ($mp3->track1(), $mp3->track2(),
					     $mp3->disk1(), $mp3->disk2());

    my ($time, $bitrate, $frequency, $is_vbr, $size) = (int($mp3->total_secs()*1000),
							$mp3->bitrate_kbps(),
							$mp3->frequency_Hz(),
							$mp3->is_vbr(),
							$mp3->size_bytes());

    # destroy object
    $mp3->close();

    # Now, we fill in the entry for this file
    pr_open_dict();

    if (defined($title))	{ pr_key("Name"); pr_string($title); }
    if (defined($artist))	{ pr_key("Artist"); pr_string($artist); }
    if (defined($album))	{ pr_key("Album"); pr_string($album); }
    if (defined($genre))	{ pr_key("Genre"); pr_string($genre); }
    if (defined($year))		{ pr_key("Year"); pr_integer($year); }
    if (defined($track1))	{ pr_key("Track Number"); pr_integer($track1); }
    if (defined($track2))	{ pr_key("Track Count"); pr_integer($track2); }
    if (defined($disc1))	{ pr_key("Disc Number"); pr_integer($disc1); }
    if (defined($disc2))	{ pr_key("Disc Count"); pr_integer($disc2); }
    if (defined($time))		{ pr_key("Total Time"); pr_integer($time); }
    if (defined($bitrate))	{ pr_key("Bit Rate"); pr_integer($bitrate); }
    if (defined($frequency))	{ pr_key("Sample Rate"); pr_integer($frequency); }
    if (defined($is_vbr))	{ pr_key("Has Variable Bit Rate"); pr_boolean($is_vbr); }
    if (defined($size))		{ pr_key("Size"); pr_integer($size); };

    if ((exists($mp3->{ID3v1}) or exists($mp3->{ID3v2}))) {
	pr_key("Supports ID3 Tags"); pr_boolean("true");
    }

    # Compulsory filling
    { pr_key("Date"); pr_string(12345678); };
    { pr_key("Date Modified"); pr_date("2009-03-02T19:50:00Z"); };
    { pr_key("Numeric Path"); pr_string("$_[1]"); };
    { pr_key("File Extension"); pr_string("mp3"); };

    pr_close_dict();
}


# ==============================================================================
# main program

my $root   = defined($ARGV[0])?$ARGV[0]:".";
my $file   = "$root/ContentsDB.xml";
my $title  = defined($ARGV[1])?my_utf8_encode($ARGV[1]):"My MP3 CD-ROM";
my $burner = defined($ARGV[2])?my_utf8_encode($ARGV[2]):"DVD-ROM DRIVE";
my $serial = gen_serial_no();

open(FH, ">$file") or die("Error opening file $file: $!\n");

pr_header($burner, $serial, $title);
recurse_dir($root, "");
pr_footer();

close(FH) or die("Error closing file $file: $!\n");


# ===========================================================================
=head1 NAME

m3s - generate ContentsDB.xml file for an MP3 CD to be recognized by
iTunes

=head1 SYNOPSIS

  m3s [root-dir] [disc-title] [burner-model]

=head1 DESCRIPTION

The m3s program is meant to generate a ContentsDB.xml file for a
directory tree containing MP3 files meant to be burned to a CD or DVD
that can, latter, be recognized by iTunes as a "big" CD, without the
need to connect to the network to fetch metadata (this is usually the
default action that iTunes takes when an Audio CD is inserted on the
optical reader of the computer).

The C<root-dir> parameter specifies the root directory of the tree where
the MP3 files are located. If it is not specified, then, it is assumed
to be the current working directory. The MP3 files are, then, parsed and
the ContentsDB.xml file is written at the C<root-dir> directory. This
makes it convenient to create a CD/DVD image.

A command like the following may be used:

    genisoimage -J -ucs-level 1 -o disc-title.iso -V "disc-title" root-dir

The C<disc-title> parameter specifies the name that iTunes will show to
the user as being the name of the disc.

The C<burner-model> parameter is purely cosmetic and is used to inform
iTunes which drive model was used to burn the disc. It apparently serves
no purpose other than this (please, let me know if I am mistaken).

Listed below are the fields that Apple's iTunes version 8 writes in each
song's stanza, with the kind of value corresponding to that field:

=over

=item * Name (string)

=item * Artist (string)

=item * Album (string)

=item * Genre (string)

=item * Persistent ID (string, hex number, 16 digits) *

=item * Play Count (integer) *

=item * Play Date (integer, -991494962) *

=item * Disc Number (integer) *

=item * Disc Count (integer) *

=item * Track Number (integer)

=item * Track Count (integer)

=item * Year (integer)

=item * Total Time (integer)

=item * Bit Rate (integer)

=item * Has Variable Bit Rate (boolean) *

=item * Sample Rate (integer)

=item * Date (string, hex number, 8 digits)

=item * Date Modified (date, ISO format)

=item * Size (integer)

=item * Supports ID3 Tags (boolean)

=item * Numeric Path (string)

=item * File Extension (string)

=back

In the header of the contentsdb.xml file:

=over

=item * Disc ID (string, hex number, 16 digits)

=item * Disc Name (string)

=back

Fields marked with * are not present in iTunes v4.6)

=head1 LICENCE

This program is Free Software and is distributed under the terms of the
GNU General Public License version 2 or, at your option, any latter
version.

=head1 AUTHOR

This program was written by Rogério Brito <rbrito@users.sf.net> on
$Date$.

=cut
