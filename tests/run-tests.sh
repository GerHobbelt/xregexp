#! /bin/bash
#


pushd $(dirname $0)                                                                                     2> /dev/null  > /dev/null



echo "Constructing consolidated test file (otherwise jasmine won't test correctly!)"

# concat all test files to create a file for NodeJS that behaves like xregexp in the browser:
cat ../xregexp-all.js | \
sed -e 's/^}(this, function() {$/});/' \
    -e 's/^return XRegExp;$/(({/' \
    -e 's/^\/\/ Module systems magic dance$/"use strict";\n\n/' \
 > node-test-suite.js

# Helpers
cat helpers/h.js >> node-test-suite.js
cat helpers/h-matchers.js >> node-test-suite.js
cat helpers/h-unicode.js >> node-test-suite.js

# Specs
cat spec/s-xregexp.js >> node-test-suite.js
cat spec/s-xregexp-methods.js >> node-test-suite.js
cat spec/s-xregexp-natives.js >> node-test-suite.js
cat spec/s-addons-build.js >> node-test-suite.js
cat spec/s-addons-matchrecursive.js >> node-test-suite.js
cat spec/s-addons-unicode.js >> node-test-suite.js



echo ""
echo ""



../node_modules/.bin/jasmine



popd                                                                                                    2> /dev/null  > /dev/null


