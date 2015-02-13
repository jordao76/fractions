/* global module */
module.exports = (function(){
'use strict';

var gcd = function(n, d) {
  var remainder = 0;
  while (d !== 0) {
    remainder = n % d;
    n = d;
    d = remainder;
  }
  return Math.abs(n);
};

var div0 = new Error('Division by zero!');

var Fraction = function(n, d) {
  if (d === 0) throw div0;
  d = d || 1;
  if (d < 0) {
    n = -n;
    d = -d;
  }
  var div = gcd(n, d);
  this.n = n / div;
  this.d = d / div;
};

var fraction = function(n, d) { return new Fraction(n, d); };

Fraction.create = function(n, d) {
  return fraction(n, d);
};
Fraction.add = function(l, r) {
  var a=l.n,b=l.d,c=r.n,d=r.d;
  return fraction(a*d + c*b, b*d);
};
Fraction.minus = function(f) {
  var n=f.n,d=f.d;
  return fraction(-n, d);
};
Fraction.mul = function(l, r) {
  var a=l.n,b=l.d,c=r.n,d=r.d;
  return fraction(a*c, b*d);
};
Fraction.div = function(l, r) {
  var a=l.n,b=l.d,c=r.n,d=r.d;
  return fraction(a*d, b*c);
};
Fraction.prototype = {
  toFloat:  function() { return this.n/this.d; },
  toString: function() { return this.d===1?(''+this.n):(this.n+'/'+this.d); }
};

return Fraction;

}());
