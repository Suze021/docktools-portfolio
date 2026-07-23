document.documentElement.classList.add('js');

const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
const finePointer = window.matchMedia('(pointer: fine)').matches;

const clamp = (value, min, max) => Math.min(Math.max(value, min), max);

// Preserve line breaks while giving each word an individual reveal mask.
document.querySelectorAll('[data-split]').forEach((element) => {
  const walker = document.createTreeWalker(element, NodeFilter.SHOW_TEXT);
  const textNodes = [];
  while (walker.nextNode()) textNodes.push(walker.currentNode);

  textNodes.forEach((node) => {
    if (!node.nodeValue.trim()) return;
    const fragment = document.createDocumentFragment();
    const words = node.nodeValue.trim().split(/\s+/);
    words.forEach((word, index) => {
      const wrap = document.createElement('span');
      const inner = document.createElement('span');
      wrap.className = 'word-wrap';
      inner.className = 'word';
      inner.textContent = word;
      inner.style.transitionDelay = `${Math.min(index * 35, 350)}ms`;
      wrap.append(inner);
      fragment.append(wrap);
      if (index < words.length - 1) fragment.append(' ');
    });
    node.replaceWith(fragment);
  });
});

requestAnimationFrame(() => document.body.classList.add('is-ready'));

document.querySelectorAll('[data-year]').forEach((element) => {
  element.textContent = new Date().getFullYear();
});

const header = document.querySelector('[data-header]');
const menu = document.querySelector('[data-menu]');
const menuToggle = document.querySelector('[data-menu-toggle]');
let lastScrollY = window.scrollY;

const closeMenu = () => {
  menuToggle?.setAttribute('aria-expanded', 'false');
  menu?.classList.remove('is-open');
  document.body.style.overflow = '';
  document.body.classList.remove('menu-open');
};

menuToggle?.addEventListener('click', () => {
  const willOpen = menuToggle.getAttribute('aria-expanded') !== 'true';
  menuToggle.setAttribute('aria-expanded', String(willOpen));
  menu?.classList.toggle('is-open', willOpen);
  document.body.style.overflow = willOpen ? 'hidden' : '';
  document.body.classList.toggle('menu-open', willOpen);
});

menu?.querySelectorAll('a').forEach((link) => link.addEventListener('click', closeMenu));
window.addEventListener('keydown', (event) => {
  if (event.key === 'Escape') closeMenu();
});

const progress = document.querySelector('[data-scroll-progress]');
const timeline = document.querySelector('[data-timeline]');
const timelineProgress = document.querySelector('[data-timeline-progress]');
const projects = [...document.querySelectorAll('[data-project]')];

const updateScrollState = () => {
  const scrollY = window.scrollY;
  const available = document.documentElement.scrollHeight - window.innerHeight;
  const ratio = available > 0 ? scrollY / available : 0;
  progress?.style.setProperty('transform', `scaleX(${ratio})`);

  header?.classList.toggle('is-scrolled', scrollY > 18);
  const menuOpen = menuToggle?.getAttribute('aria-expanded') === 'true';
  header?.classList.toggle('is-hidden', !menuOpen && scrollY > lastScrollY && scrollY > 260);
  lastScrollY = scrollY;

  if (timeline && timelineProgress) {
    const rect = timeline.getBoundingClientRect();
    const timelineRatio = clamp((window.innerHeight * 0.65 - rect.top) / (rect.height + window.innerHeight * 0.2), 0, 1);
    timelineProgress.style.transform = `scaleY(${timelineRatio})`;
  }

  if (!reducedMotion && window.innerWidth > 760) {
    projects.forEach((project) => {
      const preview = project.querySelector('[data-project-preview]');
      if (!preview) return;
      const rect = project.getBoundingClientRect();
      if (rect.bottom < 0 || rect.top > window.innerHeight) return;
      const centerOffset = (rect.top + rect.height / 2 - window.innerHeight / 2) / window.innerHeight;
      preview.style.setProperty('--project-y', `${clamp(centerOffset * -8, -8, 8)}px`);
    });
  }
};

let scrollFrame;
window.addEventListener('scroll', () => {
  if (scrollFrame) return;
  scrollFrame = requestAnimationFrame(() => {
    updateScrollState();
    scrollFrame = null;
  });
}, { passive: true });

updateScrollState();

const observer = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (!entry.isIntersecting) return;
    entry.target.classList.add('is-visible');
    observer.unobserve(entry.target);
  });
}, { threshold: 0.13, rootMargin: '0px 0px -45px' });

document.querySelectorAll('[data-reveal], [data-split]').forEach((element, index) => {
  if (reducedMotion) {
    element.classList.add('is-visible');
    return;
  }
  if (element.matches('[data-reveal]')) {
    element.style.transitionDelay = `${Math.min(index % 3, 2) * 60}ms`;
  }
  observer.observe(element);
});

// Safety net: content must never remain hidden if a browser skips observer
// callbacks during an unusually fast scroll, page restore or automation.
window.setTimeout(() => {
  document.querySelectorAll('[data-reveal], [data-split]').forEach((element) => {
    element.classList.add('is-visible');
  });
}, 4200);

if (finePointer && !reducedMotion) {
  const cursor = document.querySelector('[data-cursor]');
  let targetX = window.innerWidth / 2;
  let targetY = window.innerHeight / 2;
  let currentX = targetX;
  let currentY = targetY;

  window.addEventListener('pointermove', (event) => {
    targetX = event.clientX;
    targetY = event.clientY;
    if (cursor) cursor.style.opacity = '1';
  }, { passive: true });

  window.addEventListener('pointerleave', () => {
    if (cursor) cursor.style.opacity = '0';
  });

  document.querySelectorAll('a, button, [data-project-preview]').forEach((target) => {
    target.addEventListener('pointerenter', () => cursor?.classList.add('is-active'));
    target.addEventListener('pointerleave', () => cursor?.classList.remove('is-active'));
  });

  const renderCursor = () => {
    currentX += (targetX - currentX) * 0.18;
    currentY += (targetY - currentY) * 0.18;
    cursor?.style.setProperty('transform', `translate3d(${currentX - 17}px, ${currentY - 17}px, 0)`);
    requestAnimationFrame(renderCursor);
  };
  renderCursor();
}
