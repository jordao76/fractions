import katex from 'katex';
import 'katex/dist/katex.min.css';
import './styles.css';
import calculator from './calculator.js';

const $calculator = document.getElementById('calculator');
const $output = document.getElementById('output');
const $decimal = document.getElementById('decimal');
const $backspace = document.getElementById('backspace');
const $buttons = document.querySelectorAll('.btn');

function adjustParens(n) {
  if (n === 0) return;
  const spans = $output.querySelectorAll('.katex .mclose');
  const closingParens = Array.from(spans).filter((s) => s.textContent === ')');
  closingParens.slice(-n).forEach((el) => el.classList.add('dimmed'));
}

function getPlaceholders() {
  return Array.from($output.querySelectorAll('.katex span')).filter(
    (s) => s.textContent === '\u2218' // ∘ (\circ in TeX)
  );
}

function adjustPlaceholders() {
  getPlaceholders().forEach((el) => el.classList.add('dimmed'));
}

function adjustFraction() {
  const placeholders = getPlaceholders();
  if (placeholders.length === 0) return;
  const last = placeholders[placeholders.length - 1];
  // Walk up to the fraction container (.frac-line's parent)
  let frac = last.closest('.mfrac');
  if (frac) {
    frac.classList.add('dimmed');
    // Un-dim numeric children so only placeholder parts are dimmed
    frac.querySelectorAll('span').forEach((s) => {
      if (s.textContent.match(/\d+/)) {
        s.style.color = '#ece2d0';
      }
    });
  }
}

function output(tex, info) {
  $decimal.classList.remove('error');
  $decimal.textContent = info?.decimal != null ? info.decimal : '';
  if (tex === '') {
    $output.innerHTML = '';
    return;
  }
  try {
    katex.render(tex, $output, { displayMode: true, throwOnError: false });
  } catch (_e) {
    $output.textContent = tex;
  }
  // Remove default margin on katex display
  const katexDisplay = $output.querySelector('.katex-display');
  if (katexDisplay) {
    katexDisplay.style.margin = '0';
    katexDisplay.style.textAlign = 'right';
  }
  adjustParens(info?.incomplete?.parens || 0);
  if (info?.incomplete?.symbols > 0) {
    adjustFraction();
  } else {
    adjustPlaceholders();
  }
  // Scroll right all the way
  $output.scrollLeft = $output.scrollWidth;
}

const calc = calculator({
  output,
  onError: (s) => {
    $decimal.textContent = s;
    $decimal.classList.add('error');
  },
});

function getKey(btn) {
  return btn.dataset.symbol || btn.textContent;
}

// Collect valid key char codes
const validKeys = new Set();
$buttons.forEach((btn) => {
  validKeys.add(getKey(btn));
});

function toggleButtons() {
  $buttons.forEach((btn) => {
    if (calc.canInput(getKey(btn))) {
      btn.removeAttribute('disabled');
    } else {
      btn.setAttribute('disabled', 'disabled');
    }
  });
  if (calc.canUninput()) {
    $backspace.removeAttribute('disabled');
  } else {
    $backspace.setAttribute('disabled', 'disabled');
  }
}

$calculator.addEventListener('keydown', (e) => {
  if (e.key === 'Backspace') {
    calc.uninput();
    toggleButtons();
    e.preventDefault();
    return;
  }
  if (e.key === 'Enter') {
    calc.input('=');
    toggleButtons();
    return;
  }
  const key = e.key.toUpperCase();
  if (validKeys.has(key)) {
    calc.input(key);
    toggleButtons();
  }
});

$buttons.forEach((btn) => {
  btn.addEventListener('click', () => {
    calc.input(getKey(btn));
    toggleButtons();
  });
});

toggleButtons();
$calculator.focus();

// Backspace button click
$backspace.addEventListener('click', () => {
  calc.uninput();
  toggleButtons();
});

// Swipe left on the display to delete last character
let swipeStartX = 0, swipeStartY = 0;
$output.addEventListener('touchstart', (e) => {
  swipeStartX = e.touches[0].clientX;
  swipeStartY = e.touches[0].clientY;
}, { passive: true });
$output.addEventListener('touchend', (e) => {
  const dx = e.changedTouches[0].clientX - swipeStartX;
  const dy = e.changedTouches[0].clientY - swipeStartY;
  if (dx < -40 && Math.abs(dx) > Math.abs(dy)) {
    calc.uninput();
    toggleButtons();
  }
}, { passive: true });

// Render KaTeX fraction labels into the fraction buttons
katex.render('\\dfrac{x}{y}', document.querySelector('[data-symbol="/"]'), { throwOnError: false });
katex.render('w\\,\\dfrac{x}{y}', document.querySelector('[data-symbol=" "]'), { throwOnError: false });
