// A minimal expo-updates server (protocol 1) for this reproduction. It serves the update in
// updates/current, which scripts/publish-update.sh writes. Without updates/current, it answers
// 204 (no update). Run it with `node scripts/serve-update.js`. On Android, also run
// `adb reverse tcp:3000 tcp:3000`; the iOS simulator reaches the Mac directly.
const crypto = require('crypto');
const fs = require('fs');
const http = require('http');
const path = require('path');

const PORT = 3000;
const RUNTIME_VERSION = '1';
const UPDATE_DIR = path.join(__dirname, '..', 'updates', 'current');
const BASE_URL = `http://127.0.0.1:${PORT}`;
const CONTENT_TYPES = { png: 'image/png', jpg: 'image/jpeg', ttf: 'font/ttf', json: 'application/json' };

const sha256Base64Url = (buffer) => crypto.createHash('sha256').update(buffer).digest('base64url');
const md5Hex = (buffer) => crypto.createHash('md5').update(buffer).digest('hex');

function asset(relativePath, ext, contentType) {
  const buffer = fs.readFileSync(path.join(UPDATE_DIR, relativePath));
  return {
    hash: sha256Base64Url(buffer),
    key: md5Hex(buffer),
    contentType,
    fileExtension: `.${ext}`,
    url: `${BASE_URL}/assets?path=${encodeURIComponent(relativePath)}`,
  };
}

function manifest(platform) {
  const metadata = JSON.parse(fs.readFileSync(path.join(UPDATE_DIR, 'metadata.json'), 'utf8'));
  const files = metadata.fileMetadata[platform];
  const launchAsset = asset(files.bundle, 'bundle', 'application/javascript');
  const hex = crypto.createHash('sha256').update(launchAsset.hash).digest('hex');
  const id = `${hex.slice(0, 8)}-${hex.slice(8, 12)}-4${hex.slice(13, 16)}-8${hex.slice(17, 20)}-${hex.slice(20, 32)}`;
  return {
    id,
    createdAt: fs.statSync(path.join(UPDATE_DIR, 'metadata.json')).mtime.toISOString(),
    runtimeVersion: RUNTIME_VERSION,
    launchAsset,
    assets: files.assets.map((a) => asset(a.path, a.ext, CONTENT_TYPES[a.ext] ?? 'application/octet-stream')),
    metadata: {},
    extra: {
      expoClient: JSON.parse(fs.readFileSync(path.join(UPDATE_DIR, 'expoConfig.json'), 'utf8')),
    },
  };
}

http
  .createServer((req, res) => {
    const url = new URL(req.url, BASE_URL);
    console.log(new Date().toISOString(), req.method, url.pathname, url.search);
    if (url.pathname === '/api/manifest') {
      const headers = { 'expo-protocol-version': '1', 'expo-sfv-version': '0', 'cache-control': 'private, max-age=0' };
      if (
        !['android', 'ios'].includes(req.headers['expo-platform']) ||
        req.headers['expo-runtime-version'] !== RUNTIME_VERSION ||
        !fs.existsSync(path.join(UPDATE_DIR, 'metadata.json'))
      ) {
        res.writeHead(204, headers).end();
        return;
      }
      const body = JSON.stringify(manifest(req.headers['expo-platform']));
      console.log('  serving update', JSON.parse(body).id);
      res.writeHead(200, { ...headers, 'content-type': 'application/json' }).end(body);
    } else if (url.pathname === '/assets') {
      const file = path.join(UPDATE_DIR, url.searchParams.get('path') ?? '');
      if (!file.startsWith(UPDATE_DIR) || !fs.existsSync(file)) {
        res.writeHead(404).end();
        return;
      }
      res.writeHead(200, { 'content-type': 'application/octet-stream' });
      fs.createReadStream(file).pipe(res);
    } else {
      res.writeHead(404).end();
    }
  })
  .listen(PORT, () => console.log(`expo-updates test server on ${BASE_URL}`));
