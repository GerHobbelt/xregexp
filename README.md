[XRegExp](http://xregexp.com/) 3.2.0-12
=======================================


[![Build Status](https://travis-ci.org/GerHobbelt/xregexp.svg?branch=master)](https://travis-ci.org/GerHobbelt/xregexp)


XRegExp provides augmented (and extensible) JavaScript regular expressions. You get modern syntax and flags beyond what browsers support natively. XRegExp is also a regex utility belt with tools to make your grepping and parsing easier, while freeing you from regex cross-browser inconsistencies and other annoyances.

XRegExp supports all native ES6 regular expression syntax. It supports ES5+ browsers, and you can use it with Node.js or as a RequireJS module.

## Performance

XRegExp compiles to native `RegExp` objects. Therefore regexes built with XRegExp perform just as fast as native regular expressions. There is a tiny extra cost when compiling a pattern for the first time.

## Usage examples

```js
// Using named capture and flag x for free-spacing and line comments
const date = XRegExp(
    `(?<year>  [0-9]{4} ) -?  # year
     (?<month> [0-9]{2} ) -?  # month
     (?<day>   [0-9]{2} )     # day`, 'x');

// XRegExp.exec gives you named backreferences on the match result
let match = XRegExp.exec('2017-02-22', date);
match.year; // -> '2017'

// It also includes optional pos and sticky arguments
let pos = 3;
const result = [];
while (match = XRegExp.exec('<1><2><3>4<5>', /<(\d+)>/, pos, 'sticky')) {
    result.push(match[1]);
    pos = match.index + match[0].length;
}
// result -> ['2', '3']

// XRegExp.replace allows named backreferences in replacements
XRegExp.replace('2017-02-22', date, '$<month>/$<day>/$<year>');
// -> '02/22/2017'
XRegExp.replace('2017-02-22', date, (match) => {
    return `${match.month}/${match.day}/${match.year}`;
});
// -> '02/22/2017'

// XRegExps compile to RegExps and work perfectly with native methods
date.test('2017-02-22');
// -> true

// The only caveat is that named captures must be referenced using
// numbered backreferences if used with native methods
'2017-02-22'.replace(date, '$2/$3/$1');
// -> '02/22/2017'

// Use XRegExp.forEach to extract every other digit from a string
const evens = [];
XRegExp.forEach('1a2345', /\d/, (match, i) => {
    if (i % 2) evens.push(+match[0]);
});
// evens -> [2, 4]

// Use XRegExp.matchChain to get numbers within <b> tags
XRegExp.matchChain('1 <b>2</b> 3 <B>4 \n 56</B>', [
    XRegExp('(?is)<b>.*?</b>'),
    /\d+/
]);
// -> ['2', '4', '56']

// You can also pass forward and return specific backreferences
const html =
    `<a href="http://xregexp.com/">XRegExp</a>
     <a href="http://www.google.com/">Google</a>`;
XRegExp.matchChain(html, [
    {regex: /<a href="([^"]+)">/i, backref: 1},
    {regex: XRegExp('(?i)^https?://(?<domain>[^/?#]+)'), backref: 'domain'}
]);
// -> ['xregexp.com', 'www.google.com']

// Merge strings and regexes, with updated backreferences
XRegExp.union(['m+a*n', /(bear)\1/, /(pig)\1/], 'i', {conjunction: 'or'});
// -> /m\+a\*n|(bear)\1|(pig)\2/i
```

These examples give the flavor of what's possible, but XRegExp has more syntax, flags, methods, options, and browser fixes that aren't shown here. You can also augment XRegExp's regular expression syntax with addons (see below) or write your own. See [xregexp.com](http://xregexp.com/) for details.

## Addons

You can either load addons individually, or bundle all addons with XRegExp by loading `xregexp-all.js` from https://unpkg.com/xregexp/xregexp-all.js.

### Unicode

If not using `xregexp-all.js`, first include the Unicode Base script and then one or more of the addons for Unicode blocks, categories, properties, or scripts.

Then you can do this:

```js
// Test the Unicode category L (Letter)
const unicodeWord = XRegExp('^\\pL+$');
unicodeWord.test('Русский'); // -> true
unicodeWord.test('日本語'); // -> true
unicodeWord.test('العربية'); // -> true

// Test some Unicode scripts
XRegExp('^\\p{Hiragana}+$').test('ひらがな'); // -> true
XRegExp('^[\\p{Latin}\\p{Common}]+$').test('Über Café.'); // -> true
```

By default, `\p{…}` and `\P{…}` support the Basic Multilingual Plane (i.e. code points up to `U+FFFF`). You can opt-in to full 21-bit Unicode support (with code points up to `U+10FFFF`) on a per-regex basis by using flag `A`. This is called *astral mode*. You can automatically add flag `A` for all new regexes by running `XRegExp.install('astral')`. When in astral mode, `\p{…}` and `\P{…}` always match a full code point rather than a code unit, using surrogate pairs for code points above `U+FFFF`.

```js
// Using flag A to match astral code points
XRegExp('^\\pS$').test('💩'); // -> false
XRegExp('^\\pS$', 'A').test('💩'); // -> true
XRegExp('(?A)^\\pS$').test('💩'); // -> true
// Using surrogate pair U+D83D U+DCA9 to represent U+1F4A9 (pile of poo)
XRegExp('(?A)^\\pS$').test('\uD83D\uDCA9'); // -> true

// Implicit flag A
XRegExp.install('astral');
XRegExp('^\\pS$').test('💩'); // -> true
```

Opting in to astral mode disables the use of `\p{…}` and `\P{…}` within character classes. In astral mode, use e.g. `(\pL|[0-9_])+` instead of `[\pL0-9_]+`.

XRegExp uses Unicode 9.0.0.

### XRegExp.build

Build regular expressions using named subpatterns, for readability and pattern reuse:

```js
const time = XRegExp.build('(?x)^ {{hours}} ({{minutes}}) $', {
    hours: XRegExp.build('{{h12}} : | {{h24}}', {
        h12: /1[0-2]|0?[1-9]/,
        h24: /2[0-3]|[01][0-9]/
    }),
    minutes: /^[0-5][0-9]$/
});

time.test('10:59'); // -> true
XRegExp.exec('10:59', time).minutes; // -> '59'
```

Named subpatterns can be provided as strings or regex objects. A leading `^` and trailing unescaped `$` are stripped from subpatterns if both are present, which allows embedding independently-useful anchored patterns. `{{…}}` tokens can be quantified as a single unit. Any backreferences in the outer pattern or provided subpatterns are automatically renumbered to work correctly within the larger combined pattern. The syntax `({{name}})` works as shorthand for named capture via `(?<name>{{name}})`. Named subpatterns cannot be embedded within character classes.

### XRegExp.matchRecursive

Match recursive constructs using XRegExp pattern strings as left and right delimiters:

```js
const str1 = '(t((e))s)t()(ing)';
XRegExp.matchRecursive(str1, '\\(', '\\)', 'g');
// -> ['t((e))s', '', 'ing']

// Extended information mode with valueNames
const str2 = 'Here is <div> <div>an</div></div> example';
XRegExp.matchRecursive(str2, '<div\\s*>', '</div>', 'gi', {
    valueNames: ['between', 'left', 'match', 'right']
});
/* -> [
{name: 'between', value: 'Here is ',       start: 0,  end: 8},
{name: 'left',    value: '<div>',          start: 8,  end: 13},
{name: 'match',   value: ' <div>an</div>', start: 13, end: 27},
{name: 'right',   value: '</div>',         start: 27, end: 33},
{name: 'between', value: ' example',       start: 33, end: 41}
] */

// Omitting unneeded parts with null valueNames, and using escapeChar
const str3 = '...{1}.\\{{function(x,y){return {y:x}}}';
XRegExp.matchRecursive(str3, '{', '}', 'g', {
    valueNames: ['literal', null, 'value', null],
    escapeChar: '\\'
});
/* -> [
{name: 'literal', value: '...',  start: 0, end: 3},
{name: 'value',   value: '1',    start: 4, end: 5},
{name: 'literal', value: '.\\{', start: 6, end: 9},
{name: 'value',   value: 'function(x,y){return {y:x}}', start: 10, end: 37}
] */

// Sticky mode via flag y
const str4 = '<1><<<2>>><3>4<5>';
XRegExp.matchRecursive(str4, '<', '>', 'gy');
// -> ['1', '<<2>>', '3']
```

`XRegExp.matchRecursive` throws an error if it scans past an unbalanced delimiter in the target string.

## Installation and usage

In browsers (bundle XRegExp with all of its addons):

```html
<script src="https://unpkg.com/xregexp/xregexp-all.js"></script>
```

Using [npm](https://www.npmjs.com/):

```bash
npm install xregexp
```

In [Node.js](http://nodejs.org/):

```js
const XRegExp = require('xregexp');
```

In an AMD loader like [RequireJS](http://requirejs.org/):

```js
require({paths: {xregexp: 'xregexp-all'}}, ['xregexp'], (XRegExp) => {
    console.log(XRegExp.version);
});
```

## About

XRegExp copyright 2007-2017 by [Steven Levithan](http://stevenlevithan.com/). Unicode data generators by [Mathias Bynens](http://mathiasbynens.be/), adapted from [unicode-data](http://git.io/unicode). XRegExp's syntax extensions and flags come from [Perl](http://www.perl.org/), [.NET](http://www.microsoft.com/net), etc.

All code, including addons, tools, and tests, is released under the terms of the [MIT License](http://mit-license.org/).

Fork me to show support, fix, and extend.

Learn more at [xregexp.com](http://xregexp.com/).





## Native support detection / RegExp flags

XRegExp internally detects if the JS engine supports any of these RegExp flags:

- `u` (defined in ES6 standard)
- `y` (defined in ES6 standard)
- `g`
- `i`
- `m`

These (and other flags registered by XRegExp addons) can be queried via the
`XRegExp._registeredFlags()` API, e.g. when you want to include this information in a system diagnostics report which accompanies a user or automated bug report.





# APIs


## XRegExp(pattern, flags) constructor

Creates an extended regular expression object for matching text with a pattern. Differs from a
native regular expression in that additional syntax and flags are supported. The returned object
is in fact a native `RegExp` and works with all native methods.

`pattern`
: {String|RegExp} Regex pattern string, or an existing regex object to copy.

`flags`
: {String} (optional) Any combination of flags.

  Native flags:

  - `g` - global
  - `i` - ignore case
  - `m` - multiline anchors
  - `u` - unicode (ES6)
  - `y` - sticky (Firefox 3+, ES6)

  Additional XRegExp flags:

  - `n` - explicit capture
  - `s` - dot matches all (aka singleline)
  - `x` - free-spacing and line comments (aka extended)
  - `A` - astral (requires the Unicode Base addon)

  Flags cannot be provided when constructing one `RegExp` from another.

Returns {RegExp} Extended regular expression object.

> `RegExp` is part of the XRegExp prototype chain (`XRegExp.prototype = new RegExp()`).

### Example

```
// With named capture and flag x
XRegExp('(?<year>  [0-9]{4} ) -?  # year  \
         (?<month> [0-9]{2} ) -?  # month \
         (?<day>   [0-9]{2} )     # day   ', 'x');

// Providing a regex object copies it. Native regexes are recompiled using native (not XRegExp)
// syntax. Copies maintain extended data, are augmented with `XRegExp.prototype` properties, and
// have fresh `lastIndex` properties (set to zero).
XRegExp(/regex/);
```



## XRegExp.version

The XRegExp version number as a string containing three dot-separated parts. For example,
'2.0.0-beta-3'.




## XRegExp: Public methods




## XRegExp.addToken(regex, handler, options)

Extends XRegExp syntax and allows custom flags. This is used internally and can be used to
create XRegExp addons. If more than one token can match the same string, the last added wins.

`regex`
: {RegExp} Regex object that matches the new token.

`handler`
: {Function} Function that returns a new pattern string (using native regex syntax)
  to replace the matched token within all future XRegExp regexes. Has access to persistent
  properties of the regex being built, through `this`. Invoked with three arguments:

  - The match array, with named backreference properties.
  - The regex scope where the match was found: 'default' or 'class'.
  - The flags used by the regex, including any flags in a leading mode modifier.

  The handler function becomes part of the XRegExp construction process, so be careful not to
  construct XRegExps within the function or you will trigger infinite recursion.

`options`
: {Object} (optional) Options object with optional properties:

  - `scope` {String} Scope where the token applies: 'default  'class  or 'all'.
  - `flag` {String} Single-character flag that triggers the token. This also registers the
    flag, which prevents XRegExp from throwing an 'unknown flag' error when the flag is used.
  - `optionalFlags` {String} Any custom flags checked for within the token `handler` that are
    not required to trigger the token. This registers the flags, to prevent XRegExp from
    throwing an 'unknown flag' error when any of the flags are used.
  - `reparse` {Boolean} Whether the `handler` function's output should not be treated as
    final, and instead be reparseable by other tokens (including the current token). Allows
    token chaining or deferring.
  - `leadChar` {String} Single character that occurs at the beginning of any successful match
    of the token (not always applicable). This doesn't change the behavior of the token unless
    you provide an erroneous value. However, providing it can increase the token's performance
    since the token can be skipped at any positions where this character doesn't appear.

### Examples

```
// Basic usage: Add \a for the ALERT control code
XRegExp.addToken(
  /\\a/,
  function() {return '\\x07';},
  {scope: 'all'}
);
XRegExp('\\a[\\a-\\n]+').test('\x07\n\x07'); // -> true

// Add the U (ungreedy) flag from PCRE and RE2, which reverses greedy and lazy quantifiers.
// Since `scope` is not specified, it uses 'default' (i.e., transformations apply outside of
// character classes only)
XRegExp.addToken(
  /([?*+]|{\d+(?:,\d*)?})(\??)/,
  function(match) {return match[1] + (match[2] ? '' : '?');},
  {flag: 'U'}
);
XRegExp('a+', 'U').exec('aaa')[0]; // -> 'a'
XRegExp('a+?', 'U').exec('aaa')[0]; // -> 'aaa'
```




## XRegExp.cache(pattern, flags)

Caches and returns the result of calling `XRegExp(pattern, flags)`. On any subsequent call with
the same pattern and flag combination, the cached copy of the regex is returned.

`pattern`
: {String} Regex pattern string.

`flags`
: {String} (optional) Any combination of XRegExp flags.

Returns {RegExp} Cached XRegExp object.

### Example

```
while (match = XRegExp.cache('.', 'gs').exec(str)) {
  // The regex is compiled once only
}
```



## XRegExp.cache.flush(cacheName)

> Intentionally undocumented; used in tests



## XRegExp.escape(str)

Escapes any regular expression metacharacters, for use when matching literal strings. The result
can safely be used at any point within a regex that uses any flags.

`str`
: {String} String to escape.

Returns {String} String with regex metacharacters escaped.

### Example

```js
XRegExp.escape('Escaped? <.>');
// -> 'Escaped\?\ <\.>'
```




## XRegExp.exec(str, regex, pos, sticky) 

Executes a regex search in a specified string. Returns a match array or `null`. If the provided
regex uses named capture, named backreference properties are included on the match array.
Optional `pos` and `sticky` arguments specify the search start position, and whether the match
must start at the specified position only. The `lastIndex` property of the provided regex is not
used, but is updated for compatibility. Also fixes browser bugs compared to the native
`RegExp.prototype.exec` and can be used reliably cross-browser.

`str` 
: {String} String to search.

`regex`
: {RegExp} Regex to search with.

`pos`
: {Number} [default: `pos=0`] Zero-based index at which to start the search.

`sticky`
: {Boolean|String} [default: `sticky=false`] Whether the match must start at the specified position
  only. The string `'sticky'` is accepted as an alternative to `true`.

Returns the match array with named backreference properties, or `null`.

```js
// Basic use, with named backreference
var match = XRegExp.exec('U+2620', XRegExp('U\\+(?<hex>[0-9A-F]{4})'));
match.hex; // -> '2620'

// With pos and sticky, in a loop
var pos = 2, result = [], match;
while (match = XRegExp.exec('<1><2><3><4>5<6>', /<(\d)>/, pos, 'sticky')) {
  result.push(match[1]);
  pos = match.index + match[0].length;
}
// result -> ['2', '3', '4']
```



## XRegExp.forEach(str, regex, callback) 

Executes a provided function once per regex match. Searches always start at the beginning of the
string and continue until the end, regardless of the state of the regex's `global` property and
initial `lastIndex`.
 
`str`
: {String} String to search.

`regex`
: {RegExp} Regex to search with.

`callback`
: {Function} Function to execute for each match. Invoked with four arguments:

  - The match array, with named backreference properties.
  - The zero-based match index.
  - The string being traversed.
  - The regex object being used to traverse the string.

### Example

```js
// Extracts every other digit from a string
var evens = [];
XRegExp.forEach('1a2345', /\d/, function(match, i) {
  if (i % 2) evens.push(+match[0]);
});
// evens -> [2, 4]
```




## XRegExp.globalize(regex) 

Copies a regex object and adds flag `g`. The copy maintains extended data, is augmented with
`XRegExp.prototype` properties, and has a fresh `lastIndex` property (set to zero). Native
regexes are not recompiled using XRegExp syntax.

`regex`
: {RegExp} Regex to globalize.

Returns a copy of the provided regex with flag `g` added.

```js
var globalCopy = XRegExp.globalize(/regex/);
globalCopy.global; // -> true
```



## XRegExp.install(options) 

Installs optional features according to the specified options. Can be undone using
`XRegExp.uninstall`.

`options`
: {Object|String} Feature options object or feature string.

### feature: astral

Enables or disables implicit astral mode opt-in. When enabled, flag A is automatically added to
all new regexes created by XRegExp. This causes an error to be thrown when creating regexes if
the Unicode Base addon is not available, since flag A is registered by that addon.

`astral`
: {Boolean} `true` to enable; `false` to disable.

### feature: natives

Native methods to use and restore ('native' is an ES3 reserved keyword).

These native methods are overridden:

- `exec`: `RegExp.prototype.exec`

- `test`: `RegExp.prototype.test`

- `match`: `String.prototype.match`

- `replace`: `String.prototype.replace`

- `split`: `String.prototype.split`


### Examples

```js
// With an options object
XRegExp.install({
  // Enables support for astral code points in Unicode addons (implicitly sets flag A)
  astral: true,

  // DEPRECATED: Overrides native regex methods with fixed/extended versions
  natives: true
});

// With an options string
XRegExp.install('astral natives');
```







## XRegExp.isInstalled(feature) 

Checks whether an individual optional feature is installed.

`feature`
: {String} Name of the feature to check. One of:

  - `astral`
  - `natives`

Return a {Boolean} value indicating whether the feature is installed.

```js
XRegExp.isInstalled('astral');
```



## XRegExp.isRegExp(value)

Returns `true` if an object is a regex; `false` if it isn't. This works correctly for regexes
created in another frame, when `instanceof` and `constructor` checks would fail.

`value`
: {any type allowed} The object to check.

Returns a {Boolean} value indicating whether the object is a `RegExp` object.

```js
XRegExp.isRegExp('string'); // -> false
XRegExp.isRegExp(/regex/i); // -> true
XRegExp.isRegExp(RegExp('^', 'm')); // -> true
XRegExp.isRegExp(XRegExp('(?s).')); // -> true
```




## XRegExp.match(str, regex, scope)

Returns the first matched string, or in global mode, an array containing all matched strings.
This is essentially a more convenient re-implementation of `String.prototype.match` that gives
the result types you actually want (string instead of `exec`-style array in match-first mode,
and an empty array instead of `null` when no matches are found in match-all mode). It also lets
you override flag g and ignore `lastIndex`, and fixes browser bugs.

`str`
: {String} String to search.

`regex`
: {RegExp} Regex to search with.

`scope`
: {String} [default: `scope='one'`] Use `'one'` to return the first match as a string. Use `'all'` to
  return an array of all matched strings. If not explicitly specified and `regex` uses flag `g`,
  `scope` is `'all'`.

Returns a {String} in match-first mode: First match as a string, or `null`. 

Returns an {Array} in match-all mode: Array of all matched strings, or an empty array.

```js
// Match first
XRegExp.match('abc', /\w/); // -> 'a'
XRegExp.match('abc', /\w/g, 'one'); // -> 'a'
XRegExp.match('abc', /x/g, 'one'); // -> null

// Match all
XRegExp.match('abc', /\w/g); // -> ['a  'b  'c']
XRegExp.match('abc', /\w/, 'all'); // -> ['a  'b  'c']
XRegExp.match('abc', /x/, 'all'); // -> []
```




## XRegExp.matchChain(str, chain)

Retrieves the matches from searching a string using a chain of regexes that successively search
within previous matches. The provided `chain` array can contain regexes and or objects with
`regex` and `backref` properties. When a backreference is specified, the named or numbered
backreference is passed forward to the next regex or returned.

`str`
: {String} String to search.

`chain`
: {Array} Regexes that each search for matches within preceding results.

Returns an {Array} of matches by the last regex in the chain, or an empty array.

```js
// Basic usage; matches numbers within <b> tags
XRegExp.matchChain('1 <b>2</b> 3 <b>4 a 56</b>', [
  XRegExp('(?is)<b>.*?</b>'),
  /\d+/
]);
// -> ['2', '4', '56']

// Passing forward and returning specific backreferences
html = '<a href="http://xregexp.com/api/">XRegExp</a>\
        <a href="http://www.google.com/">Google</a>';
XRegExp.matchChain(html, [
  {regex: /<a href="([^"]+)">/i, backref: 1},
  {regex: XRegExp('(?i)^https?://(?<domain>[^/?#]+)'), backref: 'domain'}
]);
// -> ['xregexp.com', 'www.google.com']
```




## XRegExp.replace(str, search, replacement, scope)

Returns a new string with one or all matches of a pattern replaced. The pattern can be a string
or regex, and the replacement can be a string or a function to be called for each match. To
perform a global search and replace, use the optional `scope` argument or include flag g if using
a regex. Replacement strings can use `${n}` for named and numbered backreferences. Replacement
functions can use named backreferences via `arguments[0].name`. Also fixes browser bugs compared
to the native `String.prototype.replace` and can be used reliably cross-browser.

`str`
: {String} String to search.

`search`
: {RegExp|String} Search pattern to be replaced.

`replacement`
: {String|Function} Replacement string or a function invoked to create it.
  
  Replacement strings can include special replacement syntax:

  - `$$` - Inserts a literal `$` character.
  - `$&`, `$0` - Inserts the matched substring.
  - `$\`` - Inserts the string that precedes the matched substring (left context).
  - `$'` - Inserts the string that follows the matched substring (right context).
  - `$n`, `$nn` - Where `n`/`nn` are digits referencing an existent capturing group, inserts
    backreference `n`/`nn`.
  - `${n}` - Where `n` is a name or any number of digits that reference an existent capturing
    group, inserts backreference `n`.

  Replacement functions are invoked with three or more arguments:

  - The matched substring (corresponds to $& above). Named backreferences are accessible as
    properties of this first argument.
  - 0..n arguments, one for each backreference (corresponding to $1, $2, etc. above).
  - The zero-based index of the match within the total search string.
  - The total string being searched.

`scope`
: {String} [default: `scope='one'`] Use `'one'` to replace the first match only, or `'all'`. If not
  explicitly specified and using a regex with flag `g`, `scope` is `'all'`.

Returns a new string with one or all matches replaced.

```js
// Regex search, using named backreferences in replacement string
var name = XRegExp('(?<first>\\w+) (?<last>\\w+)');
XRegExp.replace('John Smith', name, '${last}, ${first}');
// -> 'Smith, John'

// Regex search, using named backreferences in replacement function
XRegExp.replace('John Smith', name, function(match) {
  return match.last + ', ' + match.first;
});
// -> 'Smith, John'
 
// String search, with replace-all
XRegExp.replace('RegExp builds RegExps', 'RegExp', 'XRegExp', 'all');
// -> 'XRegExp builds XRegExps'
```




## XRegExp.replaceEach(str, replacements)

Performs batch processing of string replacements. Used like `XRegExp.replace`, but accepts an
array of replacement details. Later replacements operate on the output of earlier replacements.
Replacement details are accepted as an array with a regex or string to search for, the
replacement string or function, and an optional scope of 'one' or 'all'. Uses the XRegExp
replacement text syntax, which supports named backreference properties via `${name}`.

`str`
: {String} String to search.

`replacements`
: {Array} Array of replacement detail arrays.

Return a new string with all replacements.

```js
str = XRegExp.replaceEach(str, [
  [XRegExp('(?<name>a)'), 'z${name}'],
  [/b/gi, 'y'],
  [/c/g, 'x', 'one'], // scope 'one' overrides /g
  [/d/, 'w', 'all'],  // scope 'all' overrides lack of /g
  ['e', 'v', 'all'],  // scope 'all' allows replace-all for strings
  [/f/g, function($0) {
    return $0.toUpperCase();
  }]
]);
```




## XRegExp.split(str, separator, limit)

Splits a string into an array of strings using a regex or string separator. Matches of the
separator are not included in the result array. However, if `separator` is a regex that contains
capturing groups, backreferences are spliced into the result each time `separator` is matched.
Fixes browser bugs compared to the native `String.prototype.split` and can be used reliably
cross-browser.

`str`
: {String} String to split.

`separator`
: {RegExp|String} Regex or string to use for separating the string.

`limit`
: {Number} (optional) Maximum number of items to include in the result array.

Returns an array of substrings.

```js
// Basic use
XRegExp.split('a b c', ' ');
// -> ['a', 'b', 'c']
 
// With limit
XRegExp.split('a b c', ' ', 2);
// -> ['a', 'b']
 
// Backreferences in result array
XRegExp.split('..word1..', /([a-z]+)(\d+)/i);
// -> ['..', 'word', '1', '..']
```




## XRegExp.test(str, regex, pos, sticky) 

Executes a regex search in a specified string. Returns `true` or `false`. Optional `pos` and
`sticky` arguments specify the search start position, and whether the match must start at the
specified position only. The `lastIndex` property of the provided regex is not used, but is
updated for compatibility. Also fixes browser bugs compared to the native
`RegExp.prototype.test` and can be used reliably cross-browser.

`str`
: {String} String to search.

`regex`
: {RegExp} Regex to search with.

`pos`
: {Number} [default: `pos=0`] Zero-based index at which to start the search.

`sticky`
: {Boolean|String} [default: `sticky=false`] Whether the match must start at the specified position
  only. The string `'sticky'` is accepted as an alternative to `true`.

Returns a {Boolean} value indicating whether the regex matched the provided value.

```js
// Basic use
XRegExp.test('abc', /c/); // -> true
 
// With pos and sticky
XRegExp.test('abc', /c/, 0, 'sticky'); // -> false
XRegExp.test('abc', /c/, 2, 'sticky'); // -> true
```




## XRegExp.uninstall(options) 

Uninstalls optional features according to the specified options. All optional features start out
uninstalled, so this is used to undo the actions of `XRegExp.install`.
 
`options`
: {Object|String} Feature options object or features string. These features are supported:

  - `astral`
  - `natives`

```js
// With an options object
XRegExp.uninstall({
  // Disables support for astral code points in Unicode addons
  astral: true,
 
  // DEPRECATED: Restores native regex methods
  natives: true
});

// With an options string
XRegExp.uninstall('astral natives');
```




## XRegExp.join(patterns, separator, flags)

Returns an XRegExp object that is the concatenation of the given patterns. Patterns can be provided as
regex objects or strings. Metacharacters are escaped in patterns provided as strings.
Backreferences in provided regex objects are automatically renumbered to work correctly within
the larger combined pattern. Native flags used by provided regexes are ignored in favor of the
`flags` argument.

`patterns`
: {Array} Regexes and strings to combine.

`separator`
: {String|RegExp} Regex or string to use as the joining separator.

`flags`
: {String} (optional) Any combination of XRegExp flags.

Returns the union regexp of the provided regexes and strings.

```js
XRegExp.join(['a+b*c', /(dogs)\1/, /(cats)\1/], 'i');
// -> /a\+b\*c(dogs)\1(cats)\2/i
```




## XRegExp.union(patterns, flags)

Returns an XRegExp object that is the union of the given patterns. Patterns can be provided as
regex objects or strings. Metacharacters are escaped in patterns provided as strings.
Backreferences in provided regex objects are automatically renumbered to work correctly within
the larger combined pattern. Native flags used by provided regexes are ignored in favor of the
`flags` argument.

`patterns`
: {Array} Regexes and strings to combine.

`flags`
: {String} (optional) Any combination of XRegExp flags.

Returns the union regexp of the provided regexes and strings.

```js
XRegExp.union(['a+b*c', /(dogs)\1/, /(cats)\1/], 'i');
// -> /a\+b\*c|(dogs)\1|(cats)\2/i
```




## Fixed/extended native methods

Calling `XRegExp.install('natives')` uses this to override the native methods.




### RegExp.exec(str) 

Adds named capture support (with backreferences returned as `result.name`), and fixes browser
bugs in the native `RegExp.prototype.exec`. Calling `XRegExp.install('natives')` uses this to
override the native method. Use via `XRegExp.exec` without overriding natives.

`str`
: {String} String to search.

Returns the match array with named backreference properties, or `null`.




### RegExp.test(str)

Fixes browser bugs in the native `RegExp.prototype.test`. Calling `XRegExp.install('natives')`
uses this to override the native method.

`str`
: {String} String to search.

Returns a {Boolean} value indicating whether the regex matched the provided value.




### String.match(regex)

Adds named capture support (with backreferences returned as `result.name`), and fixes browser
bugs in the native `String.prototype.match`. Calling `XRegExp.install('natives')` uses this to
override the native method.

`regex`
: {RegExp|*} Regex to search with. If not a regex object, it is passed to the `RegExp` constructor.

Returns an array of match strings or `null`, if `regex` uses flag `g`. 

Returns the result of calling `regex.exec(this)`, if `regex` was without flag `g`.




### String.replace(search, replacement)

Adds support for `${n}` tokens for named and numbered backreferences in replacement text, and
provides named backreferences to replacement functions as `arguments[0].name`. Also fixes browser
bugs in replacement text syntax when performing a replacement using a nonregex search value, and
the value of a replacement regex's `lastIndex` property during replacement iterations and upon
completion. Calling `XRegExp.install('natives')` uses this to override the native method. Note
that this doesn't support SpiderMonkey's proprietary third (`flags`) argument. Use via
`XRegExp.replace` without overriding natives.

`search`
: {RegExp|String} Search pattern to be replaced.

`replacement`
: {String|Function} Replacement string or a function invoked to create it.

Returns a new string with one or all matches replaced.



### String.split(separator, limit) 

Fixes browser bugs in the native `String.prototype.split`. Calling `XRegExp.install('natives')`
uses this to override the native method. Use via `XRegExp.split` without overriding natives.

`separator`
: {RegExp|String} Regex or string to use for separating the string.

`limit`
: {Number} (optional) Maximum number of items to include in the result array.

Returns an array of substrings.



## Enhanced regex support features


### Letter Escapes are errors (unless...)

Letter escapes that natively match literal characters: `\a`, `\A`, etc. These should be
SyntaxErrors but are allowed in web reality. XRegExp makes them errors for cross-browser
consistency and to reserve their syntax, but lets them be superseded by addons.

```js
XRegExp.addToken(
    /\\([ABCE-RTUVXYZaeg-mopqyz]|c(?![A-Za-z])|u(?![\dA-Fa-f]{4}|{[\dA-Fa-f]+})|x(?![\dA-Fa-f]{2}))/, ...
```


### Unicode code point escapes (with curly braces)

Unicode code point escape with curly braces: `\u{N..}`. `N..` is any one or more digit
hexadecimal number from 0-10FFFF, and can include leading zeros. Requires the native ES6 `u` flag
to support code points greater than U+FFFF. Avoids converting code points above U+FFFF to
surrogate pairs (which could be done without flag `u`), since that could lead to broken behavior
if you follow a `\u{N..}` token that references a code point above U+FFFF with a quantifier, or
if you use the same in a character class.

```js
XRegExp.addToken(
    /\\u{([\dA-Fa-f]+)}/, ...
```


### Empty character class

Empty character class: `[]` or `[^]`. This fixes a critical cross-browser syntax inconsistency.
Unless this is standardized (per the ES spec), regex syntax can't be accurately parsed because
character class endings can't be determined.

```js
XRegExp.addToken(
    /\[(\^?)\]/, ...
```

### Regex comment pattern

Comment pattern: `(?# )`. Inline comments are an alternative to the line comments allowed in
free-spacing mode (flag `x`).

```js
XRegExp.addToken(
    /\(\?#[^)]*\)/, ...
```


### Free-spacing mode a.k.a. extended mode regexes

Whitespace and line comments, in free-spacing mode (aka extended mode, flag `x`) only.

```js
XRegExp.addToken(
    /\s+|#[^\n]*\n?/, ...
```


### Dotall mode a.k.a. singleline mode (`s` flag)

Dot, in dotall mode (aka singleline mode, flag `s`) only.

```js
XRegExp.addToken(
    /\./,
    function() {
        return '[\\s\\S]';
    },
    {
        flag: 's',
        leadChar: '.'
    }
);
```


### Named backreference

Named backreference: `\k<name>`. Backreference names can use the characters A-Z, a-z, 0-9, _,
and $ only. Also allows numbered backreferences as `\k<n>`.

```js
XRegExp.addToken(
    /\\k<([\w$]+)>/, ...
```


### Numbered backreference

Numbered backreference or octal, plus any following digits: `\0`, `\11`, etc. Octals except `\0`
not followed by 0-9 and backreferences to unopened capture groups throw an error. Other matches
are returned unaltered. IE < 9 doesn't support backreferences above `\99` in regex syntax.

```js
XRegExp.addToken(
    /\\(\d+)/, ...
```



### Named capture group

Named capturing group; match the opening delimiter only: `(?<name>`. Capture names can use the
characters A-Z, a-z, 0-9, _, and $ only. Names can't be integers. Supports Python-style
`(?P<name>` as an alternate syntax to avoid issues in some older versions of Opera which natively
supported the Python-style syntax. Otherwise, XRegExp might treat numbered backreferences to
Python-style named capture as octals.

```js
XRegExp.addToken(
    /\(\?P?<([\w$]+)>/, ...
```



### Capture group & explicit capture mode (`n` flag)

Capturing group; match the opening parenthesis only. Required for support of named capturing
groups. Also adds explicit capture mode (flag `n`).

```js
XRegExp.addToken(
    /\((?!\?)/,
    {
        optionalFlags: 'n',
        leadChar: '('
    }
```




## XRegExp.build(pattern, subs, flags) 

Builds regexes using named subpatterns, for readability and pattern reuse. Backreferences in
the outer pattern and provided subpatterns are automatically renumbered to work correctly.
Native flags used by provided subpatterns are ignored in favor of the `flags` argument.

`pattern`
: {String} XRegExp pattern using `{{name}}` for embedded subpatterns. Allows
  `({{name}})` as shorthand for `(?<name>{{name}})`. Patterns cannot be embedded within
  character classes.

`subs`  
: {Object} Lookup object for named subpatterns. Values can be strings or regexes. A
  leading `^` and trailing unescaped `$` are stripped from subpatterns, if both are present.

`flags`
: {String} (optional) Any combination of XRegExp flags.

Returns a regexp with interpolated subpatterns.

```js
var time = XRegExp.build('(?x)^ {{hours}} ({{minutes}}) $', {
  hours: XRegExp.build('{{h12}} : | {{h24}}', {
    h12: /1[0-2]|0?[1-9]/,
    h24: /2[0-3]|[01][0-9]/
  }, 'x'),
  minutes: /^[0-5][0-9]$/
});
time.test('10:59'); // -> true
XRegExp.exec('10:59', time).minutes; // -> '59'
```






## XRegExp.matchRecursive(str, left, right, flags, options) 

Returns an array of match strings between outermost left and right delimiters, or an array of
objects with detailed match parts and position data. An error is thrown if delimiters are
unbalanced within the data.

`str`
: {String} String to search.

`left`
: {String} Left delimiter as an XRegExp pattern.

`right`
: {String} Right delimiter as an XRegExp pattern.

`flags`
: {String} (optional) Any native or XRegExp flags, used for the left and right delimiters.

`options`
: {Object} (optional) Lets you specify `valueNames` and `escapeChar` options.

Returns an array of matches, or an empty array.

```js
// Basic usage
var str = '(t((e))s)t()(ing)';
XRegExp.matchRecursive(str, '\\(', '\\)', 'g');
// -> ['t((e))s', ' ', 'ing']
 
// Extended information mode with valueNames
str = 'Here is <div> <div>an</div></div> example';
XRegExp.matchRecursive(str, '<div\\s*>', '</div>', 'gi', {
  valueNames: ['between', 'left', 'match', 'right']
});
// -> [
// {name: 'between', value: 'Here is ',       start: 0,  end: 8},
// {name: 'left',    value: '<div>',          start: 8,  end: 13},
// {name: 'match',   value: ' <div>an</div>', start: 13, end: 27},
// {name: 'right',   value: '</div>',         start: 27, end: 33},
// {name: 'between', value: ' example',       start: 33, end: 41}
// ]
 
// Omitting unneeded parts with null valueNames, and using escapeChar
str = '...{1}.\\{{function(x,y){return {y:x}}}';
XRegExp.matchRecursive(str, '{', '}', 'g', {
  valueNames: ['literal', null, 'value', null],
  escapeChar: '\\'
});
// -> [
// {name: 'literal', value: '...',  start: 0, end: 3},
// {name: 'value',   value: '1',    start: 4, end: 5},
// {name: 'literal', value: '.\\{', start: 6, end: 9},
// {name: 'value',   value: 'function(x,y){return {y:x};}', start: 10, end: 37}
// ]
 
// Sticky mode via flag y
str = '<1><<<2>>><3>4<5>';
XRegExp.matchRecursive(str, '<', '>', 'gy');
// -> ['1', '<<2>>', '3']
```





## Unicode matching (`\p{..}`, `\P{..}`, `\p{^..}`, `\pC`) & astral mode (`A` flag)

XRegExp adds base support for Unicode matching:

- Adds syntax `\p{..}` for matching Unicode tokens. Tokens can be inverted using `\P{..}` or
  `\p{^..}`. Token names ignore case, spaces, hyphens, and underscores. You can omit the
  braces for token names that are a single letter (e.g. `\pL` or `PL`).

- Adds flag `A` (astral), which enables 21-bit Unicode support.

- Adds the `XRegExp.addUnicodeData` method used by other addons to provide character data.
 
Unicode Base relies on externally provided Unicode character data. Official addons are
available to provide data for Unicode categories, scripts, blocks, and properties via 
`XRegExp.addToken()` API.



## XRegExp.addUnicodeData(data)

Adds to the list of Unicode tokens that XRegExp regexes can match via `\p` or `\P`.

`data`
{Array} Objects with named character ranges. Each object may have properties
  `name`, `alias`, `isBmpLast`, `inverseOf`, `bmp`, and `astral`. All but `name` are
  optional, although one of `bmp` or `astral` is required (unless `inverseOf` is set). If
  `astral` is absent, the `bmp` data is used for BMP and astral modes. If `bmp` is absent,
  the name errors in BMP mode but works in astral mode. If both `bmp` and `astral` are
  provided, the `bmp` data only is used in BMP mode, and the combination of `bmp` and
  `astral` data is used in astral mode. `isBmpLast` is needed when a token matches orphan
  high surrogates *and* uses surrogate pairs to match astral code points. The `bmp` and
  `astral` data should be a combination of literal characters and `\xHH` or `\uHHHH` escape
  sequences, with hyphens to create ranges. Any regex metacharacters in the data should be
  escaped, apart from range-creating hyphens. The `astral` data can additionally use
  character classes and alternation, and should use surrogate pairs to represent astral code
  points. `inverseOf` can be used to avoid duplicating character data if a Unicode token is
  defined as the exact inverse of another token.

```js
// Basic use
XRegExp.addUnicodeData([{
  name: 'XDigit',
  alias: 'Hexadecimal',
  bmp: '0-9A-Fa-f'
}]);
XRegExp('\\p{XDigit}:\\p{Hexadecimal}+').test('0:3D'); // -> true
```





## Private / Unofficial / Unsupported APIs


### XRegExp._registeredFlags()

> 'Unofficial/Unsupported API': interface may be subject to change between any XRegExp releases; used in tests and addons; suitable for advanced users of the library only.

Returns a reference to the internal registered flags object, where each flag is a hash key:

```js
var flags = XRegExp._registeredFlags();
assert(flags['u'], 'expected native Unicode support');
```


### function setNatives(on)

> 'Unofficial/Unsupported API': interface may be subject to change between any XRegExp releases; used in tests and addons; suitable for advanced users of the library only.

Enables or disables native method overrides.

`on`
: {Boolean} `true` to enable; `false` to disable.

Used internally by the `XRegExp.install()` and `XRegExp.uninstall()` APIs; `setNatives()` is itself not accessibly externally (private function).


### XRegExp._hasNativeFlag(flag)

> 'Unofficial/Unsupported API': interface may be subject to change between any XRegExp releases; used in tests and addons; suitable for advanced users of the library only.

Check if the regex flag is supported natively in your environment.

Returns {Boolean}.

> Developer Note:
>
> Can't check based on the presence of properties/getters since browsers might support such
> properties even when they don't support the corresponding flag in regex construction (tested
> in Chrome 48, where `'unicode' in /x/` is true but trying to construct a regex with flag `u`
> throws an error)


### XRegExp._dec(hex)

> 'Unofficial/Unsupported API': interface may be subject to change between any XRegExp releases; used in tests and addons; suitable for advanced users of the library only.

Converts hexadecimal to decimal.

`hex`
: {String}

Returns {Number}



### XRegExp._hex(dec)

> 'Unofficial/Unsupported API': interface may be subject to change between any XRegExp releases; used in tests and addons; suitable for advanced users of the library only.

Converts decimal to hexadecimal.

`dec`
: {Number|String}

Returns {String}



### XRegExp._pad4(str)

> 'Unofficial/Unsupported API': interface may be subject to change between any XRegExp releases; used in tests and addons; suitable for advanced users of the library only.

Adds leading zeros if shorter than four characters. Used for fixed-length hexadecimal values.

`str`
: {String}

Returns {String}





### XRegExp._getUnicodeProperty(name)

> 'Unofficial/Unsupported API': interface may be subject to change between any XRegExp releases; used in tests and addons; suitable for advanced users of the library only.

Return a reference to the internal Unicode definition structure for the given Unicode Property
if the given name is a legal Unicode Property for use in XRegExp `\p` or `\P` regex constructs.

`name`
: {String} Name by which the Unicode Property may be recognized (case-insensitive),
  e.g. `'N'` or `'Number'`.

  The given name is matched against all registered Unicode Properties and Property Aliases.

  Token names are case insensitive, and any spaces, hyphens, and underscores are ignored.

Returns {Object} reference to definition structure when the name matches a Unicode Property;
`false` when the name does not match *any* Unicode Property or Property Alias.


#### Notes

For more info on Unicode Properties, see also http://unicode.org/reports/tr18/#Categories.

This method is *not* part of the officially documented and published API and is meant 'for
advanced use only' where userland code wishes to re-use the (large) internal Unicode
structures set up by XRegExp as a single point of Unicode 'knowledge' in the application.

See some example usage of this functionality, used as a boolean check if the given name
is legal and to obtain internal structural data:
- `function prepareMacros(...)` in https://github.com/GerHobbelt/jison-lex/blob/master/regexp-lexer.js#L885
- `function generateRegexesInitTableCode(...)` in https://github.com/GerHobbelt/jison-lex/blob/master/regexp-lexer.js#L1999

Note that the second function in the example (`function generateRegexesInitTableCode(...)`)
uses a approach without using this API to obtain a Unicode range spanning regex for use in environments
which do not support XRegExp by simply expanding the XRegExp instance to a String through
the `map()` mapping action and subsequent `join()`.







## Unicode Blocks, Categories, Properties and Scripts

XRegExp adds support for all Unicode blocks. Block names use the prefix 'In'. E.g.
`\p{InBasicLatin}`. Token names are case insensitive, and any spaces, hyphens, and
underscores are ignored.

Currently XRegExp supports the Unicode 8.0.0 block names listed below:

- `InAegean_Numbers`
- `InAhom`
- `InAlchemical_Symbols`
- `InAlphabetic_Presentation_Forms`
- `InAnatolian_Hieroglyphs`
- `InAncient_Greek_Musical_Notation`
- `InAncient_Greek_Numbers`
- `InAncient_Symbols`
- `InArabic`
- `InArabic_Extended_A`
- `InArabic_Mathematical_Alphabetic_Symbols`
- `InArabic_Presentation_Forms_A`
- `InArabic_Presentation_Forms_B`
- `InArabic_Supplement`
- `InArmenian`
- `InArrows`
- `InAvestan`
- `InBalinese`
- `InBamum`
- `InBamum_Supplement`
- `InBasic_Latin`
- `InBassa_Vah`
- `InBatak`
- `InBengali`
- `InBlock_Elements`
- `InBopomofo`
- `InBopomofo_Extended`
- `InBox_Drawing`
- `InBrahmi`
- `InBraille_Patterns`
- `InBuginese`
- `InBuhid`
- `InByzantine_Musical_Symbols`
- `InCarian`
- `InCaucasian_Albanian`
- `InChakma`
- `InCham`
- `InCherokee`
- `InCherokee_Supplement`
- `InCJK_Compatibility`
- `InCJK_Compatibility_Forms`
- `InCJK_Compatibility_Ideographs`
- `InCJK_Compatibility_Ideographs_Supplement`
- `InCJK_Radicals_Supplement`
- `InCJK_Strokes`
- `InCJK_Symbols_and_Punctuation`
- `InCJK_Unified_Ideographs`
- `InCJK_Unified_Ideographs_Extension_A`
- `InCJK_Unified_Ideographs_Extension_B`
- `InCJK_Unified_Ideographs_Extension_C`
- `InCJK_Unified_Ideographs_Extension_D`
- `InCJK_Unified_Ideographs_Extension_E`
- `InCombining_Diacritical_Marks`
- `InCombining_Diacritical_Marks_Extended`
- `InCombining_Diacritical_Marks_for_Symbols`
- `InCombining_Diacritical_Marks_Supplement`
- `InCombining_Half_Marks`
- `InCommon_Indic_Number_Forms`
- `InControl_Pictures`
- `InCoptic`
- `InCoptic_Epact_Numbers`
- `InCounting_Rod_Numerals`
- `InCuneiform`
- `InCuneiform_Numbers_and_Punctuation`
- `InCurrency_Symbols`
- `InCypriot_Syllabary`
- `InCyrillic`
- `InCyrillic_Extended_A`
- `InCyrillic_Extended_B`
- `InCyrillic_Supplement`
- `InDeseret`
- `InDevanagari`
- `InDevanagari_Extended`
- `InDingbats`
- `InDomino_Tiles`
- `InDuployan`
- `InEarly_Dynastic_Cuneiform`
- `InEgyptian_Hieroglyphs`
- `InElbasan`
- `InEmoticons`
- `InEnclosed_Alphanumeric_Supplement`
- `InEnclosed_Alphanumerics`
- `InEnclosed_CJK_Letters_and_Months`
- `InEnclosed_Ideographic_Supplement`
- `InEthiopic`
- `InEthiopic_Extended`
- `InEthiopic_Extended_A`
- `InEthiopic_Supplement`
- `InGeneral_Punctuation`
- `InGeometric_Shapes`
- `InGeometric_Shapes_Extended`
- `InGeorgian`
- `InGeorgian_Supplement`
- `InGlagolitic`
- `InGothic`
- `InGrantha`
- `InGreek_and_Coptic`
- `InGreek_Extended`
- `InGujarati`
- `InGurmukhi`
- `InHalfwidth_and_Fullwidth_Forms`
- `InHangul_Compatibility_Jamo`
- `InHangul_Jamo`
- `InHangul_Jamo_Extended_A`
- `InHangul_Jamo_Extended_B`
- `InHangul_Syllables`
- `InHanunoo`
- `InHatran`
- `InHebrew`
- `InHigh_Private_Use_Surrogates`
- `InHigh_Surrogates`
- `InHiragana`
- `InIdeographic_Description_Characters`
- `InImperial_Aramaic`
- `InInscriptional_Pahlavi`
- `InInscriptional_Parthian`
- `InIPA_Extensions`
- `InJavanese`
- `InKaithi`
- `InKana_Supplement`
- `InKanbun`
- `InKangxi_Radicals`
- `InKannada`
- `InKatakana`
- `InKatakana_Phonetic_Extensions`
- `InKayah_Li`
- `InKharoshthi`
- `InKhmer`
- `InKhmer_Symbols`
- `InKhojki`
- `InKhudawadi`
- `InLao`
- `InLatin_1_Supplement`
- `InLatin_Extended_A`
- `InLatin_Extended_Additional`
- `InLatin_Extended_B`
- `InLatin_Extended_C`
- `InLatin_Extended_D`
- `InLatin_Extended_E`
- `InLepcha`
- `InLetterlike_Symbols`
- `InLimbu`
- `InLinear_A`
- `InLinear_B_Ideograms`
- `InLinear_B_Syllabary`
- `InLisu`
- `InLow_Surrogates`
- `InLycian`
- `InLydian`
- `InMahajani`
- `InMahjong_Tiles`
- `InMalayalam`
- `InMandaic`
- `InManichaean`
- `InMathematical_Alphanumeric_Symbols`
- `InMathematical_Operators`
- `InMeetei_Mayek`
- `InMeetei_Mayek_Extensions`
- `InMende_Kikakui`
- `InMeroitic_Cursive`
- `InMeroitic_Hieroglyphs`
- `InMiao`
- `InMiscellaneous_Mathematical_Symbols_A`
- `InMiscellaneous_Mathematical_Symbols_B`
- `InMiscellaneous_Symbols`
- `InMiscellaneous_Symbols_and_Arrows`
- `InMiscellaneous_Symbols_and_Pictographs`
- `InMiscellaneous_Technical`
- `InModi`
- `InModifier_Tone_Letters`
- `InMongolian`
- `InMro`
- `InMultani`
- `InMusical_Symbols`
- `InMyanmar`
- `InMyanmar_Extended_A`
- `InMyanmar_Extended_B`
- `InNabataean`
- `InNew_Tai_Lue`
- `InNKo`
- `InNumber_Forms`
- `InOgham`
- `InOl_Chiki`
- `InOld_Hungarian`
- `InOld_Italic`
- `InOld_North_Arabian`
- `InOld_Permic`
- `InOld_Persian`
- `InOld_South_Arabian`
- `InOld_Turkic`
- `InOptical_Character_Recognition`
- `InOriya`
- `InOrnamental_Dingbats`
- `InOsmanya`
- `InPahawh_Hmong`
- `InPalmyrene`
- `InPau_Cin_Hau`
- `InPhags_pa`
- `InPhaistos_Disc`
- `InPhoenician`
- `InPhonetic_Extensions`
- `InPhonetic_Extensions_Supplement`
- `InPlaying_Cards`
- `InPrivate_Use_Area`
- `InPsalter_Pahlavi`
- `InRejang`
- `InRumi_Numeral_Symbols`
- `InRunic`
- `InSamaritan`
- `InSaurashtra`
- `InSharada`
- `InShavian`
- `InShorthand_Format_Controls`
- `InSiddham`
- `InSinhala`
- `InSinhala_Archaic_Numbers`
- `InSmall_Form_Variants`
- `InSora_Sompeng`
- `InSpacing_Modifier_Letters`
- `InSpecials`
- `InSundanese`
- `InSundanese_Supplement`
- `InSuperscripts_and_Subscripts`
- `InSupplemental_Arrows_A`
- `InSupplemental_Arrows_B`
- `InSupplemental_Arrows_C`
- `InSupplemental_Mathematical_Operators`
- `InSupplemental_Punctuation`
- `InSupplemental_Symbols_and_Pictographs`
- `InSupplementary_Private_Use_Area_A`
- `InSupplementary_Private_Use_Area_B`
- `InSutton_SignWriting`
- `InSyloti_Nagri`
- `InSyriac`
- `InTagalog`
- `InTagbanwa`
- `InTags`
- `InTai_Le`
- `InTai_Tham`
- `InTai_Viet`
- `InTai_Xuan_Jing_Symbols`
- `InTakri`
- `InTamil`
- `InTelugu`
- `InThaana`
- `InThai`
- `InTibetan`
- `InTifinagh`
- `InTirhuta`
- `InTransport_and_Map_Symbols`
- `InUgaritic`
- `InUnified_Canadian_Aboriginal_Syllabics`
- `InUnified_Canadian_Aboriginal_Syllabics_Extended`
- `InVai`
- `InVariation_Selectors`
- `InVariation_Selectors_Supplement`
- `InVedic_Extensions`
- `InVertical_Forms`
- `InWarang_Citi`
- `InYi_Radicals`
- `InYi_Syllables`
- `InYijing_Hexagram_Symbols`

XRegExp adds support for Unicode's general categories. E.g., `\p{Lu}` or `\p{Uppercase Letter}`. See
category descriptions in UAX #44 <http://unicode.org/reports/tr44/#GC_Values_Table>. Token
names are case insensitive, and any spaces, hyphens, and underscores are ignored.

Currently XRegExp supports the Unicode 8.0.0 category names listed below:

- `Close_Punctuation`
- `Connector_Punctuation`
- `Control`
- `Currency_Symbol`
- `Dash_Punctuation`
- `Decimal_Number`
- `Enclosing_Mark`
- `Final_Punctuation`
- `Format`
- `Initial_Punctuation`
- `Letter`
- `Letter_Number`
- `Line_Separator`
- `Lowercase_Letter`
- `Mark`
- `Math_Symbol`
- `Modifier_Letter`
- `Modifier_Symbol`
- `Nonspacing_Mark`
- `Number`
- `Open_Punctuation`
- `Other`
- `Other_Letter`
- `Other_Number`
- `Other_Punctuation`
- `Other_Symbol`
- `Paragraph_Separator`
- `Private_Use`
- `Punctuation`
- `Separator`
- `Space_Separator`
- `Spacing_Mark`
- `Surrogate`
- `Symbol`
- `Titlecase_Letter`
- `Unassigned`
- `Uppercase_Letter`
- `C`
- `Cc`
- `Cf`
- `Cn`
- `Co`
- `Cs`
- `L`
- `Ll`
- `Lm`
- `Lo`
- `Lt`
- `Lu`
- `M`
- `Mc`
- `Me`
- `Mn`
- `N`
- `Nd`
- `Nl`
- `No`
- `P`
- `Pc`
- `Pd`
- `Pe`
- `Pf`
- `Pi`
- `Po`
- `Ps`
- `S`
- `Sc`
- `Sk`
- `Sm`
- `So`
- `Z`
- `Zl`
- `Zp`
- `Zs`

XRegExp adds properties to meet the UTS #18 Level 1 RL1.2 requirements for Unicode regex support. See
<http://unicode.org/reports/tr18/#RL1.2>. Following are definitions of these properties from
UAX #44 <http://unicode.org/reports/tr44/>:

- `Alphabetic`

  Characters with the Alphabetic property. Generated from: `Lowercase + Uppercase + Lt + Lm +
  Lo + Nl + Other_Alphabetic`.

- `Default_Ignorable_Code_Point`

  For programmatic determination of default ignorable code points. New characters that should
  be ignored in rendering (unless explicitly supported) will be assigned in these ranges,
  permitting programs to correctly handle the default rendering of such characters when not
  otherwise supported.
 
- `Lowercase`

  Characters with the Lowercase property. Generated from: `Ll + Other_Lowercase`.
 
- `Noncharacter_Code_Point`

  Code points permanently reserved for internal use.

- `Uppercase`

  Characters with the Uppercase property. Generated from: `Lu + Other_Uppercase`.

- `White_Space`

  Spaces, separator characters and other control characters which should be treated by
  programming languages as "white space" for the purpose of parsing elements.
 
The properties `ASCII`, `Any`, and `Assigned` are also included but are not defined in UAX #44. 
UTS #18 RL1.2 additionally requires support for Unicode scripts and general categories. These are
included in XRegExp's Unicode Categories and Unicode Scripts addons.
 
Token names are case insensitive, and any spaces, hyphens, and underscores are ignored.

Currently XRegExp supports the Unicode 8.0.0 property names listed below:

- `Alphabetic`
- `Any`
- `ASCII`
- `Default_Ignorable_Code_Point`
- `Lowercase`
- `Noncharacter_Code_Point`
- `Uppercase`
- `White_Space`

Next to these, this property name is available as well:

- `Assigned`

  This is defined as the inverse of Unicode category `Cn` (`Unassigned`)


XRegExp adds support for all Unicode scripts. E.g., `\p{Latin}`. Token names are case insensitive,
and any spaces, hyphens, and underscores are ignored.

Currently XRegExp supports the Unicode 8.0.0 script names listed below:

- `Ahom`
- `Anatolian_Hieroglyphs`
- `Arabic`
- `Armenian`
- `Avestan`
- `Balinese`
- `Bamum`
- `Bassa_Vah`
- `Batak`
- `Bengali`
- `Bopomofo`
- `Brahmi`
- `Braille`
- `Buginese`
- `Buhid`
- `Canadian_Aboriginal`
- `Carian`
- `Caucasian_Albanian`
- `Chakma`
- `Cham`
- `Cherokee`
- `Common`
- `Coptic`
- `Cuneiform`
- `Cypriot`
- `Cyrillic`
- `Deseret`
- `Devanagari`
- `Duployan`
- `Egyptian_Hieroglyphs`
- `Elbasan`
- `Ethiopic`
- `Georgian`
- `Glagolitic`
- `Gothic`
- `Grantha`
- `Greek`
- `Gujarati`
- `Gurmukhi`
- `Han`
- `Hangul`
- `Hanunoo`
- `Hatran`
- `Hebrew`
- `Hiragana`
- `Imperial_Aramaic`
- `Inherited`
- `Inscriptional_Pahlavi`
- `Inscriptional_Parthian`
- `Javanese`
- `Kaithi`
- `Kannada`
- `Katakana`
- `Kayah_Li`
- `Kharoshthi`
- `Khmer`
- `Khojki`
- `Khudawadi`
- `Lao`
- `Latin`
- `Lepcha`
- `Limbu`
- `Linear_A`
- `Linear_B`
- `Lisu`
- `Lycian`
- `Lydian`
- `Mahajani`
- `Malayalam`
- `Mandaic`
- `Manichaean`
- `Meetei_Mayek`
- `Mende_Kikakui`
- `Meroitic_Cursive`
- `Meroitic_Hieroglyphs`
- `Miao`
- `Modi`
- `Mongolian`
- `Mro`
- `Multani`
- `Myanmar`
- `Nabataean`
- `New_Tai_Lue`
- `Nko`
- `Ogham`
- `Ol_Chiki`
- `Old_Hungarian`
- `Old_Italic`
- `Old_North_Arabian`
- `Old_Permic`
- `Old_Persian`
- `Old_South_Arabian`
- `Old_Turkic`
- `Oriya`
- `Osmanya`
- `Pahawh_Hmong`
- `Palmyrene`
- `Pau_Cin_Hau`
- `Phags_Pa`
- `Phoenician`
- `Psalter_Pahlavi`
- `Rejang`
- `Runic`
- `Samaritan`
- `Saurashtra`
- `Sharada`
- `Shavian`
- `Siddham`
- `SignWriting`
- `Sinhala`
- `Sora_Sompeng`
- `Sundanese`
- `Syloti_Nagri`
- `Syriac`
- `Tagalog`
- `Tagbanwa`
- `Tai_Le`
- `Tai_Tham`
- `Tai_Viet`
- `Takri`
- `Tamil`
- `Telugu`
- `Thaana`
- `Thai`
- `Tibetan`
- `Tifinagh`
- `Tirhuta`
- `Ugaritic`
- `Vai`
- `Warang_Citi`
- `Yi`

Additional token names may be defined via the `XRegExp.addUnicodeData(unicodeData)` API.

 



## Info for XRegExp Developers

To regenerate the `xregexp-all.js` source file you can simply run the command

```bash
npm run build
```

in the base directory of the repository.

