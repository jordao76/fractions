function gcd(n, d) {
  let r;
  while (d !== 0) {
    r = n % d;
    n = d;
    d = r;
  }
  return Math.abs(n);
}

const div0 = new Error('Division by zero!');

export class Fraction {
  constructor(n, d = 1) {
    if (d === 0) throw div0;
    if (d < 0) { n = -n; d = -d; }
    const div = gcd(n, d);
    this.n = n / div;
    this.d = d / div;
  }

  isProper() {
    return Math.abs(this.n) < this.d;
  }

  toFloat() {
    return this.n / this.d;
  }

  toString() {
    return this.d === 1 ? `${this.n}` : `${this.n}/${this.d}`;
  }

  toMixedString() {
    if (this.isProper()) {
      return this.toString();
    } else if (this.n % this.d === 0) {
      return `${Math.trunc(this.n / this.d)}`;
    } else {
      return `${Math.trunc(this.n / this.d)} ${Math.abs(this.n % this.d)}/${this.d}`;
    }
  }

  static create(n, d) {
    return new Fraction(n, d);
  }

  static mixed(w, n, d) {
    // For negative whole parts, -2 1/3 means -(2 + 1/3) = -7/3, not (-2*3+1)/3 = -5/3
    const sign = w < 0 ? -1 : 1;
    return this.create(sign * (Math.abs(w) * d + n), d);
  }

  static add(l, r) {
    const [a, b, c, d] = [l.n, l.d, r.n, r.d];
    return this.create(a * d + c * b, b * d);
  }

  static minus(f) {
    return this.create(-f.n, f.d);
  }

  static mul(l, r) {
    const [a, b, c, d] = [l.n, l.d, r.n, r.d];
    return this.create(a * c, b * d);
  }

  static div(l, r) {
    const [a, b, c, d] = [l.n, l.d, r.n, r.d];
    return this.create(a * d, b * c);
  }

  static reciprocal(f) {
    return this.create(f.d, f.n);
  }
}
