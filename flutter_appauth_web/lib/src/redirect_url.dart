// Pure helpers for the authorization response carried in the redirect URL,
// kept separate from the platform implementation so they are unit-testable
// without a browser.

// `code`/`error` identify a response to complete; the wider set is stripped
// from the address bar once a response is consumed. `state`, `iss` and
// `session_state` are correlation metadata that may legitimately sit on an app
// URL, so they never identify a response on their own.
const Set<String> _indicators = <String>{'code', 'error'};
const Set<String> _parameters = <String>{
  'code',
  'state',
  'session_state',
  'iss',
  'error',
  'error_description',
  'error_uri',
};

/// Whether [uri] carries an authorization response (a `code` or `error`) in its
/// query string or fragment.
bool hasAuthorizationResponse(Uri uri) {
  return uri.queryParameters.keys.any(_indicators.contains) ||
      (uri.fragment.isNotEmpty &&
          Uri.splitQueryString(uri.fragment).keys.any(_indicators.contains));
}

/// [uri] reduced to a root-relative URL with the authorization response
/// parameters removed and any application-owned parameters preserved.
///
/// Built by hand because `Uri.replace` treats a null query/fragment as "keep",
/// not "drop"; `queryParametersAll` preserves repeated app-owned keys.
String redirectUrlWithoutResponse(Uri uri) {
  final Map<String, List<String>> query = Map<String, List<String>>.of(
    uri.queryParametersAll,
  )..removeWhere((String key, _) => _parameters.contains(key));
  final String fragment = _strippedFragment(uri.fragment);
  final StringBuffer buffer = StringBuffer(uri.path.isEmpty ? '/' : uri.path);
  if (query.isNotEmpty) {
    buffer.write('?${_encodeQuery(query)}');
  }
  if (fragment.isNotEmpty) {
    buffer.write('#$fragment');
  }
  return buffer.toString();
}

String _strippedFragment(String fragment) {
  if (fragment.isEmpty) {
    return '';
  }
  final Map<String, String> parsed = Uri.splitQueryString(fragment);
  if (!parsed.keys.any(_parameters.contains)) {
    return fragment;
  }
  parsed.removeWhere((String key, _) => _parameters.contains(key));
  return _encodeQuery(<String, List<String>>{
    for (final MapEntry<String, String> e in parsed.entries)
      e.key: <String>[e.value],
  });
}

String _encodeQuery(Map<String, List<String>> parameters) {
  final List<String> pairs = <String>[];
  parameters.forEach((String key, List<String> values) {
    for (final String value in values) {
      pairs.add(
        '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value)}',
      );
    }
  });
  return pairs.join('&');
}
