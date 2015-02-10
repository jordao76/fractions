/* global module */
module.exports = (function(){
'use strict';

// fractions are represented as an array of 2 elements, e.g. 1/3 is [1,3]

var gcd = function(n, d) {
  var remainder = 0;
  while (d !== 0) {
    remainder = n % d;
    n = d;
    d = remainder;
  }
  return n;
};

var fraction = function(f) {
  var d = gcd(f[0], f[1]);
  var result = [f[0]/d, f[1]/d];
  result.toFloat = function() {
    return this[0]/this[1];
  };
  result.toString = function() {
    return this[1]===1?(''+this[0]):(this[0]+'/'+this[1]);
  };
  return result;
};

var div0 = new Error('Division by zero!');

return {
  create: function(n, d) {
    if (d===0) throw div0;
    return fraction([n, d||1]);
  },
  add: function(l, r) {
    var a=l[0],b=l[1],c=r[0],d=r[1];
    return fraction([a*d + c*b, b*d]);
  },
  minus: function(f) {
    var n=f[0],d=f[1];
    return fraction([-n, d]);
  },
  mul: function(l, r) {
    var a=l[0],b=l[1],c=r[0],d=r[1];
    return fraction([a*c, b*d]);
  },
  div: function(l, r) {
    var a=l[0],b=l[1],c=r[0],d=r[1];
    if (c===0) throw div0;
    return fraction([a*d, b*c]);
  }
};

}());
