/**
 * Proxy preload for Node.js native fetch.
 * Node.js 22's built-in fetch (undici) does not respect HTTPS_PROXY env vars.
 * This preload sets up a global ProxyAgent when proxy env vars are detected.
 *
 * Loaded via NODE_OPTIONS="--import .../proxy-preload.mjs"
 */
import { ProxyAgent, setGlobalDispatcher } from 'undici';

const proxyUrl =
  process.env.HTTPS_PROXY ||
  process.env.HTTP_PROXY ||
  process.env.https_proxy ||
  process.env.http_proxy ||
  process.env.ALL_PROXY ||
  process.env.all_proxy;

if (proxyUrl) {
  setGlobalDispatcher(new ProxyAgent(proxyUrl));
}
