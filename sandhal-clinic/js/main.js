(function () {
  "use strict";

  const $ = (sel, root = document) => root.querySelector(sel);
  const $$ = (sel, root = document) => [...root.querySelectorAll(sel)];

  /* Year in footer */
  const y = $("[data-year]");
  if (y) y.textContent = String(new Date().getFullYear());

  /* Sticky header shadow */
  const header = $("[data-header]");
  const onScroll = () => {
    if (!header) return;
    header.classList.toggle("is-scrolled", window.scrollY > 24);
  };
  window.addEventListener("scroll", onScroll, { passive: true });
  onScroll();

  /* Mobile nav */
  const navToggle = $("[data-nav-toggle]");
  const nav = $("[data-nav]");
  if (navToggle && nav) {
    navToggle.addEventListener("click", () => {
      const open = nav.classList.toggle("is-open");
      navToggle.setAttribute("aria-expanded", open ? "true" : "false");
      document.body.classList.toggle("nav-open", open);
    });
    $$('a[href^="#"]', nav).forEach((a) => {
      a.addEventListener("click", () => {
        nav.classList.remove("is-open");
        navToggle.setAttribute("aria-expanded", "false");
        document.body.classList.remove("nav-open");
      });
    });
  }

  /* Hero carousel */
  const carousel = $("[data-carousel]");
  const dots = $$("[data-carousel-dot]");
  const slides = carousel ? $$("[data-slide]", carousel) : [];

  function goToSlide(i) {
    if (!slides.length) return;
    const idx = ((i % slides.length) + slides.length) % slides.length;
    slides.forEach((slide, j) => {
      const on = j === idx;
      slide.classList.toggle("is-active", on);
      slide.setAttribute("aria-hidden", on ? "false" : "true");
      slide.querySelectorAll("a, button").forEach((el) => {
        el.tabIndex = on ? 0 : -1;
      });
    });
    dots.forEach((d, j) => {
      d.classList.toggle("is-active", j === idx);
      if (j === idx) d.setAttribute("aria-current", "true");
      else d.removeAttribute("aria-current");
    });
  }

  const prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const slideIntervalMs = prefersReducedMotion ? 0 : 6500;

  if (slides.length) {
    goToSlide(0);
    dots.forEach((dot, i) => {
      dot.addEventListener("click", () => goToSlide(i));
    });
    let t = null;
    function startAutoplay() {
      if (slideIntervalMs <= 0 || t) return;
      t = setInterval(() => {
        const cur = slides.findIndex((s) => s.classList.contains("is-active"));
        goToSlide(cur + 1);
      }, slideIntervalMs);
    }
    function stopAutoplay() {
      if (t) {
        clearInterval(t);
        t = null;
      }
    }
    if (slideIntervalMs > 0) {
      startAutoplay();
      const heroSection = carousel.parentElement;
      if (heroSection) {
        heroSection.addEventListener("mouseenter", stopAutoplay);
        heroSection.addEventListener("mouseleave", startAutoplay);
        heroSection.addEventListener("focusin", stopAutoplay);
        heroSection.addEventListener("focusout", () => {
          if (!heroSection.contains(document.activeElement)) startAutoplay();
        });
      }
    }
  }

  /* Testimonials */
  const track = $("[data-testimonials]");
  const testBlocks = track ? $$(".testimonial", track) : [];
  const dotWrap = $("[data-test-dots]");

  if (testBlocks.length && dotWrap) {
    testBlocks.forEach((_, i) => {
      const b = document.createElement("button");
      b.type = "button";
      b.setAttribute("aria-label", `Review ${i + 1}`);
      b.classList.toggle("is-active", i === 0);
      b.addEventListener("click", () => showTest(i));
      dotWrap.appendChild(b);
    });

    const dotBtns = () => $$("button", dotWrap);

    function showTest(i) {
      const idx = i % testBlocks.length;
      testBlocks.forEach((el, j) => el.classList.toggle("is-active", j === idx));
      dotBtns().forEach((d, j) => d.classList.toggle("is-active", j === idx));
    }

    let ti = setInterval(() => {
      const cur = testBlocks.findIndex((el) => el.classList.contains("is-active"));
      showTest(cur + 1);
    }, 6000);
    if (track.parentElement) {
      track.parentElement.addEventListener("mouseenter", () => clearInterval(ti));
      track.parentElement.addEventListener("mouseleave", () => {
        ti = setInterval(() => {
          const cur = testBlocks.findIndex((el) => el.classList.contains("is-active"));
          showTest(cur + 1);
        }, 6000);
      });
    }
  }

  /* Contact form (demo — no backend) */
  const form = $("[data-contact-form]");
  const status = $("[data-form-status]");
  if (form && status) {
    form.addEventListener("submit", (e) => {
      e.preventDefault();
      status.textContent = "Thank you — we will contact you shortly.";
      status.classList.add("is-success");
      form.reset();
    });
  }

  /* Scroll to top */
  const scrollBtn = $("[data-scroll-top]");
  window.addEventListener(
    "scroll",
    () => {
      if (!scrollBtn) return;
      scrollBtn.classList.toggle("is-visible", window.scrollY > 400);
    },
    { passive: true }
  );
  if (scrollBtn) {
    scrollBtn.addEventListener("click", () => {
      window.scrollTo({ top: 0, behavior: "smooth" });
    });
  }
})();
