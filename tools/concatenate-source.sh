#!/usr/bin/env bash

# Allow running this script from another directory
cd "$(dirname "$0")"

cd ..


# Ordered list of all library source files
source_files='
    ./tools/intro.js
    ./lib/xregexp.js
    ./lib/addons/build.js
    ./lib/addons/matchrecursive.js
    ./lib/addons/unicode-base.js
    ./lib/addons/unicode-blocks.js
    ./lib/addons/unicode-categories.js
    ./lib/addons/unicode-properties.js
    ./lib/addons/unicode-scripts.js
    ./tools/outro.js
'

# Unordered list of all source files which MAY need any XregExp version number updated
to_patch_files='
    ./src/xregexp.js
    ./src/addons/build.js
    ./src/addons/matchrecursive.js
    ./src/addons/unicode-base.js
    ./src/addons/unicode-blocks.js
    ./src/addons/unicode-categories.js
    ./src/addons/unicode-properties.js
    ./src/addons/unicode-scripts.js
'

# Update the version numbers everywhere
if [ -f ./package.json ]; then
    v=$( node -e 'var pkg = require("./package.json"); console.log(pkg.version);' )
    for file in $to_patch_files
    do
        cat "${file}" | sed -e "s/\\* XRegExp\\([ -][^0-9]*\\)\\([0-9]\\+\\..*\\)\$/* XRegExp\\1$v/" -e "s/XRegExp\.version = [^;]\\+;/XRegExp.version = '$v';/" > __tmp__
        cat __tmp__ > "${file}"
    done
    rm -f __tmp__ 
else
    echo "This repo doesn't come with a package.json file"
fi


# compile source files using babel:
# Remove old babel output files before running the compiler
rm -rf lib
mkdir -p lib/addons
node_modules/.bin/babel src -d lib


# Filename of concatenated package
output_file='./xregexp-all.js'

# Remove output file to re-write it
rm -f $output_file

# Concatenate all source files
for file in $source_files
do
    # use SED to kill duplicate definitions of REGEX_DATA and functions pad4, dec and hex.
    # Also clear out the internal export statements: the intro+outro takes care of that
    # in full UMD/AMD style.
    cat "${file}" | sed -e 's/^\}; *\/\/ *End of module.*$//' \
                        -e 's/^module\.exports *= *function *(XRegExp) *{//' \
                        -e 's/module\.exports *= *XRegExp;//' \
                        -e "s/module\\.exports *= *exports\\['default'\\];//" \
                        -e 's/exports\.default *= *XRegExp;//' \
                        -e 's/exports\.default *= *function *(XRegExp) *{//' \
                        -e "s/'use strict';//" \
                        -e "s/REGEX_DATA = 'xregexp',//" \
                        -e '/\/\/ Adds leading zeros if shorter than four characters/,/\/\/ Gets the decimal code/ { /Gets the decimal/ p; d; }' \
                        -e '/Object\.defineProperty(exports, "__esModule", {/,+2d' \
                        >> "${output_file}"
    echo '' >> "${output_file}"
done


# and none of the following should dump core when the code is intact:
echo "Testing source file integrity: lib/xregexp.js"
node ./lib/xregexp.js

echo "Testing source file integrity: all (babel-compiled) sources in lib/"
node ./lib/index.js

echo "Testing source file integrity: generated output file xregexp-all.js"
node "${output_file}"


echo "Successfully created $(basename $output_file)"
