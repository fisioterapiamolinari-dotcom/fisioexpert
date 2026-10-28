// =====================================================================
// Service worker dell'App Allenamenti Fisio Expert
//
// Gestisce SOLO le pagine dell'app e le loro risorse: il resto del sito
// (home, blog, prenotazioni…) passa dritto alla rete come sempre.
// I dati dei pazienti NON passano da qui: le chiamate a Supabase vanno
// sempre in rete, e l'allenamento offline lo salvano le pagine stesse.
//
// Quando cambi una pagina dell'app non serve toccare questo file:
// le pagine si scaricano sempre fresche se c'è rete.
// Cambia VERSIONE solo se modifichi l'elenco dei file qui sotto.
// =====================================================================

const VERSIONE = 'fx-app-v1';

const PAGINE = ['/login.html', '/app.html', '/allenamento.html', '/informativa-app.html'];
const RISORSE = [
  '/logo.png', '/favicon.ico', '/manifest-app.json',
  '/icona-app-180.png', '/icona-app-192.png', '/icona-app-512.png',
  'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.58.0/dist/umd/supabase.min.js'
];

self.addEventListener('install', evento => {
  evento.waitUntil(
    caches.open(VERSIONE)
      // una risorsa che non si scarica non deve bloccare l'installazione
      .then(cache => Promise.all([...PAGINE, ...RISORSE].map(url => cache.add(url).catch(() => {}))))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', evento => {
  evento.waitUntil(
    caches.keys()
      .then(nomi => Promise.all(nomi.filter(n => n.startsWith('fx-app-') && n !== VERSIONE).map(n => caches.delete(n))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', evento => {
  const richiesta = evento.request;
  if (richiesta.method !== 'GET') return;
  const url = new URL(richiesta.url);

  // Pagine dell'app: prima la rete (sempre aggiornate), senza rete la copia salvata
  if (url.origin === location.origin && PAGINE.includes(url.pathname)) {
    evento.respondWith(primaLaRete(richiesta));
    return;
  }

  // Logo, icone, libreria Supabase e font: prima la copia salvata (non cambiano)
  const statica = (url.origin === location.origin && RISORSE.includes(url.pathname)) ||
    url.href.startsWith('https://cdn.jsdelivr.net/npm/@supabase/supabase-js@') ||
    url.hostname === 'fonts.googleapis.com' || url.hostname === 'fonts.gstatic.com';
  if (statica) evento.respondWith(primaLaCopia(richiesta));

  // Tutto il resto (sito, Supabase, admin) non viene toccato
});

async function primaLaRete(richiesta) {
  const cache = await caches.open(VERSIONE);
  try {
    const risposta = await Promise.race([
      fetch(richiesta),
      new Promise((_, no) => setTimeout(() => no(new Error('lenta')), 5000)) // rete da palestra: dopo 5 s usa la copia
    ]);
    if (risposta.ok) cache.put(new URL(richiesta.url).pathname, risposta.clone());
    return risposta;
  } catch {
    const copia = await cache.match(new URL(richiesta.url).pathname);
    return copia || fetch(richiesta);
  }
}

async function primaLaCopia(richiesta) {
  const cache = await caches.open(VERSIONE);
  const copia = await cache.match(richiesta);
  if (copia) return copia;
  const risposta = await fetch(richiesta);
  if (risposta.ok || risposta.type === 'opaque') cache.put(richiesta, risposta.clone());
  return risposta;
}
