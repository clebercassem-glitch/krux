const root = document.documentElement;
const header = document.querySelector(".site-header");
const menuButton = document.querySelector(".menu-button");
const nav = document.querySelector(".site-nav");
const motionOK = !window.matchMedia("(prefers-reduced-motion: reduce)").matches;

menuButton?.addEventListener("click", () => {
  const isOpen = nav?.classList.toggle("open");
  menuButton.setAttribute("aria-expanded", String(Boolean(isOpen)));
});

nav?.querySelectorAll("a").forEach((link) => {
  link.addEventListener("click", () => {
    nav.classList.remove("open");
    menuButton?.setAttribute("aria-expanded", "false");
  });
});

const updateHeader = () => {
  header?.classList.toggle("is-scrolled", window.scrollY > 18);
};

updateHeader();
window.addEventListener("scroll", updateHeader, { passive: true });

if (motionOK) {
  let rafId = 0;
  let pointer = { x: window.innerWidth / 2, y: window.innerHeight * 0.2 };

  window.addEventListener("pointermove", (event) => {
    pointer = { x: event.clientX, y: event.clientY };
    if (rafId) return;

    rafId = window.requestAnimationFrame(() => {
      const x = `${pointer.x}px`;
      const y = `${pointer.y}px`;
      root.style.setProperty("--mx", x);
      root.style.setProperty("--my", y);

      document.querySelectorAll("[data-depth]").forEach((el) => {
        const depth = Number(el.dataset.depth || 0);
        const moveX = ((pointer.x / window.innerWidth) - 0.5) * depth;
        const moveY = ((pointer.y / window.innerHeight) - 0.5) * depth;
        el.style.transform = `translate3d(${moveX}px, ${moveY}px, 0)`;
      });

      rafId = 0;
    });
  }, { passive: true });

  document.querySelectorAll(".tilt-card, .value-rail article").forEach((card) => {
    card.addEventListener("pointermove", (event) => {
      const rect = card.getBoundingClientRect();
      const localX = event.clientX - rect.left;
      const localY = event.clientY - rect.top;
      const rotateY = ((localX / rect.width) - 0.5) * 5;
      const rotateX = -((localY / rect.height) - 0.5) * 5;

      card.style.setProperty("--cx", `${localX}px`);
      card.style.setProperty("--cy", `${localY}px`);
      card.style.transform = `perspective(900px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) translateY(-3px)`;
    });

    card.addEventListener("pointerleave", () => {
      card.style.transform = "";
    });
  });
}

const revealObserver = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting) {
      entry.target.classList.add("is-visible");
      revealObserver.unobserve(entry.target);
    }
  });
}, { threshold: 0.12 });

document.querySelectorAll(".reveal").forEach((el, index) => {
  el.style.transitionDelay = `${Math.min(index * 35, 260)}ms`;
  revealObserver.observe(el);
});
