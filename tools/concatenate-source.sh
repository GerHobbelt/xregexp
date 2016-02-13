#!/usr/bin/env bash

# Allow running this script from another directory
cd "$(dirname "$0")"

# Ordered list of all source files
source_files='
    ./intro.js
    ../src/xregexp.js
    ../src/addons/build.js
    ../src/addons/matchrecursive.js
    ../src/addons/unicode-base.js
    ../src/addons/unicode-blocks.js
    ../src/addons/unicode-categories.js
    ../src/addons/unicode-properties.js
    ../src/addons/unicode-scripts.js
    ./outro.js
'

# Filename of concatenated package
output_file='../xregexp-all.js'

# Remove output file to re-write it
rm -f $output_file

# Concatenate all source files
for file in $source_files
do
    # use SED to kill duplicate definitions of REGEX_DATA and functions pad4, dec and hex.
    # Also clear out the internal export statements: the intro+outro takes care of that
    # in full UMD/AMD style.
    cat "${file}" | sed -e 's/^\};//' \
                        -e 's/^module\.exports *= *function(XRegExp) *{//' \
                        -e 's/module\.exports *= *XRegExp;//' \
                        -e "s/'use strict';//" \
                        -e "s/REGEX_DATA = 'xregexp',//" \
                        -e '/\/\/ Adds leading zeros if shorter than four characters/,/\/\/ Gets the decimal code/ { /Gets the decimal/ p; d; }' \
                        >> "${output_file}"
    echo '' >> "${output_file}"
done

echo "Successfully created $(basename $output_file)"
