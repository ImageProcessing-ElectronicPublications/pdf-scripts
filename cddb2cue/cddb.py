#!/usr/bin/env python

import json
import re

def parse_headers(lines):
    """
    Parse 'comment' lines.

    Returns a tuple with the length of the disc in seconds followed by the
    start positions of the tracks in frames (that is, 1/75ths of seconds).
    """

    # Metadata to take from the file
    disc_data = {
        'artist': '',
        'genre': '',
        'length': 0,
        'offsets': [],
        'title': '',
        'year': 0,
        'tracktitles': []
    }

    # This doesn't actually match comments only at the beginning (yet)
    header_lines = [line for line in lines if line != '' and line.startswith('#')]
    other_lines = [line for line in lines if line != '' and not line.startswith('#')]

    # Data from the header
    for line in header_lines:
        m = re.match('^#\s+Track frame offsets:', line)
        if m:
            continue

        m = re.match('^#\s+(\d+)', line)
        if m:
            disc_data['offsets'].append(int(m.group(1)))
            continue

        m = re.match('^#\s+Disc length: (\d+)', line)
        if m:
            disc_data['length'] = int(m.group(1))
            disc_data['offsets'].append(int(m.group(1)) * 75)
            break

    # Data from the rest of the file
    for line in other_lines:
        m = re.match('^DTITLE=(.*)\s/\s(.*)', line)
        if m:
            disc_data['artist'] = m.group(1)
            disc_data['title'] = m.group(2)
            break

    for line in other_lines:
        m = re.match('^DYEAR=(\d+)', line)
        if m:
            disc_data['year'] = int(m.group(1))
            break

    for line in other_lines:
        m = re.match('^DGENRE=(.*)', line)
        if m:
            disc_data['genre'] = m.group(1)
            break

    for line in other_lines:
        m = re.match('^TTITLE(\d+)=(.*)', line)
        if m:
            disc_data['tracktitles'].append(m.group(2))

    return disc_data


def frames_to_hour(stamp):
    ff = stamp % 75
    stamp = stamp / 75
    hh = stamp / 3600
    mm = (int(stamp) % 3600) / 60
    ss = int(stamp) % 60

    if hh:
        return '%02d:%02d:%02d:%02d' % (hh, mm, ss, ff)
    else:
        return '%02d:%02d:%02d' % (mm, ss, ff)


def create_cue(disc_data):
    """
    Receives one dictionary like above and prints the info in cuesheet format.
    """
    print 'PERFORMER "%s"' % disc_data['artist']

    if disc_data['year']:
        print 'REM DATE %d' % disc_data['year']

    if disc_data['genre']:
        print 'REM GENRE "%s"' % disc_data['genre']

    print 'TITLE "%s"' % disc_data['title']
    print 'FILE "%s - %s.mp3" MP3' % (disc_data['artist'], disc_data['title'])

    pairs = zip(disc_data['tracktitles'], disc_data['offsets'])

    # FIXME: In the following, 150 should be replaced by first entry of the offsets list.
    for trackno, (tracktitle, offset) in enumerate(pairs):
        print '  TRACK %d AUDIO' % (trackno + 1)
        print '    TITLE "%s"' % tracktitle
        print '    INDEX 01 %s' % frames_to_hour(offset - 150)


if __name__ == '__main__':

    with open('example.cddb') as f:
        lines = f.readlines()

    # seconds, frames = parse_headers(lines)
    # print('The disc has %d seconds.' % seconds)
    # print('The tracks begin: %s.' % frames[:-1])
    # print('The tracks delim: %s.' % frames)

    data = parse_headers(lines)
    #print json.dumps(data, indent=4)

    create_cue(data)
    #print create_cue(data)