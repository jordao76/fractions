import { Fraction } from './fractions.js';
import { parse as pegParse } from './fractions-peg-parser.js';

function parse(exp) {
  try {
    return pegParse(exp);
  } catch (error) {
    return tryParseAsIncompleteExpression(exp, error);
  }
}

function tryParseAsIncompleteExpression(exp, error) {
  function replaceNumberWithMissing(ast) {
    function recur(o) {
      if (o.arg) {
        if (o.arg.length) {
          if (o.arg[o.arg.length - 1].type === 'missing') {
            return recur(o.arg[o.arg.length - 2]);
          } else {
            return recur(o.arg[o.arg.length - 1]);
          }
        } else if (o.type !== 'num') {
          return recur(o.arg);
        }
      }
      return o;
    }
    const last = recur(ast);
    if (last.arg === -1) {
      last.type = 'minus';
      last.arg = { type: 'missing' };
    } else {
      last.type = 'missing';
      delete last.arg;
    }
  }

  let newExp = exp;
  let symbolsAdded = 0;
  let numbersAdded = 0;

  if (exp.match(/[^\d)\s]+$/)) {
    newExp += '1';
    ++numbersAdded;
  } else if (exp.match(/\s\d+$/)) {
    newExp += '/1';
    ++symbolsAdded;
    ++numbersAdded;
  } else if (exp.match(/\s$/)) {
    newExp += '1/1';
    ++symbolsAdded;
    numbersAdded += 2;
  }

  let openParens = (exp.match(/\(/g) || []).length;
  const closeParens = (exp.match(/\)/g) || []).length;
  const parensAdded = openParens - closeParens;
  while (openParens-- > closeParens) {
    newExp += ')';
  }

  if (exp !== newExp) {
    try {
      const ast = pegParse(newExp);
      if (parensAdded > 0 || symbolsAdded > 0 || numbersAdded > 0) {
        ast.incomplete = {};
        if (parensAdded > 0) ast.incomplete.parens = parensAdded;
        if (symbolsAdded > 0) ast.incomplete.symbols = symbolsAdded;
        if (numbersAdded > 0) ast.incomplete.numbers = numbersAdded;
        let n = numbersAdded;
        while (n-- > 0) {
          replaceNumberWithMissing(ast);
        }
      }
      return ast;
    } catch (_e) {
      // fall through
    }
  }

  return { error: error.message };
}

function interpret(ast, interpreter) {
  if (!ast) return null;
  if (ast.error != null) return interpreter.error(ast.error);
  const map = (o, f) => (o.map ? o.map(f) : f(o));
  function recur(o) {
    if (o.type === 'num' || o.type === 'missing') {
      return interpreter[o.type](o.arg);
    } else {
      return interpreter[o.type](map(o.arg, recur));
    }
  }
  return interpreter.post(recur(ast));
}

function calc(ast) {
  if (ast.incomplete?.numbers) {
    return { error: 'incomplete expression' };
  }
  try {
    const f = Fraction;
    return interpret(ast, {
      error: () => '',
      num: (n) => f.create(n),
      add: (a) => a.reduce((p, e) => f.add(p, e)),
      minus: (e) => f.minus(e),
      mul: (a) => a.reduce((p, e) => f.mul(p, e)),
      div: (e) => f.reciprocal(e),
      mixed: (a) => {
        const [w, n, d] = a.map((e) => e.n);
        return f.mixed(w, n, d);
      },
      over: (a) => {
        const [n, d] = a.map((e) => e.n);
        return f.create(n, d);
      },
      exp: (e) => e,
      post: (r) => r,
    });
  } catch (e) {
    return { error: e.message };
  }
}

function render(ast, options) {
  function withResult(s) {
    const result = calc(ast);
    if (result.error) return { error: result.error };
    const r = render(parse(result.toString()));
    const m = render(parse(result.toMixedString()));
    let ret = s;
    if (!r.error && s !== r) ret += ` = ${r}`;
    if (!m.error && m !== r && m !== s) ret += ` = ${m}`;
    return ret;
  }

  return interpret(ast, {
    error: (e) => ({ error: e }),
    missing: () => '',
    num: (n) => `${n}`,
    add: (a) => a.reduce((p, e) => `${p} + ${e}`),
    minus: (e) => `-${e}`,
    mul: (a) => a.reduce((p, e) => `${p} \\times ${e}`),
    div: (e) => `\\div ${e}`,
    mixed: (a) => {
      const [w, n, d] = a;
      return `${w} \\frac{${n || '\\circ'}}{${d || '\\circ'}}`;
    },
    over: (a) => {
      const [n, d] = a;
      return d != null ? `\\frac{${n}}{${d || '\\circ'}}` : n;
    },
    exp: (e) => `\\left( ${e} \\right)`,
    post: (s) => {
      let result = s
        .replace(/\\times \\div/g, '\\div')
        .replace(/\+(\s)?-/g, '-$1')
        .replace(/-(\s)?-/g, '+$1')
        .replace(/\s{2,}/g, ' ');
      if (options?.result) {
        return withResult(result);
      }
      return result;
    },
  });
}

class Parsed {
  constructor(ast) {
    this.ast = ast;
  }
  calc() {
    return calc(this.ast);
  }
  render(options) {
    return render(this.ast, options);
  }
}

export default {
  parse: (e) => new Parsed(parse(e)),
};
