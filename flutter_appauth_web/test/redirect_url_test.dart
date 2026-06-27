import 'package:flutter_appauth_web/src/redirect_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('hasAuthorizationResponse', () {
    test('detects code in the query', () {
      expect(
        hasAuthorizationResponse(Uri.parse('https://app/?code=abc')),
        isTrue,
      );
    });

    test('detects error in the query', () {
      expect(
        hasAuthorizationResponse(Uri.parse('https://app/?error=access_denied')),
        isTrue,
      );
    });

    test('detects a response in the fragment', () {
      expect(
        hasAuthorizationResponse(Uri.parse('https://app/#code=abc&state=s')),
        isTrue,
      );
    });

    test('ignores correlation metadata on its own', () {
      expect(
        hasAuthorizationResponse(Uri.parse('https://app/?state=s&iss=i')),
        isFalse,
      );
    });

    test('is false for a plain app URL', () {
      expect(
        hasAuthorizationResponse(Uri.parse('https://app/?tab=a')),
        isFalse,
      );
    });
  });

  group('redirectUrlWithoutResponse', () {
    test('strips all response parameters to the root path', () {
      expect(
        redirectUrlWithoutResponse(Uri.parse('https://app/?code=a&state=s')),
        '/',
      );
    });

    test('preserves application-owned parameters', () {
      expect(
        redirectUrlWithoutResponse(Uri.parse('https://app/page?code=a&foo=b')),
        '/page?foo=b',
      );
    });

    test('preserves repeated application-owned keys', () {
      expect(
        redirectUrlWithoutResponse(
          Uri.parse('https://app/?tab=a&tab=b&code=c&state=s'),
        ),
        '/?tab=a&tab=b',
      );
    });

    test('strips every standard response parameter', () {
      expect(
        redirectUrlWithoutResponse(
          Uri.parse('https://app/cb?code=c&state=s&session_state=x&iss=i'),
        ),
        '/cb',
      );
    });

    test('strips response parameters from the fragment', () {
      expect(
        redirectUrlWithoutResponse(Uri.parse('https://app/cb#code=a&state=s')),
        '/cb',
      );
    });

    test('leaves a non-response fragment untouched', () {
      expect(
        redirectUrlWithoutResponse(Uri.parse('https://app/cb#section')),
        '/cb#section',
      );
    });

    test('re-encodes preserved values', () {
      expect(
        redirectUrlWithoutResponse(
          Uri.parse('https://app/?next=%2Fhome&code=c'),
        ),
        '/?next=%2Fhome',
      );
    });
  });
}
