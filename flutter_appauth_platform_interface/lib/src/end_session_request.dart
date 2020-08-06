class EndSessionRequest {
  final String idTokenHint;
  final String postLogoutRedirectUrl;

  const EndSessionRequest(
    this.idTokenHint,
    this.postLogoutRedirectUrl,
  );
}
