const CACHE_NAME = 'stockmaster-v2';
const ASSETS = [
    '/static/manifest.json'
];

self.addEventListener('install', (e) => {
    e.waitUntil(
        caches.open(CACHE_NAME).then(cache => {
            return cache.addAll(ASSETS);
        }).then(() => self.skipWaiting())
    );
});

self.addEventListener('activate', (e) => {
    e.waitUntil(
        caches.keys().then(keys => {
            return Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)));
        }).then(() => self.clients.claim())
    );
});

self.addEventListener('fetch', (e) => {
    // Only intercept GET requests
    if (e.request.method !== 'GET') return;
    
    // Ignore API calls and dynamic paths that shouldn't be cached
    const url = new URL(e.request.url);
    if (url.pathname.startsWith('/api/') || url.pathname.startsWith('/static/uploads/')) {
        return;
    }

    // Network-First Strategy with Dynamic Caching
    e.respondWith(
        fetch(e.request).then(response => {
            // If valid response, clone and cache it
            if (response && response.status === 200) {
                const responseToCache = response.clone();
                caches.open(CACHE_NAME).then(cache => {
                    cache.put(e.request, responseToCache);
                });
            }
            return response;
        }).catch(() => {
            // If network fails, fallback to cache
            return caches.match(e.request);
        })
    );
});
