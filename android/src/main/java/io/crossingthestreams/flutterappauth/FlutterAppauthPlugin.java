package io.crossingthestreams.flutterappauth;

import android.content.Intent;
import android.net.Uri;

import net.openid.appauth.AuthorizationException;
import net.openid.appauth.AuthorizationRequest;
import net.openid.appauth.AuthorizationResponse;
import net.openid.appauth.AuthorizationService;
import net.openid.appauth.AuthorizationServiceConfiguration;
import net.openid.appauth.ClientSecretBasic;
import net.openid.appauth.ResponseTypeValues;
import net.openid.appauth.TokenRequest;
import net.openid.appauth.TokenResponse;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import androidx.annotation.Nullable;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * FlutterAppauthPlugin
 */
public class FlutterAppauthPlugin implements MethodCallHandler, PluginRegistry.ActivityResultListener {

    private static final String AUTHORIZE_AND_EXCHANGE_TOKEN_METHOD = "authorizeAndExchangeToken";
    private static final String TOKEN_METHOD = "token";

    private static final String DISCOVERY_ERROR_CODE = "discovery_failed";
    private static final String AUTHORIZE_ERROR_CODE = "authorize_and_exchange_token_failed";
    private static final String TOKEN_ERROR_CODE = "token_failed";

    private static final String DISCOVERY_ERROR_MESSAGE = "Error retrieving discovery document";
    private static final String TOKEN_ERROR_MESSAGE = "Failed to exchange token";
    private static final String AUTHORIZE_ERROR_MESSAGE = "Failed to authorize";

    private final Registrar registrar;
    private final int RC_AUTH = 531984;
    private PendingOperation pendingOperation;
    private String clientSecret;

    private FlutterAppauthPlugin(Registrar registrar) {
        this.registrar = registrar;
        this.registrar.addActivityResultListener(this);
    }

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "crossingthestreams.io/flutter_appauth");
        channel.setMethodCallHandler(new FlutterAppauthPlugin(registrar));
    }

    private void checkAndSetPendingOperation(String method, Result result) {
        if (pendingOperation != null) {
            throw new IllegalStateException(
                    "Concurrent operations detected: " + pendingOperation.method + ", " + method);
        }
        pendingOperation = new PendingOperation(method, result);
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        Map<String, Object> arguments = call.arguments();
        switch (call.method) {
            case AUTHORIZE_AND_EXCHANGE_TOKEN_METHOD:
                checkAndSetPendingOperation(call.method, result);
                handleAuthorizeAndExchangeTokenMethodCall(arguments);
                break;
            case TOKEN_METHOD:
                checkAndSetPendingOperation(call.method, result);
                handleTokenMethodCall(arguments);
                break;
            default:
                result.notImplemented();
        }
    }

    @SuppressWarnings("unchecked")
    private AuthorizationTokenRequestParameters processAuthorizationTokenRequestArguments(Map<String, Object> arguments) {
        final String clientId = (String) arguments.get("clientId");
        final String issuer = (String) arguments.get("issuer");
        final String discoveryUrl = (String) arguments.get("discoveryUrl");
        final String redirectUrl = (String) arguments.get("redirectUrl");
        final String loginHint = (String) arguments.get("loginHint");
        clientSecret = (String) arguments.get("clientSecret");
        final ArrayList<String> scopes = (ArrayList<String>) arguments.get("scopes");
        Map<String, String> serviceConfigurationParameters = (Map<String, String>) arguments.get("serviceConfiguration");
        Map<String, String> additionalParameters = (Map<String, String>) arguments.get("additionalParameters");
        return new AuthorizationTokenRequestParameters(clientId, issuer, discoveryUrl, scopes, redirectUrl, serviceConfigurationParameters, additionalParameters, loginHint);
    }

    @SuppressWarnings("unchecked")
    private TokenRequestParameters processTokenRequestArguments(Map<String, Object> arguments) {
        final String clientId = (String) arguments.get("clientId");
        final String issuer = (String) arguments.get("issuer");
        final String discoveryUrl = (String) arguments.get("discoveryUrl");
        final String redirectUrl = (String) arguments.get("redirectUrl");
        final String grantType = (String) arguments.get("grantType");
        clientSecret = (String) arguments.get("clientSecret");
        String refreshToken = null;
        if (arguments.containsKey("refreshToken")) {
            refreshToken = (String) arguments.get("refreshToken");
        }
        final ArrayList<String> scopes = (ArrayList<String>) arguments.get("scopes");
        Map<String, String> serviceConfigurationParameters = (Map<String, String>) arguments.get("serviceConfiguration");
        Map<String, String> additionalParameters = (Map<String, String>) arguments.get("additionalParameters");
        return new TokenRequestParameters(clientId, issuer, discoveryUrl, scopes, redirectUrl, refreshToken, grantType, serviceConfigurationParameters, additionalParameters);
    }

    private void handleAuthorizeAndExchangeTokenMethodCall(Map<String, Object> arguments) {
        final AuthorizationTokenRequestParameters tokenRequestParameters = processAuthorizationTokenRequestArguments(arguments);
        if (tokenRequestParameters.serviceConfigurationParameters != null) {
            AuthorizationServiceConfiguration serviceConfiguration = requestParametersToServiceConfiguration(tokenRequestParameters);
            performAuthorization(serviceConfiguration, tokenRequestParameters.clientId, tokenRequestParameters.redirectUrl, tokenRequestParameters.scopes, tokenRequestParameters.loginHint, tokenRequestParameters.additionalParameters);
        } else {
            if (tokenRequestParameters.discoveryUrl != null) {
                AuthorizationServiceConfiguration.fetchFromUrl(Uri.parse(tokenRequestParameters.discoveryUrl), new AuthorizationServiceConfiguration.RetrieveConfigurationCallback() {
                    @Override
                    public void onFetchConfigurationCompleted(@Nullable AuthorizationServiceConfiguration serviceConfiguration, @Nullable AuthorizationException ex) {
                        if (ex == null) {
                            performAuthorization(serviceConfiguration, tokenRequestParameters.clientId, tokenRequestParameters.redirectUrl, tokenRequestParameters.scopes, tokenRequestParameters.loginHint, tokenRequestParameters.additionalParameters);
                        } else {
                            finishWithDiscoveryError(ex.getLocalizedMessage());
                        }
                    }
                });
            } else {
                AuthorizationServiceConfiguration.fetchFromIssuer(Uri.parse(tokenRequestParameters.issuer), new AuthorizationServiceConfiguration.RetrieveConfigurationCallback() {
                    @Override
                    public void onFetchConfigurationCompleted(@Nullable AuthorizationServiceConfiguration serviceConfiguration, @Nullable AuthorizationException ex) {
                        if (ex == null) {
                            performAuthorization(serviceConfiguration, tokenRequestParameters.clientId, tokenRequestParameters.redirectUrl, tokenRequestParameters.scopes, tokenRequestParameters.loginHint, tokenRequestParameters.additionalParameters);
                        } else {
                            finishWithDiscoveryError(ex.getLocalizedMessage());

                        }
                    }
                });
            }
        }

    }

    private AuthorizationServiceConfiguration requestParametersToServiceConfiguration(TokenRequestParameters tokenRequestParameters) {
        return new AuthorizationServiceConfiguration(Uri.parse(tokenRequestParameters.serviceConfigurationParameters.get("authorizationEndpoint")), Uri.parse(tokenRequestParameters.serviceConfigurationParameters.get("tokenEndpoint")));
    }

    private void handleTokenMethodCall(Map<String, Object> arguments) {
        final TokenRequestParameters tokenRequestParameters = processTokenRequestArguments(arguments);
        if (tokenRequestParameters.serviceConfigurationParameters != null) {

            AuthorizationServiceConfiguration serviceConfiguration = requestParametersToServiceConfiguration(tokenRequestParameters);
            performTokenRequest(serviceConfiguration, tokenRequestParameters.clientId, tokenRequestParameters.redirectUrl, tokenRequestParameters.grantType, tokenRequestParameters.refreshToken, tokenRequestParameters.scopes, tokenRequestParameters.additionalParameters);

        } else {
            if (tokenRequestParameters.discoveryUrl != null) {
                AuthorizationServiceConfiguration.fetchFromUrl(Uri.parse(tokenRequestParameters.discoveryUrl), new AuthorizationServiceConfiguration.RetrieveConfigurationCallback() {
                    @Override
                    public void onFetchConfigurationCompleted(@Nullable AuthorizationServiceConfiguration serviceConfiguration, @Nullable AuthorizationException ex) {
                        if (ex == null) {
                            performTokenRequest(serviceConfiguration, tokenRequestParameters.clientId, tokenRequestParameters.redirectUrl, tokenRequestParameters.grantType, tokenRequestParameters.refreshToken, tokenRequestParameters.scopes, tokenRequestParameters.additionalParameters);
                        } else {
                            finishWithDiscoveryError(ex.getLocalizedMessage());
                        }
                    }
                });

            } else {

                AuthorizationServiceConfiguration.fetchFromIssuer(Uri.parse(tokenRequestParameters.issuer), new AuthorizationServiceConfiguration.RetrieveConfigurationCallback() {
                    @Override
                    public void onFetchConfigurationCompleted(@Nullable AuthorizationServiceConfiguration serviceConfiguration, @Nullable AuthorizationException ex) {
                        if (ex == null) {
                            performTokenRequest(serviceConfiguration, tokenRequestParameters.clientId, tokenRequestParameters.redirectUrl, tokenRequestParameters.grantType, tokenRequestParameters.refreshToken, tokenRequestParameters.scopes, tokenRequestParameters.additionalParameters);
                        } else {
                            finishWithDiscoveryError(ex.getLocalizedMessage());
                        }
                    }
                });
            }
        }
    }


    private void performAuthorization(AuthorizationServiceConfiguration serviceConfiguration, String clientId, String redirectUrl, ArrayList<String> scopes, String loginHint, Map<String, String> additionalParameters) {
        AuthorizationRequest.Builder authRequestBuilder =
                new AuthorizationRequest.Builder(
                        serviceConfiguration,
                        clientId,
                        ResponseTypeValues.CODE,
                        Uri.parse(redirectUrl));
        if (scopes != null && !scopes.isEmpty()) {
            authRequestBuilder.setScopes(scopes);
        }

        if (loginHint != null) {
            authRequestBuilder.setLoginHint(loginHint);
        }

        if (additionalParameters != null && !additionalParameters.isEmpty()) {
            authRequestBuilder.setAdditionalParameters(additionalParameters);
        }

        AuthorizationRequest authRequest = authRequestBuilder.build();
        AuthorizationService authService = new AuthorizationService(registrar.context());
        Intent authIntent = authService.getAuthorizationRequestIntent(authRequest);
        registrar.activity().startActivityForResult(authIntent, RC_AUTH);
    }

    private void performTokenRequest(AuthorizationServiceConfiguration serviceConfiguration, String clientId, String redirectUrl, String grantType, String refreshToken, ArrayList<String> scopes, Map<String, String> additionalParameters) {
        TokenRequest.Builder builder = new TokenRequest.Builder(serviceConfiguration, clientId)
                .setRefreshToken(refreshToken)
                .setRedirectUri(Uri.parse(redirectUrl));

        if (grantType != null) {
            builder.setGrantType(grantType);
        }
        if (scopes != null) {
            builder.setScopes(scopes);
        }

        if (additionalParameters != null && !additionalParameters.isEmpty()) {
            builder.setAdditionalParameters(additionalParameters);
        }

        TokenRequest tokenRequest = builder.build();
        AuthorizationService authService = new AuthorizationService(registrar.context());
        AuthorizationService.TokenResponseCallback tokenResponseCallback = new AuthorizationService.TokenResponseCallback() {
            @Override
            public void onTokenRequestCompleted(
                    TokenResponse resp, AuthorizationException ex) {
                if (resp != null) {
                    Map<String, Object> responseMap = tokenResponseToMap(resp, null);
                    finishWithSuccess(responseMap);
                } else {
                    finishWithTokenError();
                }
            }
        };
        if (clientSecret == null) {
            authService.performTokenRequest(tokenRequest, tokenResponseCallback);
        } else {
            authService.performTokenRequest(tokenRequest, new ClientSecretBasic(clientSecret), tokenResponseCallback);
        }

    }

    private void finishWithTokenError() {
        finishWithError(TOKEN_ERROR_CODE, TOKEN_ERROR_MESSAGE);
    }


    private void finishWithSuccess(Object data) {
        pendingOperation.result.success(data);
        pendingOperation = null;
    }

    private void finishWithError(String errorCode, String errorMessage) {
        pendingOperation.result.error(errorCode, errorMessage, null);
        pendingOperation = null;
    }

    private void finishWithDiscoveryError(String localizedDescription) {
        finishWithError(DISCOVERY_ERROR_CODE, DISCOVERY_ERROR_MESSAGE + localizedDescription);
    }


    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent intent) {
        if (pendingOperation == null) {
            return false;
        }
        if (requestCode == RC_AUTH) {
            final AuthorizationResponse authResponse = AuthorizationResponse.fromIntent(intent);
            AuthorizationException ex = AuthorizationException.fromIntent(intent);
            if (ex == null) {
                AuthorizationService authService = new AuthorizationService(registrar.context());
                AuthorizationService.TokenResponseCallback tokenResponseCallback = new AuthorizationService.TokenResponseCallback() {
                    @Override
                    public void onTokenRequestCompleted(
                            TokenResponse resp, AuthorizationException ex) {
                        if (resp != null) {
                            Map<String, Object> responseMap = tokenResponseToMap(resp, authResponse);
                            finishWithSuccess(responseMap);
                        } else {
                            finishWithTokenError();
                        }
                    }
                };
                if (clientSecret == null) {
                    authService.performTokenRequest(authResponse.createTokenExchangeRequest(), tokenResponseCallback);
                } else {
                    authService.performTokenRequest(authResponse.createTokenExchangeRequest(), new ClientSecretBasic(clientSecret), tokenResponseCallback);
                }
            } else {
                finishWithError(AUTHORIZE_ERROR_CODE, AUTHORIZE_ERROR_MESSAGE);

            }
            return true;
        }
        return false;
    }

    private Map<String, Object> tokenResponseToMap(TokenResponse tokenResponse, AuthorizationResponse authorizationResponse) {
        Map<String, Object> responseMap = new HashMap<>();
        responseMap.put("accessToken", tokenResponse.accessToken);
        responseMap.put("accessTokenExpirationTime", tokenResponse.accessTokenExpirationTime != null ? tokenResponse.accessTokenExpirationTime.doubleValue() : null);
        responseMap.put("refreshToken", tokenResponse.refreshToken);
        responseMap.put("idToken", tokenResponse.idToken);
        responseMap.put("tokenType", tokenResponse.tokenType);
        if (authorizationResponse != null) {
            responseMap.put("authorizationAdditionalParameters", authorizationResponse.additionalParameters);
        }
        responseMap.put("tokenAdditionalParameters", tokenResponse.additionalParameters);

        return responseMap;
    }

    private class PendingOperation {
        final String method;
        final Result result;

        PendingOperation(String method, Result result) {
            this.method = method;
            this.result = result;
        }
    }


    private class TokenRequestParameters {
        final String clientId;
        final String issuer;
        final String discoveryUrl;
        final ArrayList<String> scopes;
        final String redirectUrl;
        final String refreshToken;
        final String grantType;
        final Map<String, String> serviceConfigurationParameters;
        final Map<String, String> additionalParameters;

        private TokenRequestParameters(String clientId, String issuer, String discoveryUrl, ArrayList<String> scopes, String redirectUrl, String refreshToken, String grantType, Map<String, String> serviceConfigurationParameters, Map<String, String> additionalParameters) {
            this.clientId = clientId;
            this.issuer = issuer;
            this.discoveryUrl = discoveryUrl;
            this.scopes = scopes;
            this.redirectUrl = redirectUrl;
            this.refreshToken = refreshToken;
            this.grantType = grantType;
            this.serviceConfigurationParameters = serviceConfigurationParameters;
            this.additionalParameters = additionalParameters;
        }
    }

    private class AuthorizationTokenRequestParameters extends TokenRequestParameters {
        final String loginHint;

        private AuthorizationTokenRequestParameters(String clientId, String issuer, String discoveryUrl, ArrayList<String> scopes, String redirectUrl, Map<String, String> serviceConfigurationParameters, Map<String, String> additionalParameters, String loginHint) {
            super(clientId, issuer, discoveryUrl, scopes, redirectUrl, null, null, serviceConfigurationParameters, additionalParameters);
            this.loginHint = loginHint;
        }
    }

}

