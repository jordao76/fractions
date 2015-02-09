module.exports = (function(fraction, parser){
'use strict';

var parse = function(exp) {
  try {
    return parser.parse(exp);
  } catch(e) {
    // try to create a valid expression

    // trim trailing non-numbers
    var newExp = exp.replace(/\D+$/, '');

    // balance close parenthesis
    var openParens = (newExp.match(/\(/g)||{length:0}).length;
    var closeParens = (newExp.match(/\)/g)||{length:0}).length;
    while (openParens-- > closeParens) { newExp += ")"; }

    if (exp !== newExp) {
      return parse(newExp);
    }
    else {
      return window.partial || { error:e.message };
    }
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
      nil:function(){return ''},
      error:function(){return ''},
      num:function(n){return f.create(n)},
      add:function(a,recur){return a.map(recur).reduce(function(p,e){return f.add(p,e);});},
      minus:function(e,recur){return f.minus(recur(e));},
      mul:function(a,recur){return a.map(recur).reduce(function(p,e){return f.mul(p,e);});},
      over:function(a,recur){
        if (a.length===2) return f.div(recur(a[0]),recur(a[1]));
        // do pair-wise association, e.g. "1 / 2 / 3 / 4 / 5" => "(1 / 2) / (3 / 4) / 5"
        var pairs = a.map(recur).reduce(
          function(p,e){
            var last = p[p.length-1]; 
            if (last.length < 2) last.push(e); else p.push([e]);
            return p;
          },[[]]
        );
        return pairs.
          map(function(e){return f.div(e[0],e[1]||f.create(1));}).
          reduce(function(p,e){return f.div(p,e);});
      },
      exp:function(e,recur){return recur(e);},
      post:function(r){return f.toString(r);}
    });
  } catch(e) {
    return { error: e.message };
  }
};

// render AST as AsciiMath
var render = function(ast, result) {
  var rendered = interpret(ast, {
    nil:function(){return ''},
    error:function(err){return 'bb"Error"'},
    num:function(n){return ''+n},
    add:function(a,recur){return a.map(recur).reduce(function(p,e){return p+"+"+e;});},
    minus:function(e,recur){return "-"+recur(e);},
    mul:function(a,recur){return a.map(recur).reduce(function(p,e){return p+"xx"+e;});},
    over:function(a,recur){
      // do pair-wise association, e.g. "1 / 2 / 3 / 4 / 5" => "(1 / 2) -: (3 / 4) -: 5"
      var curr = '', op = function(){return curr=curr==='/'?'-:':'/';};
      return a.map(recur).reduce(function(p,e){return p+op()+e;});
    },
    exp:function(e,recur){return "("+recur(e)+")";},
    post:function(s){return s.replace(/\+-/g,'-').replace(/--/g,'+');}
  });
  if (result) {
    if (result.error) { rendered += ' = bb"' + result.error + '"'; }
    else { rendered += ' = ' + result; }
  }
  return rendered;
};

return {
  parse : parse,
  calc : calc,
  render : render
};

}(require('./fractions'), require('./fractions-parser')));
