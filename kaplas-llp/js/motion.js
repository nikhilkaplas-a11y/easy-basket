/* ================================================
   motion.js — vanilla JS animation library
   Handles: reveal-on-scroll, mouse spotlight, magnetic
   buttons, 3D tilt cards, count-up stats, code
   typewriter, console ticker.
   No dependencies. Runs after DOMContentLoaded.
   ================================================ */

(() => {
  'use strict';

  /* ----------------------------------------------------
     1. SCROLL REVEAL (IntersectionObserver)
     ---------------------------------------------------- */
  function initReveal() {
    const items = document.querySelectorAll('.reveal');
    if (!items.length) return;
    const io = new IntersectionObserver((entries) => {
      entries.forEach((e) => {
        if (e.isIntersecting) {
          e.target.classList.add('in');
          io.unobserve(e.target);
        }
      });
    }, { threshold: 0.15, rootMargin: '0px 0px -50px 0px' });
    items.forEach((i) => io.observe(i));
  }

  /* ----------------------------------------------------
     2. MOUSE SPOTLIGHT (hero only)
     Smooth follow with simple critically-damped spring.
     ---------------------------------------------------- */
  function initSpotlight() {
    const hero = document.querySelector('[data-spotlight]');
    if (!hero) return;
    const dot = hero.querySelector('.hero-spotlight');
    if (!dot) return;

    let tx = 0, ty = 0, cx = 0, cy = 0;
    let rafId = null;
    let visible = false;

    function onMove(e) {
      const r = hero.getBoundingClientRect();
      tx = e.clientX - r.left;
      ty = e.clientY - r.top;
      if (!visible) {
        dot.style.opacity = '1';
        cx = tx; cy = ty;
        visible = true;
      }
      schedule();
    }
    function onLeave() {
      dot.style.opacity = '0';
      visible = false;
    }
    function step() {
      rafId = null;
      cx += (tx - cx) * 0.18;
      cy += (ty - cy) * 0.18;
      dot.style.left = cx + 'px';
      dot.style.top = cy + 'px';
      if (Math.abs(tx - cx) > 0.3 || Math.abs(ty - cy) > 0.3) schedule();
    }
    function schedule() { if (rafId == null) rafId = requestAnimationFrame(step); }

    hero.addEventListener('mousemove', onMove);
    hero.addEventListener('mouseleave', onLeave);
  }

  /* ----------------------------------------------------
     3. MAGNETIC BUTTONS
     Subtle cursor-pull (3-6px max). Premium feel.
     ---------------------------------------------------- */
  function initMagnetic() {
    const btns = document.querySelectorAll('.btn-magnetic');
    btns.forEach((btn) => {
      const STRENGTH = 0.25;
      const MAX = 8;
      btn.addEventListener('mousemove', (e) => {
        const r = btn.getBoundingClientRect();
        const cx = r.left + r.width / 2;
        const cy = r.top + r.height / 2;
        const dx = (e.clientX - cx) * STRENGTH;
        const dy = (e.clientY - cy) * STRENGTH;
        const x = Math.max(-MAX, Math.min(MAX, dx));
        const y = Math.max(-MAX, Math.min(MAX, dy));
        btn.style.transform = `translate(${x}px, ${y}px)`;
      });
      btn.addEventListener('mouseleave', () => {
        btn.style.transform = 'translate(0, 0)';
      });
    });
  }

  /* ----------------------------------------------------
     4. 3D CARD TILT
     Subtle perspective rotation on cursor position.
     ---------------------------------------------------- */
  function initTilt() {
    const cards = document.querySelectorAll('.card-tilt');
    cards.forEach((card) => {
      const MAX_DEG = 6;
      card.style.perspective = '900px';
      card.addEventListener('mousemove', (e) => {
        const r = card.getBoundingClientRect();
        const px = (e.clientX - r.left) / r.width;
        const py = (e.clientY - r.top) / r.height;
        const rx = ((py - 0.5) * -2) * MAX_DEG;
        const ry = ((px - 0.5) * 2) * MAX_DEG;
        card.style.transform =
          `perspective(900px) rotateX(${rx.toFixed(2)}deg) rotateY(${ry.toFixed(2)}deg) translateZ(0)`;
      });
      card.addEventListener('mouseleave', () => {
        card.style.transform = 'perspective(900px) rotateX(0) rotateY(0)';
      });
    });
  }

  /* ----------------------------------------------------
     5. COUNT-UP STATS
     Animate from 0 → target on viewport enter.
     Supports prefixes/suffixes (%, +, K, ↓, etc.).
     ---------------------------------------------------- */
  function parseValue(v) {
    const m = String(v).match(/^(\D*)([\d.,]+)(.*)$/);
    if (!m) return { prefix: v, n: 0, decimals: 0, suffix: '' };
    const numStr = m[2].replace(/,/g, '');
    const decimals = numStr.includes('.') ? numStr.split('.')[1].length : 0;
    return { prefix: m[1] || '', n: parseFloat(numStr), decimals, suffix: m[3] || '' };
  }
  function easeOutCubic(t) { return 1 - Math.pow(1 - t, 3); }
  function initCountUp() {
    const els = document.querySelectorAll('[data-count]');
    if (!els.length) return;
    const io = new IntersectionObserver((entries) => {
      entries.forEach((e) => {
        if (!e.isIntersecting) return;
        const el = e.target;
        const target = el.getAttribute('data-count');
        const dur = parseInt(el.getAttribute('data-count-dur')) || 1600;
        const p = parseValue(target);
        const start = performance.now();
        function tick(now) {
          const t = Math.min(1, (now - start) / dur);
          const eased = easeOutCubic(t);
          const cur = p.n * eased;
          const out = p.decimals > 0
            ? cur.toFixed(p.decimals)
            : Math.round(cur).toLocaleString('en-IN');
          el.textContent = p.prefix + out + p.suffix;
          if (t < 1) requestAnimationFrame(tick);
        }
        el.textContent = p.prefix + '0' + p.suffix;
        requestAnimationFrame(tick);
        io.unobserve(el);
      });
    }, { threshold: 0.4 });
    els.forEach((el) => io.observe(el));
  }

  /* ----------------------------------------------------
     6. TYPEWRITER CODE EDITOR
     Types out files character-by-character, then loops
     to next file. Tabs in the editor bar swap with it.
     ---------------------------------------------------- */
  const CODE_FILES = [
    {
      name: 'kaplas.ts',
      lines: [
        ['<span class="tk-com">// Senior engineers. Production code. Real outcomes.</span>'],
        [''],
        ['<span class="tk-key">interface</span> <span class="tk-fn">KaplasEngagement</span> {'],
        ['  team:        <span class="tk-str">"senior-only"</span>,'],
        ['  shipping:    <span class="tk-str">"fast"</span>,'],
        ['  scale:       <span class="tk-num">100_000_000</span>,'],
        ['  reliability: <span class="tk-num">99.9</span>,'],
        ['}'],
        [''],
        ['<span class="tk-key">export const</span> <span class="tk-var">ready</span> = <span class="tk-key">true</span>;'],
      ],
    },
    {
      name: 'easy-basket.ts',
      lines: [
        ['<span class="tk-com">// Hyperlocal delivery. End-to-end.</span>'],
        ['<span class="tk-key">import</span> { <span class="tk-fn">orchestrate</span> } <span class="tk-key">from</span> <span class="tk-str">"@kaplas/core"</span>;'],
        [''],
        ['<span class="tk-key">const</span> <span class="tk-var">orders</span> = <span class="tk-key">await</span> <span class="tk-fn">orchestrate</span>({'],
        ['  riders:       <span class="tk-num">240</span>,'],
        ['  avgDeliveryMin: <span class="tk-num">22</span>,'],
        ['  otpSuccess:   <span class="tk-num">99.4</span>,'],
        ['  codReconciled: <span class="tk-key">true</span>,'],
        ['});'],
      ],
    },
    {
      name: 'routing-ai.ts',
      lines: [
        ['<span class="tk-com">// One API. Every model. Pay-per-use.</span>'],
        ['<span class="tk-key">const</span> <span class="tk-var">router</span> = <span class="tk-fn">createRouter</span>({'],
        ['  providers: [<span class="tk-str">"openai"</span>, <span class="tk-str">"anthropic"</span>, <span class="tk-str">"google"</span>],'],
        ['  strategy:  <span class="tk-str">"cost-then-latency"</span>,'],
        ['  fallback:  <span class="tk-key">true</span>,'],
        ['});'],
        [''],
        ['<span class="tk-key">await</span> <span class="tk-var">router</span>.<span class="tk-fn">complete</span>(<span class="tk-var">prompt</span>);'],
      ],
    },
    {
      name: 'payments.ts',
      lines: [
        ['<span class="tk-com">// Multi-gateway orchestration.</span>'],
        ['<span class="tk-key">async function</span> <span class="tk-fn">charge</span>(<span class="tk-var">amount</span>) {'],
        ['  <span class="tk-key">const</span> <span class="tk-var">pg</span> = <span class="tk-fn">selectGateway</span>({'],
        ['    success: <span class="tk-num">0.97</span>,'],
        ['    cost:    <span class="tk-str">"lowest"</span>,'],
        ['  });'],
        ['  <span class="tk-key">return</span> <span class="tk-key">await</span> <span class="tk-var">pg</span>.<span class="tk-fn">charge</span>(<span class="tk-var">amount</span>);'],
        ['}'],
      ],
    },
  ];

  function initTypewriter() {
    const editor = document.querySelector('[data-typewriter]');
    if (!editor) return;
    const tabsEl = editor.querySelector('.code-bar-tabs');
    const bodyEl = editor.querySelector('.code-body');

    // build tab strip
    tabsEl.innerHTML = CODE_FILES.map((f, i) =>
      `<span class="code-tab${i === 0 ? ' active' : ''}" data-idx="${i}">${f.name}</span>`
    ).join('');
    const tabs = tabsEl.querySelectorAll('.code-tab');

    let fileIdx = 0;
    let lineIdx = 0;
    let charIdx = 0;
    let timer = null;

    // typing speeds
    const CHAR_DELAY = 14;       // ms per char
    const LINE_DELAY = 90;       // ms between lines
    const FILE_HOLD = 2400;      // ms hold complete file
    const PRE_TYPE_DELAY = 400;  // ms before next file starts

    function setActiveTab() {
      tabs.forEach((t, i) => t.classList.toggle('active', i === fileIdx));
    }

    function renderBody(completedLines, currentLine) {
      const html = completedLines.map((l, i) =>
        `<div class="code-line"><span class="ln">${i + 1}</span><span class="lc">${l}</span></div>`
      ).join('');
      const cursor = '<span class="cursor-blink"></span>';
      if (currentLine != null) {
        bodyEl.innerHTML = html +
          `<div class="code-line"><span class="ln">${completedLines.length + 1}</span><span class="lc">${currentLine}${cursor}</span></div>`;
      } else {
        bodyEl.innerHTML = html;
      }
    }

    function visibleLength(html) {
      const tmp = document.createElement('div');
      tmp.innerHTML = html;
      return tmp.textContent.length;
    }
    function sliceHTML(html, n) {
      // walk HTML and keep n visible chars
      let out = '';
      let count = 0;
      let i = 0;
      while (i < html.length && count < n) {
        if (html[i] === '<') {
          const end = html.indexOf('>', i);
          out += html.slice(i, end + 1);
          i = end + 1;
        } else {
          out += html[i];
          count++;
          i++;
        }
      }
      return out;
    }

    function step() {
      const file = CODE_FILES[fileIdx];
      if (lineIdx >= file.lines.length) {
        // file complete, hold then advance
        timer = setTimeout(() => {
          fileIdx = (fileIdx + 1) % CODE_FILES.length;
          lineIdx = 0;
          charIdx = 0;
          setActiveTab();
          bodyEl.innerHTML = '';
          timer = setTimeout(step, PRE_TYPE_DELAY);
        }, FILE_HOLD);
        return;
      }
      const fullLine = file.lines[lineIdx][0];
      const total = visibleLength(fullLine);
      if (charIdx <= total) {
        const completed = file.lines.slice(0, lineIdx).map(l => l[0]);
        const partial = sliceHTML(fullLine, charIdx);
        renderBody(completed, partial);
        charIdx++;
        timer = setTimeout(step, fullLine === '' ? 30 : CHAR_DELAY);
      } else {
        // line done, move to next
        lineIdx++;
        charIdx = 0;
        timer = setTimeout(step, LINE_DELAY);
      }
    }

    setActiveTab();
    step();
  }

  /* ----------------------------------------------------
     7. CONSOLE TICKER
     Rotates short status lines like a live shell.
     ---------------------------------------------------- */
  const CONSOLE_LINES = [
    'deploying <strong>easy-basket v2.1</strong> → 240 orders/day',
    'training cohort <strong>#7</strong> enrolled · DSA + system design',
    'payments routed: <strong>100k+</strong> processed today',
    'easy-basket OTP success: <strong>99.4%</strong> · twilio fallback green',
    'sandhal-clinic: <strong>14 clinics</strong> live, 2 onboarding',
    'routing-ai gateway: <strong>4 providers</strong> active, smart-routing on',
    'kaplas network: <strong>5+ senior engineers</strong> on standby',
    'p99 latency: <strong>108ms</strong> across all services',
  ];
  function initTicker() {
    const el = document.querySelector('[data-ticker]');
    if (!el) return;
    let i = 0;
    function show() {
      el.style.opacity = '0';
      el.style.transform = 'translateY(4px)';
      setTimeout(() => {
        el.innerHTML = CONSOLE_LINES[i];
        el.style.transition = 'opacity 0.4s ease, transform 0.4s ease';
        el.style.opacity = '1';
        el.style.transform = 'translateY(0)';
        i = (i + 1) % CONSOLE_LINES.length;
      }, 220);
    }
    show();
    setInterval(show, 3200);
  }

  /* ----------------------------------------------------
     8. ROTATING WORD (in heroes that use it)
     Cycles through a list with smooth fade+blur.
     ---------------------------------------------------- */
  function initRotatingWord() {
    const el = document.querySelector('[data-rotate]');
    if (!el) return;
    const words = (el.getAttribute('data-rotate') || '').split('|');
    if (!words.length) return;
    let idx = 0;
    el.textContent = words[0];
    el.style.transition = 'opacity 0.4s ease, filter 0.4s ease, transform 0.4s ease';
    setInterval(() => {
      el.style.opacity = '0';
      el.style.filter = 'blur(6px)';
      el.style.transform = 'translateY(-12px)';
      setTimeout(() => {
        idx = (idx + 1) % words.length;
        el.textContent = words[idx];
        el.style.transform = 'translateY(12px)';
        requestAnimationFrame(() => {
          el.style.opacity = '1';
          el.style.filter = 'blur(0px)';
          el.style.transform = 'translateY(0)';
        });
      }, 380);
    }, 2400);
  }

  /* ----------------------------------------------------
     INIT
     ---------------------------------------------------- */
  function init() {
    initReveal();
    initSpotlight();
    initMagnetic();
    initTilt();
    initCountUp();
    initTypewriter();
    initTicker();
    initRotatingWord();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
