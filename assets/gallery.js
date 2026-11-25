// Screenshot gallery and language menu for index.html and fi/index.html. Each page sets window.GALLERY before
// loading this file: its image folder (base), its screenshot sets, and the gallery's own texts.
// Icons, device frames, and layout are original to this site; it loads no external fonts, scripts, or styles.
(() => {
  const { base, sets: SHOTS, text: T } = window.GALLERY;

  const viewer = document.getElementById("viewer");
  const device = document.getElementById("device");
  const shot = document.getElementById("shot");
  const thumbs = document.getElementById("thumbs");
  const prev = document.getElementById("prev");
  const next = document.getElementById("next");
  const tabs = [...document.querySelectorAll('.switch [role="tab"]')];
  let key = "iphone", index = 0;
  const src = (set, file, dir = "") => `${base}${dir}/${set.dir}-${file}.jpg`;
  // Disable a step button at either end; if it had focus, hand focus to its partner so it isn't lost.
  function setEnds(back, forward, i, count) {
    for (const [b, off, other] of [[back, i === 0, forward], [forward, i === count - 1, back]]) {
      if (off && document.activeElement === b) other.focus();
      b.disabled = off;
    }
  }

  // Shareable links: #duo or #ipad opens that set, #ipad-3 a given shot (#iphone works too).
  // Without such a hash the page opens as usual; browsing the gallery keeps the hash current.
  const HASH = /^#(iphone|duo|ipad)(?:-(\d+))?$/;
  let linking = false;
  function syncHash() {
    if (!linking) return;
    const h = index ? `#${key}-${index + 1}` : `#${key}`;
    if (location.hash !== h) history.replaceState(null, "", h);
  }
  // The language links keep the visitor's place: a section link (#faq) they followed, else the
  // gallery shot they browsed to or opened from a link. The other page has the same IDs.
  const SECTION = /^#[a-z][\w-]*$/;
  function languageHash() {
    const h = location.hash;
    if (h && !HASH.test(h) && SECTION.test(h) && document.getElementById(h.slice(1))) return h;
    if (linking) return index ? `#${key}-${index + 1}` : `#${key}`;
    return HASH.test(h) ? h : "";
  }
  function syncLanguageLinks() {
    for (const a of document.querySelectorAll('.lang a:not([aria-current])')) a.hash = languageHash();
  }

  function show(i) {
    const set = SHOTS[key];
    index = Math.max(0, Math.min(set.shots.length - 1, i));
    syncHash();
    syncLanguageLinks();
    const [file, frame, title, sub] = set.shots[index];
    device.className = "device " + frame;
    shot.src = src(set, file);
    shot.alt = T.alt(set.label, title, sub);
    document.getElementById("zoom").setAttribute("aria-label", T.zoom(shot.alt));
    document.getElementById("cap-title").textContent = title;
    document.getElementById("cap-sub").textContent = sub;
    document.getElementById("cap-count").textContent = T.count(index + 1, set.shots.length);
    [...thumbs.children].forEach((t, j) => t.setAttribute("aria-current", j === index));
    setEnds(prev, next, index, set.shots.length);
    // Warm the neighbors so stepping feels instant.
    for (const j of [index - 1, index + 1]) if (set.shots[j]) new Image().src = src(set, set.shots[j][0]);
  }
  function selectSet(tab, focus) {
    key = tab.id.slice(4);
    for (const t of tabs) {
      const on = t === tab;
      t.setAttribute("aria-selected", on);
      t.tabIndex = on ? 0 : -1;
    }
    if (focus) tab.focus();
    const set = SHOTS[key];
    viewer.dataset.set = key;
    viewer.setAttribute("aria-labelledby", tab.id);
    thumbs.innerHTML = "";
    set.shots.forEach(([file, , title], j) => {
      const b = document.createElement("button");
      b.type = "button";
      b.className = "thumb";
      b.setAttribute("aria-label", T.thumb(j + 1, title));
      b.innerHTML = `<img src="${src(set, file, "/thumbs")}" alt="" loading="lazy" decoding="async">`;
      b.addEventListener("click", () => show(j));
      thumbs.append(b);
    });
    show(0);
  }
  tabs.forEach((tab, i) => {
    tab.addEventListener("click", () => selectSet(tab));
    tab.addEventListener("keydown", e => {
      const d = e.key === "ArrowRight" ? 1 : e.key === "ArrowLeft" ? -1 : 0;
      if (d) { e.preventDefault(); selectSet(tabs[(i + d + tabs.length) % tabs.length], true); }
    });
  });
  // Zoom: the full-size screenshot in a modal dialog (Esc, the close button, or a click outside closes it).
  const lightbox = document.getElementById("lightbox");
  const lbImg = document.getElementById("lb-img");
  let lightboxRequest = 0;
  function syncLightbox() {
    const request = ++lightboxRequest;
    const set = SHOTS[key];
    const [file, frame, title] = set.shots[index];
    document.getElementById("lb-device").className = "device " + frame;
    // Show the gallery image at once, then swap in the full-resolution copy when it arrives.
    lbImg.src = src(set, file);
    const full = src(set, file, "/full");
    const hi = new Image();
    hi.onload = () => { if (lightbox.open && request === lightboxRequest) lbImg.src = full; };
    hi.src = full;
    lbImg.alt = shot.alt;
    document.getElementById("lb-caption").textContent = `${title} (${T.count(index + 1, set.shots.length)})`;
    setEnds(document.getElementById("lb-prev"), document.getElementById("lb-next"), index, set.shots.length);
  }
  document.getElementById("zoom").addEventListener("click", () => { syncLightbox(); lightbox.showModal(); });
  document.getElementById("lb-close").addEventListener("click", () => lightbox.close());
  document.getElementById("lb-prev").addEventListener("click", () => { show(index - 1); syncLightbox(); });
  document.getElementById("lb-next").addEventListener("click", () => { show(index + 1); syncLightbox(); });
  document.getElementById("lb-device").addEventListener("click", () => lightbox.close());
  lightbox.addEventListener("click", e => { if (e.target === lightbox) lightbox.close(); });
  lightbox.addEventListener("keydown", e => {
    if (e.key === "ArrowLeft") { show(index - 1); syncLightbox(); }
    if (e.key === "ArrowRight") { show(index + 1); syncLightbox(); }
  });

  prev.addEventListener("click", () => show(index - 1));
  next.addEventListener("click", () => show(index + 1));
  viewer.addEventListener("keydown", e => {
    const d = e.key === "ArrowRight" ? 1 : e.key === "ArrowLeft" ? -1 : 0;
    if (!d) return;
    // From a focused thumbnail, step from that thumbnail rather than from the shown shot.
    const from = [...thumbs.children].indexOf(document.activeElement);
    show((from >= 0 ? from : index) + d);
    if (from >= 0) thumbs.children[index].focus();
  });
  // Open the set (and shot) a shared link names; the page itself stays where it is.
  function openFromHash() {
    const m = HASH.exec(location.hash);
    syncLanguageLinks();
    if (!m) return false;
    linking = false;
    selectSet(document.getElementById("tab-" + m[1]));
    if (m[2]) show(Number(m[2]) - 1);
    return true;
  }
  if (!openFromHash()) selectSet(tabs[0]);
  window.addEventListener("hashchange", openFromHash);

  // Language menu: close it on a click outside or on Escape (focus returns to its button).
  const menu = document.querySelector(".lang");
  if (menu) {
    document.addEventListener("click", e => { if (menu.open && !menu.contains(e.target)) menu.open = false; });
    // On the whole page, so Escape still closes it after Tab has moved focus out of the menu.
    document.addEventListener("keydown", e => {
      if (e.key !== "Escape" || !menu.open) return;
      const inside = menu.contains(document.activeElement);
      menu.open = false;
      if (inside) menu.querySelector("summary").focus();
    });
  }
  // Only a visitor's own gallery choices write the hash, never the initial load.
  for (const el of [...tabs, viewer, lightbox])
    for (const type of ["click", "keydown"]) el.addEventListener(type, () => { linking = true; }, true);
})();
