#!/usr/bin/env bash
# Monta o site publicado no Netlify em dist/:
#
#   dist/index.html      <- landing (a porta de entrada do domínio)
#   dist/og-image.png    <- card de compartilhamento da landing
#   dist/favicon.png     <- ícone (copiado do app)
#   dist/app/            <- app Flutter (compilado com --base-href /app/)
#
# Antes o app Flutter era publicado na raiz e a landing ficava escondida
# em /landing/ — quem entrava no domínio caía direto no login.
set -euo pipefail
cd "$(dirname "$0")/.."

flutter build web --release --base-href /app/

rm -rf dist
mkdir -p dist/app
cp -R build/web/. dist/app/

# A landing sobe da subpasta para a raiz do site.
mv dist/app/landing/index.html dist/index.html
mv dist/app/landing/og-image.png dist/og-image.png
rm -rf dist/app/landing
cp dist/app/favicon.png dist/favicon.png

# Kill-switch: visitantes antigos têm o service worker do Flutter
# registrado na RAIZ (o app morava lá) servindo o app inteiro do cache —
# sem isto, eles nunca veriam a landing nova. Este worker se instala por
# cima do antigo, desregistra a si mesmo e recarrega as abas abertas.
cat > dist/flutter_service_worker.js <<'EOF'
self.addEventListener('install', function () { self.skipWaiting(); });
self.addEventListener('activate', function (event) {
  event.waitUntil(
    caches.keys()
      .then(function (keys) { return Promise.all(keys.map(function (k) { return caches.delete(k); })); })
      .then(function () { return self.registration.unregister(); })
      .then(function () { return self.clients.matchAll({ type: 'window' }); })
      .then(function (clients) { clients.forEach(function (c) { c.navigate(c.url); }); })
  );
});
EOF

echo "dist/ pronto:"
find dist -maxdepth 2 -name "*.html" -o -maxdepth 1 -type f | sort
