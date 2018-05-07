/*!
 * XRegExp-All
 * <xregexp.com>
 * Steven Levithan (c) 2012-present MIT License
 */

// Module systems magic dance
// Don't use strict mode for this function, so it can assign to global
(function(root, definition) {
    // RequireJS
    if (typeof define === 'function' && define.amd) {
        define(definition);
    // CommonJS
    } else if (typeof exports === 'object') {
        var self = definition();
        // Use Node.js's `module.exports`. This supports `require('xregexp')`.
        if (typeof module === 'object') {
            module.exports = self;
        } else {
            exports.XRegExp = self;
        }
    // <script>
    } else {
        // Create global
        root.XRegExp = definition();
    }
}(this, function() {
    "use strict";
