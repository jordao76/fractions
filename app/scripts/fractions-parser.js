/* global module,require */
module.exports = (function(fraction, parser){
'use strict';

var parse = function(exp, error) {
  try {
    var ast = parser.parse(exp);
    if (error && error.missingNumber) {
      // replace last number with a 'missing' type
      var recur = function(o){
        if (o.arg) {
          if (o.arg.length) {
            return recur(o.arg[o.arg.length-1]);
          }
          else if (o.type !== 'num') {
            return recur(o.arg);
          }
        }
        return o;
      };
      var last = recur(ast);
      if (last.arg === -1) {
        last.type = 'minus';
        last.arg = { type: 'missing' };
      }
      else {
        last.type = 'missing';
        delete last.arg;
      }
    }
    return ast;
  } catch(e) {
    // try to create a valid expression
    var newExp = exp;

    // if it ends with a non-number, see if adding a number works
    if (newExp.match(/\D+$/)) {
      newExp += '1';
      e.missingNumber = true;
    }

    // balance close parenthesis
    var openParens = (newExp.match(/\(/g)||[]).length;
    var closeParens = (newExp.match(/\)/g)||[]).length;
    while (openParens-- > closeParens) { newExp += ')'; }

    if (exp !== newExp) {
      return parse(newExp, e);
    }
    return { error:e.message };
  }
};

var interpret = function(ast, interpreter) {
  if (!ast) return interpreter.nil();
  if (ast.error) return interpreter.error(ast.error);
  var recur = function(o){return interpreter[o.type](o.arg,recur);};
  return interpreter.post(recur(ast));
};

// calculate AST result
var calc = function(ast) {
  try {
    var f = fraction;
    return interpret(ast, {
      missing:function(){throw new Error('incomplete expression');}, // TODO: put string in a variable!
      nil:function(){return '';},
      error:function(){return '';},
      num:function(n){return f.create(n);},
      add:function(a,recur){return a.map(recur).reduce(function(p,e){return f.add(p,e);});},
      minus:function(e,recur){return f.minus(recur(e));},
      mul:function(a,recur){return a.map(recur).reduce(function(p,e){return f.mul(p,e);});},
      over:function(a,recur){
        if (a.length===2) return f.div(recur(a[0]),recur(a[1]));
        // do pair-wise association, e.g. "1 / 2 / 3 / 4 / 5" => "(1 / 2) / (3 / 4) / 5"
        var pairs = a.map(recur).reduce(
          function(p,e){
            var last = p[p.length-1];
            if (last.length < 2) { last.push(e); } else { p.push([e]); }
            return p;
          },[[]]
        );
        return pairs.
          map(function(e){return f.div(e[0],e[1]||f.create(1));}).
          reduce(function(p,e){return f.div(p,e);});
      },
      exp:function(e,recur){return recur(e);},
      post:function(r){return r;}
    });
  } catch(e) {
    return { error: e.message };
  }
};

// render AST as AsciiMath
var placeholder = '';
var render = function(ast, result) {
  var rendered = interpret(ast, {
    missing:function(){return placeholder;},
    nil:function(){return '';},
    error:function(){return 'bb"Error"';},
    num:function(n){return ''+n;},
    add:function(a,recur){return a.map(recur).reduce(function(p,e){return p+'+'+e;});},
    minus:function(e,recur){return '-'+recur(e);},
    mul:function(a,recur){return a.map(recur).reduce(function(p,e){return p+'xx'+e;});},
    over:function(a,recur){
      // do pair-wise association, e.g. "1 / 2 / 3 / 4 / 5" => "(1 / 2) -: (3 / 4) -: 5"
      var curr = '', op = function(){return curr=(curr==='/'?'-:':'/');};
      return a.map(recur).reduce(function(p,e){return p+op()+e;});
    },
    exp:function(e,recur){return '('+recur(e)+')';},
    post:function(s){return s.replace(/\+-/g,'-').replace(/--/g,'+');}
  });
  if (result) {
    if (result.error) { rendered += ' = bb"' + result.error + '"'; }
    else { rendered += ' = ' + result; }
  }
  return rendered;
};

var Parsed = function(ast){
  this.ast = ast;
};
Parsed.prototype = {
  calc: function(){return calc(this.ast);},
  render: function(result){return render(this.ast, result);}
};

return {
  parse: function(e){return new Parsed(parse(e));},
  placeholder: placeholder // TODO: rename?
};

}(require('./fractions'), require('./fractions-peg-parser')));
