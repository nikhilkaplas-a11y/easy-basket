const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

// Smooth scroll for anchor links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        const targetId = this.getAttribute('href');
        if (targetId.length < 2) return; // bare "#" — nothing to scroll to
        const target = document.querySelector(targetId);
        if (target) {
            e.preventDefault();
            target.scrollIntoView({
                behavior: prefersReducedMotion ? 'auto' : 'smooth',
                block: 'start'
            });
        }
    });
});

// Navbar shadow once the page has scrolled past the hero's top edge
const navbar = document.querySelector('.navbar');
if (navbar) {
    const updateNavbarState = () => {
        navbar.classList.toggle('navbar--scrolled', window.pageYOffset > 20);
    };
    updateNavbarState();
    window.addEventListener('scroll', updateNavbarState, { passive: true });
}

// Mobile nav toggle (hamburger)
const navToggle = document.getElementById('navToggle');
const navLinks = document.getElementById('navLinks');

if (navToggle && navLinks) {
    const closeMenu = () => {
        navLinks.classList.remove('is-open');
        navToggle.setAttribute('aria-expanded', 'false');
    };

    navToggle.addEventListener('click', () => {
        const isOpen = navLinks.classList.toggle('is-open');
        navToggle.setAttribute('aria-expanded', String(isOpen));
    });

    navLinks.querySelectorAll('a').forEach(link => {
        link.addEventListener('click', closeMenu);
    });

    document.addEventListener('click', (e) => {
        if (!navLinks.classList.contains('is-open')) return;
        if (!navLinks.contains(e.target) && !navToggle.contains(e.target)) {
            closeMenu();
        }
    });

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') closeMenu();
    });
}

// Scroll-triggered reveal animations (feature cards, steps, team cards,
// section headers). Elements only get the hiding `.reveal` class here in
// JS, so if this script fails to load the content just stays visible —
// no permanently-hidden sections.
const revealObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.classList.add('is-visible');
            revealObserver.unobserve(entry.target);
        }
    });
}, { threshold: 0.15, rootMargin: '0px 0px -60px 0px' });

function prepareReveal(selector, staggerGroup) {
    document.querySelectorAll(selector).forEach((el, i) => {
        el.classList.add('reveal');
        if (!prefersReducedMotion) {
            el.style.transitionDelay = `${(i % staggerGroup) * 90}ms`;
        }
        revealObserver.observe(el);
    });
}

prepareReveal('.section-header', 1);
prepareReveal('.feature-card', 3);
prepareReveal('.step', 4);
prepareReveal('.team-card', 2);

// Subtle hover lift on the hero device frame (skipped for reduced-motion users)
const heroDevice = document.querySelector('.hero-device');
if (heroDevice && !prefersReducedMotion) {
    heroDevice.addEventListener('mouseenter', () => {
        heroDevice.style.transform = 'scale(1.03)';
    });

    heroDevice.addEventListener('mouseleave', () => {
        heroDevice.style.transform = 'scale(1)';
    });
}

// Google Play button links out for real now — nothing to intercept there.
// The App Store button is still a placeholder (href="javascript:void(0)")
// until the iOS app ships, so just let people know it's coming.
document.querySelectorAll('.download-btn--soon').forEach(btn => {
    btn.addEventListener('click', (e) => {
        e.preventDefault();
        alert('Easy Basket for iOS is coming soon!');
    });
});
