/* ================================================
   main.js — UI behavior (nav, menu, contact form,
   smooth scroll, scroll-aware navbar)
   ================================================ */

(() => {
  'use strict';

  /* ----- 1. SCROLL-AWARE NAVBAR --------------------- */
  function initNav() {
    const nav = document.querySelector('.navbar');
    if (!nav) return;
    function onScroll() {
      if (window.scrollY > 12) nav.classList.add('scrolled');
      else nav.classList.remove('scrolled');
    }
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
  }

  /* ----- 2. MOBILE MENU TOGGLE ---------------------- */
  function initMenu() {
    const toggle = document.querySelector('.menu-toggle');
    const menu = document.querySelector('.mobile-menu');
    if (!toggle || !menu) return;
    const iconMenu = `<svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg>`;
    const iconClose = `<svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>`;
    toggle.innerHTML = iconMenu;
    toggle.addEventListener('click', () => {
      const open = menu.classList.toggle('open');
      toggle.innerHTML = open ? iconClose : iconMenu;
    });
    menu.addEventListener('click', (e) => {
      if (e.target.tagName === 'A') {
        menu.classList.remove('open');
        toggle.innerHTML = iconMenu;
      }
    });
  }

  /* ----- 3. SMOOTH SCROLL (anchor links) ------------ */
  function initSmoothScroll() {
    document.addEventListener('click', (e) => {
      const a = e.target.closest('a[href^="#"]');
      if (!a) return;
      const href = a.getAttribute('href');
      if (href.length < 2) return;
      const target = document.querySelector(href);
      if (!target) return;
      e.preventDefault();
      // Scroll to the section's HEADLINE (not its padded top), so it lands
      // just under the fixed navbar instead of below a big blank gap.
      const NAV_OFFSET = 88; // 64px navbar + 24px breathing room
      const focus = target.querySelector('.section-head') || target;
      const top = focus.getBoundingClientRect().top + window.scrollY - NAV_OFFSET;
      window.scrollTo({ top: Math.max(0, top), behavior: 'smooth' });
    });
  }

  /* ----- 4. THEME TOGGLE ---------------------------- */
  function initTheme() {
    const btn = document.getElementById('theme-toggle');
    if (!btn) return;
    const KEY = 'kaplas-theme';
    function apply(theme) {
      if (theme === 'light') document.documentElement.setAttribute('data-theme', 'light');
      else document.documentElement.removeAttribute('data-theme');
    }
    btn.addEventListener('click', () => {
      const isLight = document.documentElement.getAttribute('data-theme') === 'light';
      const next = isLight ? 'dark' : 'light';
      apply(next);
      try { localStorage.setItem(KEY, next); } catch (e) {}
    });
    // honour OS-level changes if user hasn't saved a preference
    if (window.matchMedia) {
      const mq = window.matchMedia('(prefers-color-scheme: light)');
      mq.addEventListener && mq.addEventListener('change', (e) => {
        let saved = null;
        try { saved = localStorage.getItem(KEY); } catch (err) {}
        if (!saved) apply(e.matches ? 'light' : 'dark');
      });
    }
  }

  /* ----- 5. CONTACT FORM ---------------------------- */
  function initContactForm() {
    const form = document.querySelector('[data-contact-form]');
    if (!form) return;
    const opts = form.querySelectorAll('.topic-opt');
    const hidden = form.querySelector('input[name="topic"]');
    opts.forEach((opt) => {
      opt.addEventListener('click', () => {
        opts.forEach((o) => o.classList.remove('active'));
        opt.classList.add('active');
        if (hidden) hidden.value = opt.getAttribute('data-topic');
      });
    });
    const msg = form.querySelector('.form-msg');
    const submitBtn = form.querySelector('button[type="submit"]');
    const submitLabel = submitBtn ? submitBtn.innerHTML : '';

    const ICON_ERROR = '<svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg> ';
    const ICON_OK = '<svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg> ';

    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      const data = new FormData(form);
      const name = (data.get('name') || '').trim();
      const email = (data.get('email') || '').trim();
      const message = (data.get('message') || '').trim();
      const topic = (data.get('topic') || 'project').trim();

      if (!name || !email || !message) {
        msg.className = 'form-msg error';
        msg.innerHTML = ICON_ERROR + 'Please fill all fields before sending.';
        return;
      }

      // A readable subject + reply-to name for the email that lands in the inbox.
      data.set('subject', `[${topic}] ${name} via kaplas.tech`);
      data.set('from_name', `${name} (kaplas.tech)`);

      // Sending state
      if (submitBtn) { submitBtn.disabled = true; submitBtn.innerHTML = 'Sending…'; }
      msg.className = 'form-msg';
      msg.textContent = 'Sending your message…';

      try {
        const res = await fetch('https://api.web3forms.com/submit', {
          method: 'POST',
          headers: { 'Accept': 'application/json' },
          body: data,
        });
        const result = await res.json();
        if (res.ok && result.success) {
          msg.className = 'form-msg success';
          msg.innerHTML = ICON_OK + "Message sent — we'll get back to you within 24 hours.";
          form.reset();
          // Restore the default topic selection after reset
          opts.forEach((o, i) => o.classList.toggle('active', i === 0));
          if (hidden) hidden.value = 'project';
        } else {
          throw new Error(result.message || 'Submission failed');
        }
      } catch (err) {
        msg.className = 'form-msg error';
        msg.innerHTML = ICON_ERROR + 'Something went wrong. Please email us directly at kaplastechnologies@gmail.com.';
      } finally {
        if (submitBtn) { submitBtn.disabled = false; submitBtn.innerHTML = submitLabel; }
      }
    });
  }

  /* ----- INIT --------------------------------------- */
  function init() {
    initNav();
    initMenu();
    initSmoothScroll();
    initTheme();
    initContactForm();
  }
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
