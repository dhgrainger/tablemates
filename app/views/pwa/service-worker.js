// Tablemates is always-online for now: the service worker exists so the app
// can be installed to a home screen. It takes control straight away and lets
// every request go to the network. Offline support and push notifications
// are out of scope for the MVP.
self.addEventListener("install", () => self.skipWaiting())
self.addEventListener("activate", (event) => event.waitUntil(self.clients.claim()))
