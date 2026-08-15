// Ranking for the lists small enough to hold in the page. The file list is not
// one of them and still goes out to fzf, but everything else is a few hundred
// rows, and matching them here is what makes a keystroke cost nothing: no task
// spawn, no pipe, no wait for a reply that may arrive after the next key.

const MATCH = 16;
const BOUNDARY = 9;
const CAMEL = 7;
const CONSEC = 8;
const GAP_START = -5;
const GAP_EXT = -1;
const NEG = -1000000;
const HALF = NEG / 2;

const SEPARATOR = /[\s/\\_\-.:@]/;

function upper(c) {
  return c >= "A" && c <= "Z";
}

function lower(c) {
  return c >= "a" && c <= "z";
}

function digit(c) {
  return c >= "0" && c <= "9";
}

// What a match at this position is worth beyond the match itself. A hit on the
// first letter of a word is what a person means far more often than a hit in
// the middle of one, so the two must not score the same.
function bonuses(text) {
  const out = new Int32Array(text.length);
  for (let j = 0; j < text.length; j++) {
    if (j === 0) {
      out[j] = BOUNDARY;
      continue;
    }
    const prev = text[j - 1];
    const here = text[j];
    if (SEPARATOR.test(prev)) {
      out[j] = BOUNDARY;
    } else if (lower(prev) && upper(here)) {
      out[j] = CAMEL;
    } else if (!digit(prev) && digit(here)) {
      out[j] = CAMEL;
    }
  }
  return out;
}

// Held per row so a keystroke re-reads them rather than rebuilding them. The
// row set changes every few seconds; the query changes every few milliseconds.
function prepare(text) {
  return { text: text, low: text.toLowerCase(), bonus: bonuses(text) };
}

// Every alignment of the query in the text is scored and the best one wins,
// because the greedy left-to-right one is often not the best: "cal" in
// "Calendar" should not settle for the "c" of the first "c" it happens to see
// when a later one starts a word.
function score(needle, field) {
  const low = field.low;
  const bonus = field.bonus;
  const n = needle.length;
  const m = low.length;
  if (n === 0) {
    return 0;
  }
  if (n > m) {
    return null;
  }

  // A subsequence test first, because most rows fail and the table below costs
  // n*m to fill.
  let at = 0;
  for (let i = 0; i < n; i++) {
    at = low.indexOf(needle[i], at);
    if (at < 0) {
      return null;
    }
    at += 1;
  }

  let prev = new Int32Array(m).fill(NEG);
  let cur = new Int32Array(m);
  for (let j = 0; j < m; j++) {
    if (low[j] === needle[0]) {
      // A match nearer the front is worth slightly more, so "mail" prefers
      // "Mail" to "Voicemail".
      prev[j] = MATCH + bonus[j] * 2 - Math.min(j, 24);
    }
  }

  for (let i = 1; i < n; i++) {
    cur.fill(NEG);
    // The best score reachable at this column by leaving a gap, carried across
    // the row so the gap is found in one pass rather than a scan per column.
    // It is brought up to date before it is read, or the column the previous
    // letter landed on would never be a place a gap can start from.
    let gapped = NEG;
    for (let j = i; j < m; j++) {
      const opened = prev[j - 1] > HALF ? prev[j - 1] + GAP_START : NEG;
      const held = gapped > HALF ? gapped + GAP_EXT : NEG;
      gapped = opened > held ? opened : held;
      if (low[j] === needle[i]) {
        const run = prev[j - 1] > HALF ? prev[j - 1] + CONSEC : NEG;
        const from = run > gapped ? run : gapped;
        if (from > HALF) {
          cur[j] = from + MATCH + bonus[j] * 2;
        }
      }
    }
    const swap = prev;
    prev = cur;
    cur = swap;
  }

  let best = NEG;
  for (let j = n - 1; j < m; j++) {
    if (prev[j] > best) {
      best = prev[j];
    }
  }
  return best > HALF ? best : null;
}

// The title is what a person is aiming at, so a hit there outranks the same hit
// in the path or the URL underneath it.
function rank(query, rows) {
  const needle = query.toLowerCase();
  const hits = [];
  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];
    let best = score(needle, row.f_title);
    if (best !== null) {
      best += 24;
    }
    if (row.f_sub) {
      const sub = score(needle, row.f_sub);
      if (sub !== null && (best === null || sub > best)) {
        best = sub;
      }
    }
    if (best !== null) {
      hits.push({ row: row, at: best, order: i });
    }
  }
  hits.sort((a, b) => (b.at !== a.at ? b.at - a.at : a.order - b.order));
  return hits.map((hit) => hit.row);
}
