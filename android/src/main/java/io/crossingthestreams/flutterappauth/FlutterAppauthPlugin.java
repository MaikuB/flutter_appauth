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

    public static final String FAILED_TO_FETCH_CONFIGURATION = "failed to fetch configuration";
    public static final String FAILED_TO_EXCHANGE_TOKEN = "Failed to exchange token";
    private static final String AUTHORIZE_METHOD = "authorize";
    private static final String REFRESH_METHOD = "refresh";
    private static final String ERROR_AUTHORIZE_FAILED = "authorize_failed";
    private static final String ERROR_REFRESH_FAILED = "refresh_failed";
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
            case AUTHORIZE_METHOD:
                checkAndSetPendingOperation(call.method, result);
                handleAuthorizeMethod(arguments);
                break;
            case REFRESH_METHOD:
                checkAndSetPendingOperation(call.method, result);
                handleRefreshMethod(arguments);
                break;
            default:
                result.notImplemented();
        }
    }

    @SuppressWarnings("unchecked")
    private RequestParameters processCallArguments(Map<String, Object> arguments) {
        final String clientId = (String) arguments.get("clientId");
        final String issuer = (String) arguments.get("issuer");
        final String discoveryUrl = (String) arguments.get("discoveryUrl");
        final String redirectUrl = (String) arguments.get("redirectUrl");
        final String loginHint = (String) arguments.get("loginHint");
        clientSecret = (String) arguments.get("clientSecret");
        String refreshToken = null;
        if (arguments.containsKey("refreshToken")) {
            refreshToken = (String) arguments.get("refreshToken");
        }
        final ArrayList<String> scopes = (ArrayList<String>) arguments.get("scopes");
        Map<String, String> serviceConfigurationParameters = (Map<String, String>) arguments.get("serviceConfiguration");
        Map<String, String> additionalParameters = (Map<String, String>) arguments.get("additionalParameters");
        return new RequestParameters(clientId, issuer, discoveryUrl, scopes, redirectUrl, loginHint, refreshToken, serviceConfigurationParameters, additionalParameters);
    }

    private void handleAuthorizeMethod(Map<String, Object> arguments) {
        final RequestParameters requestParameters = processCallArguments(arguments);
        if (requestParameters.serviceConfigurationParameters != null) {
            AuthorizationServiceConfiguration serviceConfiguration = requestParametersToServiceConfiguration(requestParameters);
            performAuthorization(serviceConfiguration, requestParameters);
        } else {
            if (requestParameters.discoveryUrl != null) {
                AuthorizationServiceConfiguration.fetchFromUrl(Uri.parse(requestParameters.discoveryUrl), new AuthorizationServiceConfiguration.RetrieveConfigurationCallback() {
                    @Override
                    public void onFetchConfigurationCompleted(@Nullable AuthorizationServiceConfiguration serviceConfiguration, @Nullable AuthorizationException ex) {
                        if (ex == null) {
                            performAuthorization(serviceConfiguration, requestParameters);
                        } else {
                            finishWithError(ERROR_AUTHORIZE_FAILED, FAILED_TO_FETCH_CONFIGURATION);
                        }
                    }
                });
            } else {
                AuthorizationServiceConfiguration.fetchFromIssuer(Uri.parse(requestParameters.issuer), new AuthorizationServiceConfiguration.RetrieveConfigurationCallback() {
                    @Override
                    public void onFetchConfigurationCompleted(@Nullable AuthorizationServiceConfiguration serviceConfiguration, @Nullable AuthorizationException ex) {
                        if (ex == null) {
                            performAuthorization(serviceConfiguration, requestParameters);
                        } else {
                            finishWithError(ERROR_AUTHORIZE_FAILED, FAILED_TO_FETCH_CONFIGURATION);

                        }
                    }
                });
            }
        }

    }

    private AuthorizationServiceConfiguration requestParametersToServiceConfiguration(RequestParameters requestParameters) {
        return new AuthorizationServiceConfiguration(Uri.parse(requestParameters.serviceConfigurationParameters.get("authorizationEndpoint")), Uri.parse(requestParameters.serviceConfigurationParameters.get("tokenEndpoint")));
    }

    private void handleRefreshMethod(Map<String, Object> arguments) {
        final RequestParameters requestParameters = processCallArguments(arguments);
        if (requestParameters.serviceConfigurationParameters != null) {

            AuthorizationServiceConfiguration serviceConfiguration = requestParametersToServiceConfiguration(requestParameters);
            performRefresh(serviceConfiguration, requestParameters.clientId, requestParameters.redirectUrl, requestParameters.refreshToken, requestParameters.scopes, requestParameters.additionalParameters);

        } else {
            if (requestParameters.discoveryUrl != null) {
                AuthorizationServiceConfiguration.fetchFromUrl(Uri.parse(requestParameters.discoveryUrl), new AuthorizationServiceConfiguration.RetrieveConfigurationCallback() {
                    @Override
                    public void onFetchConfigurationCompleted(@Nullable AuthorizationServiceConfiguration serviceConfiguration, @Nullable AuthorizationException ex) {
                        if (ex == null) {
                            performRefresh(serviceConfiguration, requestParameters.clientId, requestParameters.redirectUrl, requestParameters.refreshToken, requestParameters.scopes, requestParameters.additionalParameters);
                        } else {
                            finishWithError(ERROR_REFRESH_FAILED, FAILED_TO_FETCH_CONFIGURATION);
                        }
                    }
                });

            } else {

                AuthorizationServiceConfiguration.fetchFromIssuer(Uri.parse(requestParameters.issuer), new AuthorizationServiceConfiguration.RetrieveConfigurationCallback() {
                    @Override
                    public void onFetchConfigurationCompleted(@Nullable AuthorizationServiceConfiguration serviceConfiguration, @Nullable AuthorizationException ex) {
                        if (ex == null) {
                            performRefresh(serviceConfiguration, requestParameters.clientId, requestParameters.redirectUrl, requestParameters.refreshToken, requestParameters.scopes, requestParameters.additionalParameters);
                        } else {
                            finishWithError(ERROR_REFRESH_FAILED, FAILED_TO_FETCH_CONFIGURATION);
                        }
                    }
                });
            }
        }
    }


    private void performAuthorization(AuthorizationServiceConfiguration serviceConfiguration, RequestParameters requestParameters) {
        AuthorizationRequest.Builder authRequestBuilder =
                new AuthorizationRequest.Builder(
                        serviceConfiguration,
                        requestParameters.clientId,
                        ResponseTypeValues.CODE,
                        Uri.parse(requestParameters.redirectUrl));
        if (requestParameters.scopes != null && !requestParameters.scopes.isEmpty()) {
            authRequestBuilder.setScopes(requestParameters.scopes);
        }

        if (requestParameters.loginHint != null) {
            authRequestBuilder.setLoginHint(requestParameters.loginHint);
        }

        if (requestParameters.additionalParameters != null && !requestParameters.additionalParameters.isEmpty()) {
            authRequestBuilder.setAdditionalParameters(requestParameters.additionalParameters);
        }

        AuthorizationRequest authRequest = authRequestBuilder.build();
        AuthorizationService authService = new AuthorizationService(registrar.context());
        Intent authIntent = authService.getAuthorizationRequestIntent(authRequest);
        registrar.activity().startActivityForResult(authIntent, RC_AUTH);
    }

    private void performRefresh(AuthorizationServiceConfiguration serviceConfiguration, String clientId, String redirectUrl, String refreshToken, ArrayList<String> scopes, Map<String, String> additionalParameters) {
        TokenRequest.Builder builder = new TokenRequest.Builder(serviceConfiguration, clientId)
                .setRefreshToken(refreshToken)
                .setRedirectUri(Uri.parse(redirectUrl));

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
                    finishWithError(ERROR_REFRESH_FAILED, FAILED_TO_EXCHANGE_TOKEN);
                }
            }
        };
        if (clientSecret == null) {
            authService.performTokenRequest(tokenRequest, tokenResponseCallback);
        } else {
            authService.performTokenRequest(tokenRequest, new ClientSecretBasic(clientSecret), tokenResponseCallback);
        }

    }


    private void finishWithSuccess(Object data) {
        pendingOperation.result.success(data);
        pendingOperation = null;
    }

    private void finishWithError(String errorCode, String errorMessage) {
        pendingOperation.result.error(errorCode, errorMessage, null);
        pendingOperation = null;
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
                            finishWithError(ERROR_AUTHORIZE_FAILED, FAILED_TO_EXCHANGE_TOKEN);
                        }
                    }
                };
                if (clientSecret == null) {
                    authService.performTokenRequest(authResponse.createTokenExchangeRequest(), tokenResponseCallback);
                } else {
                    authService.performTokenRequest(authResponse.createTokenExchangeRequest(), new ClientSecretBasic(clientSecret), tokenResponseCallback);
                }
            } else {
                finishWithError(ERROR_AUTHORIZE_FAILED, "Failed to authorize");

            }
            return true;
        }
        return false;
    }

    private Map<String, Object> tokenResponseToMap(TokenResponse tokenResponse, AuthorizationResponse authorizationResponse) {
        Map<String, Object> responseMap = new HashMap<>();
        responseMap.put("accessToken", tokenResponse.accessToken);
        responseMap.put("accessTokenExpirationTime", tokenResponse.accessTokenExpirationTime);
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

    private class RequestParameters {
        final String clientId;
        final String issuer;
        final String discoveryUrl;
        final ArrayList<String> scopes;
        final String redirectUrl;
        final String loginHint;
        final String refreshToken;
        final Map<String, String> serviceConfigurationParameters;
        final Map<String, String> additionalParameters;

        private RequestParameters(String clientId, String issuer, String discoveryUrl, ArrayList<String> scopes, String redirectUrl, String loginHint, String refreshToken, Map<String, String> serviceConfigurationParameters, Map<String, String> additionalParameters) {
            this.clientId = clientId;
            this.issuer = issuer;
            this.discoveryUrl = discoveryUrl;
            this.scopes = scopes;
            this.redirectUrl = redirectUrl;
            this.loginHint = loginHint;
            this.refreshToken = refreshToken;
            this.serviceConfigurationParameters = serviceConfigurationParameters;
            this.additionalParameters = additionalParameters;
        }
    }

}

