#!/bin/bash

gs \
    -dQUIET \
    -dBATCH \
    -dNOPAUSE \
    -dSAFER \
    -sDEVICE=pdfwrite \
    -dCompatibilityLevel=1.6 \
    -dNumRenderingThreads=4 \
    -dAutoRotatePages=/None \
    -sColorConversionStrategy=RGB \
    -dAutoFilterColorImages=true \
    -dAutoFilterGrayImages=true \
    -dDownsampleColorImages=false \
    -dDownsampleGrayImages=false \
    -dDownsampleMonoImages=false \
    -dJPEGQ=90 \
    -dPDFA=2 \
    -sOutputFile="${1%.*}.pdfa.pdf" \
    -dPDFACompatibilityPolicy=1 \
    "$1" \
    ~/bin/pdfa.ps
