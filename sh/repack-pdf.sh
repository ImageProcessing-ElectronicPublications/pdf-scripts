#!/bin/sh

# FIXME: preserve bookmarks (very important!)
# FIXME: preserve annotations (not so important!)
# FIXME: remove watermarks (important!)
# FIXME: preserve OCR text (important!)

# FIXME: Rotate PDF pages: qpdf in.pdf --rotate=-90:221-227 --rotate=-90:325-326 out.pdf

#set -e

KEEP_TEMP_DIR=1
USE_LOCAL_DIR=1
RESOLUTION=300

case $1 in
    --help)
        echo "$0 [--keep-temp-dir] [--use-local-dir] <input.pdf>"
        exit 0
        ;;
    --keep-temp-dir)
        KEEP_TEMP_DIR=1
        shift
        ;;
    --use-local-dir)
        USE_LOCAL_DIR=1
        shift
        ;;
esac

# Note: mktemp instead of the other insecure alternatives
if [ $USE_LOCAL_DIR = 1 ]; then
    WORKDIR="$(mktemp -d --tmpdir=.)"
else
    WORKDIR="$(mktemp -d)"
fi

CURDIR="$PWD"
REALPATH="$(realpath "$1")"
ORIGDIR="$(dirname "$REALPATH")"
ORIGNAME="$(basename "$REALPATH")"
NEWNAME="$ORIGDIR/${ORIGNAME%%pdf}repack.pdf"

cd "$WORKDIR"

pdfimages -j -tiff "$REALPATH" a

# # FIXME: remove this hardcoded process!
# exiftool -Xresolution=$RESOLUTION -Yresolution=$RESOLUTION -ResolutionUnit=inches a-*; rm *_original

find . -iname "*.jpg" -print0 | xargs -0 -r jhead -purejpg
find . -iname "*.jpg" -print0 | xargs -0 -r jpgcrush
find . -iname "*.png" -print0 | xargs -0 -r pingo -lossless -s9 -verbose=3


PAGESIZE=$(pdfinfo "$REALPATH" | grep -P -i -o "\b(\d+)(.\d+)? x (\d+)(.\d+)?\b" | sed -e 's/ x /ptx/; s/$/pt/')

img2pdf --verbose -o "$NEWNAME" --pagesize $PAGESIZE *

cd "$CURDIR"

if [ $KEEP_TEMP_DIR = 0 ]; then
    rm -rf "$WORKDIR"
fi
