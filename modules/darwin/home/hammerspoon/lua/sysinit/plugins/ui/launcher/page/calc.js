// Arithmetic typed into the search field. Parsed rather than evaluated: the
// panel takes whatever the field holds, and handing that to a JS evaluator
// would run it. A parser can only ever return a number.

const CONSTANTS = {
  pi: Math.PI,
  tau: Math.PI * 2,
  e: Math.E,
  phi: (1 + Math.sqrt(5)) / 2,
};

const FUNCTIONS = {
  sqrt: { arity: 1, apply: Math.sqrt },
  cbrt: { arity: 1, apply: Math.cbrt },
  abs: { arity: 1, apply: Math.abs },
  floor: { arity: 1, apply: Math.floor },
  ceil: { arity: 1, apply: Math.ceil },
  round: { arity: 1, apply: Math.round },
  trunc: { arity: 1, apply: Math.trunc },
  sign: { arity: 1, apply: Math.sign },
  ln: { arity: 1, apply: Math.log },
  log: { arity: 1, apply: Math.log10 },
  log2: { arity: 1, apply: Math.log2 },
  exp: { arity: 1, apply: Math.exp },
  sin: { arity: 1, apply: Math.sin },
  cos: { arity: 1, apply: Math.cos },
  tan: { arity: 1, apply: Math.tan },
  asin: { arity: 1, apply: Math.asin },
  acos: { arity: 1, apply: Math.acos },
  atan: { arity: 1, apply: Math.atan },
  min: { arity: 2, apply: Math.min },
  max: { arity: 2, apply: Math.max },
};

function tokenize(text) {
  const out = [];
  let i = 0;
  while (i < text.length) {
    const c = text[i];
    if (c === " " || c === "\t" || c === ",") {
      // A comma is a separator between arguments and also how a person writes a
      // thousand, and both read the same to a parser that ignores it.
      i += 1;
      continue;
    }
    if (c >= "0" && c <= "9") {
      const hex = /^0[xX][0-9a-fA-F]+/.exec(text.slice(i));
      if (hex) {
        out.push({ kind: "num", value: parseInt(hex[0], 16) });
        i += hex[0].length;
        continue;
      }
      const bin = /^0[bB][01]+/.exec(text.slice(i));
      if (bin) {
        out.push({ kind: "num", value: parseInt(bin[0].slice(2), 2) });
        i += bin[0].length;
        continue;
      }
      // Before the plain form, because a person writes a large number the way
      // this panel prints one back.
      const grouped = /^\d{1,3}(,\d{3})+(\.\d+)?/.exec(text.slice(i));
      if (grouped) {
        out.push({ kind: "num", value: Number(grouped[0].replace(/,/g, "")) });
        i += grouped[0].length;
        continue;
      }
      const dec = /^\d[\d_]*(\.\d[\d_]*)?([eE][+-]?\d+)?/.exec(text.slice(i));
      if (dec === null) {
        return null;
      }
      out.push({ kind: "num", value: Number(dec[0].replace(/_/g, "")) });
      i += dec[0].length;
      continue;
    }
    if (c === ".") {
      const dec = /^\.\d+([eE][+-]?\d+)?/.exec(text.slice(i));
      if (dec === null) {
        return null;
      }
      out.push({ kind: "num", value: Number(dec[0]) });
      i += dec[0].length;
      continue;
    }
    const word = /^[A-Za-z][A-Za-z0-9]*/.exec(text.slice(i));
    if (word) {
      out.push({ kind: "word", value: word[0].toLowerCase() });
      i += word[0].length;
      continue;
    }
    if (text.startsWith("**", i)) {
      out.push({ kind: "op", value: "^" });
      i += 2;
      continue;
    }
    if ("+-*/%^()".indexOf(c) >= 0) {
      out.push({ kind: "op", value: c });
      i += 1;
      continue;
    }
    return null;
  }
  return out;
}

// A percent is carried rather than collapsed to a fraction, because what it
// means depends on what it is next to: "200 + 10%" is 220, and "10% of 200" is
// 20, but a bare "10%" is 0.1.
function plain(value) {
  return value.percent === true ? value.number / 100 : value.number;
}

function parse(tokens) {
  let at = 0;
  // Anything the grammar does not accept throws, and the caller shows no row
  // rather than a wrong one.
  const fail = () => {
    throw new Error("parse");
  };

  const peek = () => (at < tokens.length ? tokens[at] : null);
  const isOp = (value) => {
    const token = peek();
    return token !== null && token.kind === "op" && token.value === value;
  };
  const isWord = (value) => {
    const token = peek();
    return token !== null && token.kind === "word" && token.value === value;
  };

  function primary() {
    const token = peek();
    if (token === null) {
      fail();
    }
    if (token.kind === "num") {
      at += 1;
      return { number: token.value };
    }
    if (token.kind === "op" && token.value === "(") {
      at += 1;
      const inner = expression();
      if (!isOp(")")) {
        fail();
      }
      at += 1;
      return inner;
    }
    if (token.kind === "op" && (token.value === "-" || token.value === "+")) {
      at += 1;
      const inner = unary();
      return { number: token.value === "-" ? -plain(inner) : plain(inner) };
    }
    if (token.kind === "word") {
      if (Object.prototype.hasOwnProperty.call(CONSTANTS, token.value)) {
        at += 1;
        return { number: CONSTANTS[token.value] };
      }
      const fn = FUNCTIONS[token.value];
      if (fn === undefined) {
        fail();
      }
      at += 1;
      if (!isOp("(")) {
        fail();
      }
      at += 1;
      const args = [plain(expression())];
      while (args.length < fn.arity) {
        args.push(plain(expression()));
      }
      if (!isOp(")")) {
        fail();
      }
      at += 1;
      return { number: fn.apply.apply(null, args) };
    }
    return fail();
  }

  // A "%" reads as a percent or as a remainder depending on what comes after
  // it, so "50 + 10%" is 55 and "50 % 10" is 0.
  function percentHere() {
    if (!isOp("%")) {
      return false;
    }
    const next = at + 1 < tokens.length ? tokens[at + 1] : null;
    if (next === null) {
      return true;
    }
    if (next.kind === "word") {
      return next.value === "of";
    }
    return next.kind === "op" && ")+-*/^".indexOf(next.value) >= 0;
  }

  function postfix() {
    const value = primary();
    if (!percentHere()) {
      return value;
    }
    at += 1;
    if (isWord("of")) {
      at += 1;
      return { number: (value.number / 100) * plain(unary()) };
    }
    return { number: value.number, percent: true };
  }

  // Right associative, so 2^3^2 is 2^9 the way it is written on paper.
  function unary() {
    const value = postfix();
    if (isOp("^")) {
      at += 1;
      return { number: Math.pow(plain(value), plain(unary())) };
    }
    return value;
  }

  function product() {
    let left = unary();
    for (;;) {
      if (isOp("*")) {
        at += 1;
        const right = unary();
        left = { number: plain(left) * plain(right) };
      } else if (isOp("/")) {
        at += 1;
        const right = unary();
        left = { number: plain(left) / plain(right) };
      } else if (isOp("%")) {
        // Reaching here means postfix() declined it, so it is a remainder.
        at += 1;
        const right = unary();
        left = { number: plain(left) % plain(right) };
      } else {
        return left;
      }
    }
  }

  function expression() {
    let left = product();
    for (;;) {
      if (isOp("+")) {
        at += 1;
        const right = product();
        left = {
          number: right.percent === true ? plain(left) * (1 + right.number / 100) : plain(left) + plain(right),
        };
      } else if (isOp("-")) {
        at += 1;
        const right = product();
        left = {
          number: right.percent === true ? plain(left) * (1 - right.number / 100) : plain(left) - plain(right),
        };
      } else {
        return left;
      }
    }
  }

  const value = expression();
  if (at !== tokens.length) {
    fail();
  }
  return plain(value);
}

function format(value) {
  if (Number.isInteger(value) && Math.abs(value) < 1e15) {
    return value.toLocaleString("en-US");
  }
  const rounded = Number(value.toPrecision(12));
  if (Math.abs(rounded) >= 1e15 || (rounded !== 0 && Math.abs(rounded) < 1e-6)) {
    return rounded.toExponential(6).replace(/\.?0+e/, "e");
  }
  return rounded.toLocaleString("en-US", { maximumFractionDigits: 10 });
}

// A bare number is not a sum, and neither is a version or a port number, so a
// row is offered only once the query holds something to work out.
function arithmetic(tokens) {
  let operators = 0;
  for (const token of tokens) {
    if (token.kind === "op" && token.value !== "(" && token.value !== ")") {
      operators += 1;
    }
    if (token.kind === "word" && FUNCTIONS[token.value] !== undefined) {
      operators += 1;
    }
  }
  return operators > 0;
}

// Returns what the panel should show above the search results, or null when the
// query is not a sum at all.
function calculate(query) {
  const text = query.replace(/=+\s*$/, "").trim();
  if (text === "" || text.length > 200) {
    return null;
  }
  const tokens = tokenize(text);
  if (tokens === null || tokens.length === 0 || !arithmetic(tokens)) {
    return null;
  }
  let value;
  try {
    value = parse(tokens);
  } catch (error) {
    return null;
  }
  if (typeof value !== "number" || !Number.isFinite(value)) {
    return null;
  }
  return { result: format(value), expression: text };
}
