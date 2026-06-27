// Source for the vendored ../assets/appauth.bundle.js (built by js/build.sh).
// esbuild bundles this as an IIFE; the global is assigned explicitly at the
// bottom rather than via --global-name, because a star re-export shadows local
// named exports. AppAuth-JS' Node-only deps (follow-redirects, form-data,
// opener) are unreferenced here and tree-shaken out of the browser build.
import * as appauth from '@openid/appauth';

// The stock RedirectRequestHandler reads the response from the URL fragment,
// but the code flow (response_mode=query) returns it in the query string.
// Return whichever leg actually carries a response, preferring the query.
class QueryFirstStringUtils extends appauth.BasicQueryStringUtils {
  parse(input, _useHash) {
    const fromQuery = this.parseQueryString(input.search);
    if (hasAuthorizationResponse(fromQuery)) {
      return fromQuery;
    }
    const fromFragment = this.parseQueryString(input.hash);
    return hasAuthorizationResponse(fromFragment) ? fromFragment : fromQuery;
  }
}

// `state` is correlation data, not a response on its own.
function hasAuthorizationResponse(params) {
  return !!(params && (params.code || params.error));
}

// FetchRequestor rejects every non-2xx with just the status, discarding the
// body — but token errors (invalid_grant, ...) arrive as an HTTP 400 JSON body.
// Return that body so BaseTokenRequestHandler can build a structured TokenError.
class BodyPreservingRequestor extends appauth.FetchRequestor {
  async xhr(settings) {
    const isJson =
        settings.dataType && settings.dataType.toLowerCase() === 'json';
    const headers = Object.assign({}, settings.headers);
    if (isJson && !headers['Accept']) {
      headers['Accept'] = 'application/json, text/javascript, */*; q=0.01';
    }
    const response = await fetch(settings.url, {
      method: settings.method,
      body: settings.data,
      headers,
    });
    const contentType = response.headers.get('content-type');
    const wantsJson =
        isJson ||
        (contentType && contentType.indexOf('application/json') !== -1);
    const text = await response.text();
    let parsed = null;
    if (wantsJson && text) {
      try {
        parsed = JSON.parse(text);
      } catch (_) {
        parsed = null;
      }
    }
    if (response.status >= 200 && response.status < 300) {
      return parsed !== null ? parsed : text;
    }
    // Only surface a non-2xx body that is an OAuth error; otherwise a non-error
    // body (e.g. a 500 without `error`) would masquerade as a success.
    if (parsed && typeof parsed === 'object' && parsed.error) {
      return parsed;
    }
    throw new appauth.AppAuthError(
      response.status.toString(),
      text || response.statusText,
    );
  }
}

// AppAuth-JS rejects with an AppAuthError whose `extras` is a Token/Authorization
// error carrying the structured fields; flatten them for the Dart boundary.
function normalizeError(e, fallbackCode) {
  const extras = (e && e.extras) || {};
  return {
    error: extras.error || fallbackCode || 'unknown_error',
    errorDescription: extras.errorDescription ||
        String((e && e.message) || e || ''),
    errorUri: extras.errorUri,
  };
}

function createRedirectRequestHandler() {
  return new appauth.RedirectRequestHandler(
    new appauth.LocalStorageBackend(),
    new QueryFirstStringUtils(),
    window.location,
    new appauth.DefaultCrypto(),
  );
}

// A discovery URL is fetched directly; an issuer has the well-known path
// appended. Both return an envelope so structured errors cross into Dart.
async function fetchServiceConfiguration(issuer, discoveryUrl, requestor) {
  const req = requestor || new appauth.FetchRequestor();
  try {
    const configuration = discoveryUrl
        ? new appauth.AuthorizationServiceConfiguration(
            await req.xhr({ url: discoveryUrl, method: 'GET', dataType: 'json' }))
        : await appauth.AuthorizationServiceConfiguration.fetchFromIssuer(
            issuer, req);
    return { ok: true, configuration };
  } catch (e) {
    return { ok: false, error: normalizeError(e, 'discovery_failed') };
  }
}

async function performTokenRequest(config, request, requestor) {
  const handler = new appauth.BaseTokenRequestHandler(
    requestor || new BodyPreservingRequestor());
  try {
    return { ok: true, response: await handler.performTokenRequest(config, request) };
  } catch (e) {
    return { ok: false, error: normalizeError(e, 'token_request_failed') };
  }
}

globalThis.AppAuth = Object.assign({}, appauth, {
  createRedirectRequestHandler,
  fetchServiceConfiguration,
  performTokenRequest,
});
