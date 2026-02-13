import Parser from './fractions-parser.js';

export default function calculator(options) {
  const { output, onError } = options;

  const $input = {
    curr: '',
    isRes: false,
    val(v, r = false) {
      if (v != null) {
        this.curr = v;
        this.isRes = r;
      }
      return this.curr;
    },
    hasResult() {
      return this.isRes;
    },
  };

  function canInput(key) {
    if (key === 'C') return true;
    if (key === '=') {
      const exp = $input.val();
      const parsed = Parser.parse(exp);
      return !parsed.ast.error && !parsed.ast.incomplete?.numbers;
    }
    const exp = $input.val() + key;
    if (!exp) return true;
    const parsed = Parser.parse(exp);
    return !parsed.ast.error;
  }

  function input(key) {
    if (key === 'C') $input.val(key = '');
    if (key === '=') {
      calc();
    } else {
      if ($input.hasResult() && key.match(/\d/)) {
        $input.val(key);
      } else {
        $input.val($input.val() + key);
      }
      process();
    }
  }

  function uninput() {
    if ($input.hasResult()) return clear();
    const value = $input.val();
    $input.val(value.slice(0, -1));
    process();
  }

  function clear() {
    output('');
  }

  function process() {
    const exp = $input.val();
    if (!exp.trim()) return clear();
    const parsed = Parser.parse(exp);
    if (parsed.ast.error != null) {
      uninput();
    } else {
      const info = parsed.ast.incomplete ? { incomplete: parsed.ast.incomplete } : undefined;
      output(parsed.render(), info);
    }
  }

  function calc() {
    const exp = $input.val();
    if (!exp.trim()) return clear();
    const parsed = Parser.parse(exp);
    if (parsed.ast.incomplete?.numbers > 0) return;
    const rendered = parsed.render({ result: true });
    if (!rendered.error) {
      const result = parsed.calc();
      output(rendered, { decimal: result.toFloat() });
      $input.val(result.toString(), true);
    } else {
      onError(rendered.error);
    }
  }

  clear();

  return { canInput, input, uninput };
}
