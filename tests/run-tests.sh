#! /bin/bash
#


pushd $(dirname $0)                                                                                     2> /dev/null  > /dev/null



cd ..

./node_modules/.bin/jasmine JASMINE_CONFIG_PATH=./tests/jasmine.json



popd                                                                                                    2> /dev/null  > /dev/null


