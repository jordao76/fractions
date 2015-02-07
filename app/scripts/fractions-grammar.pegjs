{
  window.partial = null;
  function p(o){return window.partial=o;}

  function num(n){return p({type:'num',arg:n});}
  function add(a){return p({type:'add',arg:a});}
  function mul(a){return p({type:'mul',arg:a});}
  function over(a){return p({type:'over',arg:a});}
  function exp(e){return p({type:'exp',arg:e});}

  function minus(e){return {type:"minus",arg:e};}

  function terms(a){return a.map(function(e){return e[0]==="-"?minus(e[1]):e[1];});}
}

S
  = E

E "expression"
  = left:T right:(("+"/"-") T)+ { return add([left].concat(terms(right))); }
  / T

T "term"
  = left:F right:("*" F)+ { return mul([left].concat(terms(right))); }
  / F

F "fraction"
  = left:R right:("/" R)+ { return over([left].concat(terms(right))); }
  / R

R "factor"
  = I
  / sign:("-"/"+")? "(" expression:E ")" { 
    var r = exp(expression);
    return sign==='-'?minus(r):r; 
  }

I "integer"
  = sign:("-"/"+")? digits:[0-9]+ { return num(parseInt((sign||"")+digits.join(""), 10)); }
