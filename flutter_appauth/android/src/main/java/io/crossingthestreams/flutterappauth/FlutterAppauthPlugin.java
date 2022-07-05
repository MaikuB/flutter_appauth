package io.crossingthestreams.flutterappauth;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import net.openid.appauth.AppAuthConfiguration;
import net.openid.appauth.AuthorizationException;
import net.openid.appauth.AuthorizationRequest;
import net.openid.appauth.AuthorizationResponse;
import net.openid.appauth.AuthorizationService;
import net.openid.appauth.AuthorizationServiceConfiguration;
import net.openid.appauth.ClientSecretBasic;
import net.openid.appauth.EndSessionRequest;
import net.openid.appauth.EndSessionResponse;
import net.openid.appauth.ResponseTypeValues;
import net.openid.appauth.TokenRequest;
import net.openid.appauth.TokenResponse;
import net.openid.appauth.connectivity.DefaultConnectionBuilder;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import android.text.TextUtils;

/**
 * FlutterAppauthPlugin
 */
public class FlutterAppauthPlugin implements FlutterPlugin, MethodCallHandler, PluginRegistry.ActivityResultListener, ActivityAware {
    private static final String AUTHORIZE_AND_EXCHANGE_CODE_METHOD = "authorizeAndExchangeCode";
    private static final String AUTHORIZE_METHOD = "authorize";
    private static final String TOKEN_METHOD = "token";
    private static final String END_SESSION_METHOD = "endSession";

    private static final String DISCOVERY_ERROR_CODE = "discovery_failed";
    private static final String AUTHORIZE_AND_EXCHANGE_CODE_ERROR_CODE = "authorize_and_exchange_code_failed";
    private static final String AUTHORIZE_ERROR_CODE = "authorize_failed";
    private static final String TOKEN_ERROR_CODE = "token_failed";
    private static final String END_SESSION_ERROR_CODE = "end_session_failed";
    private static final String NULL_INTENT_ERROR_CODE = "null_intent";
    private static final String INVALID_CLAIMS_ERROR_CODE = "invalid_claims";

    private static final String DISCOVERY_ERROR_MESSAGE_FORMAT = "Error retrieving discovery document: [error: %s, description: %s]";
    private static final String TOKEN_ERROR_MESSAGE_FORMAT = "Failed to get token: [error: %s, description: %s]";
    private static final String AUTHORIZE_ERROR_MESSAGE_FORMAT = "Failed to authorize: [error: %s, description: %s]";
    private static final String END_SESSION_ERROR_MESSAGE_FORMAT = "Failed to end session: [error: %s, description: %s]";

    private static final String NULL_INTENT_ERROR_FORMAT = "Failed to authorize: Null intent received";

    private final int RC_AUTH_EXCHANGE_CODE = 65030;
    private final int RC_AUTH = 65031;
    private final int RC_END_SESSION = 65032;

    private Context applicationContext;
    private Activity mainActivity;
    private PendingOperation pendingOperation;
    private String clientSecret;
    private boolean allowInsecureConnections;
    private AuthorizationService defaultAuthorizationService;
    private AuthorizationService insecureAuthorizationService;

    @SuppressWarnings("deprecation")
    public static void registerWith(io.flutter.plugin.common.PluginRegistry.Registrar registrar) {
        final FlutterAppauthPlugin plugin = new FlutterAppauthPlugin();
        plugin.setActivity(registrar.activity());
        plugin.onAttachedToEngine(registrar.context(), registrar.messenger());
        registrar.addActivityResultListener(plugin);
        registrar.addViewDestroyListener(
                new PluginRegistry.ViewDestroyListener() {
                    @Override
                    public boolean onViewDestroy(io.flutter.view.FlutterNativeView view) {
                        plugin.disposeAuthorizationServices();
                        return false;
                    }
                });
    }


    private void setActivity(Activity flutterActivity) {
        this.mainActivity = flutterActivity;
    }

    private void onAttachedToEngine(Context context, BinaryMessenger binaryMessenger) {
        this.applicationContext = context;
        defaultAuthorizationService = new AuthorizationService(this.applicationContext);
        AppAuthConfiguration.Builder authConfigBuilder = new AppAuthConfiguration.Builder();
        authConfigBuilder.setConnectionBuilder(InsecureConnectionBuilder.INSTANCE);
        authConfigBuilder.setSkipIssuerHttpsCheck(true);
        insecureAuthorizationService = new AuthorizationService(applicationContext, authConfigBuilder.build());
        final MethodChannel channel = new MethodChannel(binaryMessenger, "crossingthestreams.io/flutter_appauth");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        onAttachedToEngine(binding.getApplicationContext(), binding.getBinaryMessenger());
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        disposeAuthorizationServices();
    }

    @Override
    public void onAttachedToActivity(ActivityPluginBinding binding) {
        binding.addActivityResultListener(this);
        mainActivity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        this.mainActivity = null;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
        binding.addActivityResultListener(this);
        mainActivity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivity() {
        this.mainActivity = null;
    }

    private void disposeAuthorizationServices() {
        defaultAuthorizationService.dispose();
        insecureAuthorizationService.dispose();
        defaultAuthorizationService = null;
        insecureAuthorizationService = null;
    }

    private void checkAndSetPendingOperation(String method, Result result) {
        if (pendingOperation != null) {
            throw new IllegalStateException(
                    "Concurrent operations detected: " + pendingOperation.method + ", " + method);
        }
        pendingOperation = new PendingOperation(method, result);
    }


    @Override
    public void onMethodCall(MethodCall call, @NonNull Result result) {
        Map<String, Object> arguments = call.arguments();
        switch (call.method) {
            case AUTHORIZE_AND_EXCHANGE_CODE_METHOD:
                try {
                    checkAndSetPendingOperation(call.method, result);
                    handleAuthorizeMethodCall(arguments, true);
                } catch (Exception ex) {
                    finishWithError(AUTHORIZE_AND_EXCHANGE_CODE_ERROR_CODE, ex.getLocalizedMessage(), getCauseFromException(ex));
                }
                break;
            case AUTHORIZE_METHOD:
                try {
                    checkAndSetPendingOperation(call.method, result);
                    handleAuthorizeMethodCall(arguments, false);
                } catch (Exception ex) {
                    finishWithError(AUTHORIZE_ERROR_CODE, ex.getLocalizedMessage(), getCauseFromException(ex));
                }
                break;
            case TOKEN_METHOD:
                try {
                    checkAndSetPendingOperation(call.method, result);
                    handleTokenMethodCall(arguments);
                } catch (Exception ex) {
                    finishWithError(TOKEN_ERROR_CODE, ex.getLocalizedMessage(), getCauseFromException(ex));
                }
                break;
            case END_SESSION_METHOD:
                try {
                    checkAndSetPendingOperation(call.method, result);
                    handleEndSessionMethodCall(arguments);
                } catch (Exception ex) {
                    finishWithError(END_SESSION_ERROR_CODE, ex.getLocalizedMessage(), getCauseFromException(ex));
                }
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
        final String nonce = (String) arguments.get("nonce");
        clientSecret = (String) arguments.get("clientSecret");
        final ArrayList<String> scopes = (ArrayList<String>) arguments.get("scopes");
        final ArrayList<String> promptValues = (ArrayList<String>) arguments.get("promptValues");
        Map<String, String> serviceConfigurationParameters = (Map<String, String>) arguments.get("serviceConfiguration");
        Map<String, String> additionalParameters = (Map<String, String>) arguments.get("additionalParameters");
        allowInsecureConnections = (boolean) arguments.get("allowInsecureConnections");
        final String responseMode = (String) arguments.get("responseMode");

        return new AuthorizationTokenRequestParameters(clientId, issuer, discoveryUrl, scopes, redirectUrl, serviceConfigurationParameters, additionalParameters, loginHint, nonce, promptValues, responseMode);
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
        String authorizationCode = null;
        if (arguments.containsKey("authorizationCode")) {
            authorizationCode = (String) arguments.get("authorizationCode");
        }
        String codeVerifier = null;
        if (arguments.containsKey("codeVerifier")) {
            codeVerifier = (String) arguments.get("codeVerifier");
        }
        String nonce = null;
        if (arguments.containsKey("nonce")) {
            nonce = (String) arguments.get("nonce");
        }
        final ArrayList<String> scopes = (ArrayList<String>) arguments.get("scopes");
        final Map<String, String> serviceConfigurationParameters = (Map<String, String>) arguments.get("serviceConfiguration");
        final Map<String, String> additionalParameters = (Map<String, String>) arguments.get("additionalParameters");
        allowInsecureConnections = (boolean) arguments.get("allowInsecureConnections");
        return new TokenRequestParameters(clientId, issuer, discoveryUrl, scopes, redirectUrl, refreshToken, authorizationCode, codeVerifier, nonce, grantType, serviceConfigurationParameters, additionalParameters);
    }

    @SuppressWarnings("unchecked")
    private EndSessionRequestParameters processEndSessionRequestArguments(Map<String, Object> arguments) {
        final String idTokenHint = (String) arguments.get("idTokenHint");
        final String postLogoutRedirectUrl = (String) arguments.get("postLogoutRedirectUrl");
        final String state = (String) arguments.get("state");
        final boolean allowInsecureConnections = (boolean) arguments.get("allowInsecureConnections");
        final String issuer = (String) arguments.get("issuer");
        final String discoveryUrl = (String) arguments.get("discoveryUrl");
        final Map<String, String> serviceConfigurationParameters = (Map<String, String>) arguments.get("serviceConfiguration");
        final Map<String, String> additionalParameters = (Map<String, String>) arguments.get("additionalParameters");
        return new EndSessionRequestParameters(idTokenHint, postLogoutRedirectUrl, state, issuer, discoveryUrl, allowInsecureConnections, serviceConfigurationParameters, additionalParameters);
    }

    private void handleAuthorizeMethodCall(Map<String, Object> arguments, final boolean exchangeCode) {
        final AuthorizationTokenRequestParameters tokenRequestParameters = processAuthorizationTokenRequestArguments(arguments);
        if (tokenRequestParameters.serviceConfigurationParameters != null) {
            AuthorizationServiceConfiguration serviceConfiguration = processServiceConfigurationParameters(tokenRequestParameters.serviceConfigurationParameters);
            performAuthorization(serviceConfiguration, tokenRequestParameters.clientId, tokenRequestParameters.redirectUrl, tokenRequestParameters.scopes, tokenRequestParameters.loginHint, tokenRequestParameters.nonce, tokenRequestParameters.additionalParameters, exchangeCode, tokenRequestParameters.promptValues, tokenRequestParameters.responseMode);
        } else {
            AuthorizationServiceConfiguration.RetrieveConfigurationCallback callback = new AuthorizationServiceConfiguration.RetrieveConfigurationCallback() {
                @Override
                public void onFetchConfigurationCompleted(@Nullable AuthorizationServiceConfiguration serviceConfiguration, @Nullable AuthorizationException ex) {
                    if (ex == null) {
                        performAuthorization(serviceConfiguration, tokenRequestParameters.clientId, tokenRequestParameters.redirectUrl, tokenRequestParameters.scopes, tokenRequestParameters.loginHint, tokenRequestParameters.nonce, tokenRequestParameters.additionalParameters, exchangeCode, tokenRequestParameters.promptValues, tokenRequestParameters.responseMode);
                    } else {
                        finishWithDiscoveryError(ex);
                    }
                }
            };
            if (tokenRequestParameters.discoveryUrl != null) {
                AuthorizationServiceConfiguration.fetchFromUrl(Uri.parse(tokenRequestParameters.discoveryUrl), callback, allowInsecureConnections ? InsecureConnectionBuilder.INSTANCE : DefaultConnectionBuilder.INSTANCE);
            } else {
                AuthorizationServiceConfiguration.fetchFromIssuer(Uri.parse(tokenRequestParameters.issuer), callback, allowInsecureConnections ? InsecureConnectionBuilder.INSTANCE : DefaultConnectionBuilder.INSTANCE);
            }
        }
    }

    private AuthorizationServiceConfiguration processServiceConfigurationParameters(Map<String, String> serviceConfigurationArguments) {
        final String endSessionEndpoint = serviceConfigurationArguments.get("endSessionEndpoint");
        return new AuthorizationServiceConfiguration(Uri.parse(serviceConfigurationArguments.get("authorizationEndpoint")), Uri.parse(serviceConfigurationArguments.get("tokenEndpoint")), null, endSessionEndpoint == null ? null : Uri.parse(endSessionEndpoint));
    }

    private void handleTokenMethodCall(Map<String, Object> arguments) {
        final TokenRequestParameters tokenRequestParameters = processTokenRequestArguments(arguments);
        if (tokenRequestParameters.serviceConfigurationParameters != null) {
            AuthorizationServiceConfiguration serviceConfiguration = processServiceConfigurationParameters(tokenRequestParameters.serviceConfigurationParameters);
            performTokenRequest(serviceConfiguration, tokenRequestParameters);
        } else {
            AuthorizationServiceConfiguration.RetrieveConfigurationCallback callback = new AuthorizationServiceConfiguration.RetrieveConfigurationCallback() {
                @Override
                public void onFetchConfigurationCompleted(@Nullable AuthorizationServiceConfiguration serviceConfiguration, @Nullable AuthorizationException ex) {
                    if (ex == null) {
                        performTokenRequest(serviceConfiguration, tokenRequestParameters);
                    } else {
                        finishWithDiscoveryError(ex);
                    }
                }
            };
            if (tokenRequestParameters.discoveryUrl != null) {
                AuthorizationServiceConfiguration.fetchFromUrl(Uri.parse(tokenRequestParameters.discoveryUrl), callback, allowInsecureConnections ? InsecureConnectionBuilder.INSTANCE : DefaultConnectionBuilder.INSTANCE);
            } else {
                AuthorizationServiceConfiguration.fetchFromIssuer(Uri.parse(tokenRequestParameters.issuer), callback, allowInsecureConnections ? InsecureConnectionBuilder.INSTANCE : DefaultConnectionBuilder.INSTANCE);
            }
        }
    }


    private void performAuthorization(AuthorizationServiceConfiguration serviceConfiguration, String clientId, String redirectUrl, ArrayList<String> scopes, String loginHint, String nonce, Map<String, String> additionalParameters, boolean exchangeCode, ArrayList<String> promptValues, String responseMode) {
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

        if (promptValues != null && !promptValues.isEmpty()) {
            authRequestBuilder.setPromptValues(promptValues);
        }

        if (responseMode != null) {
            authRequestBuilder.setResponseMode(responseMode);
        }

        if (nonce != null) {
            authRequestBuilder.setNonce(nonce);
        }

        if (additionalParameters != null && !additionalParameters.isEmpty()) {

            if(additionalParameters.containsKey("ui_locales")){
                authRequestBuilder.setUiLocales(additionalParameters.get("ui_locales"));
                additionalParameters.remove("ui_locales");
            }

            if(additionalParameters.containsKey("claims")){
                try {
                    final JSONObject claimsAsJson = new JSONObject(additionalParameters.get("claims"));
                    authRequestBuilder.setClaims(claimsAsJson);
                    additionalParameters.remove("claims");
                }
                catch (JSONException ex) {
                    finishWithError(INVALID_CLAIMS_ERROR_CODE, ex.getLocalizedMessage(), getCauseFromException(ex));
                    return;
                }
            }

            authRequestBuilder.setAdditionalParameters(additionalParameters);
        }

        AuthorizationService authorizationService = allowInsecureConnections ? insecureAuthorizationService : defaultAuthorizationService;
        Intent authIntent = authorizationService.getAuthorizationRequestIntent(authRequestBuilder.build());
        mainActivity.startActivityForResult(authIntent, exchangeCode ? RC_AUTH_EXCHANGE_CODE : RC_AUTH);
    }

    private void performTokenRequest(AuthorizationServiceConfiguration serviceConfiguration, TokenRequestParameters tokenRequestParameters) {
        TokenRequest.Builder builder = new TokenRequest.Builder(serviceConfiguration, tokenRequestParameters.clientId)
                .setRefreshToken(tokenRequestParameters.refreshToken)
                .setAuthorizationCode(tokenRequestParameters.authorizationCode)
                .setCodeVerifier(tokenRequestParameters.codeVerifier)
                .setRedirectUri(Uri.parse(tokenRequestParameters.redirectUrl));

        if (tokenRequestParameters.nonce != null) {
            builder.setNonce(tokenRequestParameters.nonce);
        }
        if (tokenRequestParameters.grantType != null) {
            builder.setGrantType(tokenRequestParameters.grantType);
        }
        if (tokenRequestParameters.scopes != null) {
            builder.setScopes(tokenRequestParameters.scopes);
        }

        if (tokenRequestParameters.additionalParameters != null && !tokenRequestParameters.additionalParameters.isEmpty()) {
            builder.setAdditionalParameters(tokenRequestParameters.additionalParameters);
        }

        AuthorizationService.TokenResponseCallback tokenResponseCallback = new AuthorizationService.TokenResponseCallback() {
            @Override
            public void onTokenRequestCompleted(
                    TokenResponse resp, AuthorizationException ex) {
                if (resp != null) {
                    Map<String, Object> responseMap = tokenResponseToMap(resp, null);
                    finishWithSuccess(responseMap);
                } else {
                    finishWithTokenError(ex);
                }
            }
        };

        TokenRequest tokenRequest = builder.build();
        AuthorizationService authorizationService = allowInsecureConnections ? insecureAuthorizationService : defaultAuthorizationService;
        if (clientSecret == null) {
            authorizationService.performTokenRequest(tokenRequest, tokenResponseCallback);
        } else {
            authorizationService.performTokenRequest(tokenRequest, new ClientSecretBasic(clientSecret), tokenResponseCallback);
        }
    }

    private void handleEndSessionMethodCall(Map<String, Object> arguments) {
        final EndSessionRequestParameters endSessionRequestParameters = processEndSessionRequestArguments(arguments);
        if (endSessionRequestParameters.serviceConfigurationParameters != null) {
            AuthorizationServiceConfiguration serviceConfiguration = processServiceConfigurationParameters(endSessionRequestParameters.serviceConfigurationParameters);
            performEndSessionRequest(serviceConfiguration, endSessionRequestParameters);
        } else {
            AuthorizationServiceConfiguration.RetrieveConfigurationCallback callback = new AuthorizationServiceConfiguration.RetrieveConfigurationCallback() {
                @Override
                public void onFetchConfigurationCompleted(@Nullable AuthorizationServiceConfiguration serviceConfiguration, @Nullable AuthorizationException ex) {
                    if (ex == null) {
                        performEndSessionRequest(serviceConfiguration, endSessionRequestParameters);
                    } else {
                        finishWithDiscoveryError(ex);
                    }
                }
            };

            if (endSessionRequestParameters.discoveryUrl != null) {
                AuthorizationServiceConfiguration.fetchFromUrl(Uri.parse(endSessionRequestParameters.discoveryUrl), callback, allowInsecureConnections ? InsecureConnectionBuilder.INSTANCE : DefaultConnectionBuilder.INSTANCE);
            } else {
                AuthorizationServiceConfiguration.fetchFromIssuer(Uri.parse(endSessionRequestParameters.issuer), callback, allowInsecureConnections ? InsecureConnectionBuilder.INSTANCE : DefaultConnectionBuilder.INSTANCE);
            }
        }
    }

    private void performEndSessionRequest(AuthorizationServiceConfiguration serviceConfiguration, final EndSessionRequestParameters endSessionRequestParameters) {
        EndSessionRequest.Builder endSessionRequestBuilder = new EndSessionRequest.Builder(serviceConfiguration);
        if (endSessionRequestParameters.idTokenHint != null) {
            endSessionRequestBuilder.setIdTokenHint(endSessionRequestParameters.idTokenHint);
        }

        if (endSessionRequestParameters.postLogoutRedirectUrl != null) {
            endSessionRequestBuilder.setPostLogoutRedirectUri(Uri.parse(endSessionRequestParameters.postLogoutRedirectUrl));
        }

        if (endSessionRequestParameters.state != null) {
            endSessionRequestBuilder.setState(endSessionRequestParameters.state);
        }

        if (endSessionRequestParameters.additionalParameters != null) {
            endSessionRequestBuilder.setAdditionalParameters(endSessionRequestParameters.additionalParameters);
        }

        final EndSessionRequest endSessionRequest = endSessionRequestBuilder.build();
        AuthorizationService authorizationService = allowInsecureConnections ? insecureAuthorizationService : defaultAuthorizationService;
        Intent endSessionIntent = authorizationService.getEndSessionRequestIntent(endSessionRequest);
        mainActivity.startActivityForResult(endSessionIntent, RC_END_SESSION);
    }

    private void finishWithTokenError(AuthorizationException ex) {
        finishWithError(TOKEN_ERROR_CODE, String.format(TOKEN_ERROR_MESSAGE_FORMAT, ex.error, ex.errorDescription), getCauseFromException(ex));
    }


    private void finishWithSuccess(Object data) {
        if (pendingOperation != null) {
            pendingOperation.result.success(data);
            pendingOperation = null;
        }
    }

    private void finishWithError(String errorCode, String errorMessage, String errorDetails) {
        if (pendingOperation != null) {
            pendingOperation.result.error(errorCode, errorMessage, errorDetails);
            pendingOperation = null;
        }
    }

    private void finishWithDiscoveryError(AuthorizationException ex) {
        finishWithError(DISCOVERY_ERROR_CODE, String.format(DISCOVERY_ERROR_MESSAGE_FORMAT, ex.error, ex.errorDescription), getCauseFromException(ex));
    }

    private void finishWithEndSessionError(AuthorizationException ex) {
        finishWithError(END_SESSION_ERROR_CODE, String.format(END_SESSION_ERROR_MESSAGE_FORMAT, ex.error, ex.errorDescription), getCauseFromException(ex));
    }

    private String getCauseFromException(Exception ex) {
        final Throwable cause = ex.getCause();
        return cause != null ? cause.getMessage() : null;
    }


    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent intent) {
        if (pendingOperation == null) {
            return false;
        }
        if (requestCode == RC_AUTH_EXCHANGE_CODE || requestCode == RC_AUTH) {
            if (intent == null) {
                finishWithError(NULL_INTENT_ERROR_CODE, NULL_INTENT_ERROR_FORMAT, null);
            } else {
                final AuthorizationResponse authResponse = AuthorizationResponse.fromIntent(intent);
                AuthorizationException ex = AuthorizationException.fromIntent(intent);
                processAuthorizationData(authResponse, ex, requestCode == RC_AUTH_EXCHANGE_CODE);
            }
            return true;
        }
        if (requestCode == RC_END_SESSION) {
            final EndSessionResponse endSessionResponse = EndSessionResponse.fromIntent(intent);
            AuthorizationException ex = AuthorizationException.fromIntent(intent);
            if (ex != null) {
                finishWithEndSessionError(ex);
            } else {
                Map<String, Object> responseMap = new HashMap<>();
                responseMap.put("state", endSessionResponse.state);
                finishWithSuccess(responseMap);
            }
        }
        return false;
    }

    private void processAuthorizationData(final AuthorizationResponse authResponse, AuthorizationException authException, boolean exchangeCode) {
        if (authException == null) {
            if (exchangeCode) {
                AppAuthConfiguration.Builder authConfigBuilder = new AppAuthConfiguration.Builder();
                if (allowInsecureConnections) {
                    authConfigBuilder.setConnectionBuilder(InsecureConnectionBuilder.INSTANCE);
                    authConfigBuilder.setSkipIssuerHttpsCheck(true);
                }

                AuthorizationService authService = new AuthorizationService(applicationContext, authConfigBuilder.build());
                AuthorizationService.TokenResponseCallback tokenResponseCallback = new AuthorizationService.TokenResponseCallback() {
                    @Override
                    public void onTokenRequestCompleted(
                            TokenResponse resp, AuthorizationException ex) {
                        if (resp != null) {
                            finishWithSuccess(tokenResponseToMap(resp, authResponse));
                        } else {
                            finishWithError(AUTHORIZE_AND_EXCHANGE_CODE_ERROR_CODE, String.format(AUTHORIZE_ERROR_MESSAGE_FORMAT, ex.error, ex.errorDescription), getCauseFromException(ex));
                        }
                    }
                };
                if (clientSecret == null) {
                    authService.performTokenRequest(authResponse.createTokenExchangeRequest(), tokenResponseCallback);
                } else {
                    authService.performTokenRequest(authResponse.createTokenExchangeRequest(), new ClientSecretBasic(clientSecret), tokenResponseCallback);
                }
            } else {
                finishWithSuccess(authorizationResponseToMap(authResponse));
            }
        } else {
            finishWithError(exchangeCode ? AUTHORIZE_AND_EXCHANGE_CODE_ERROR_CODE : AUTHORIZE_ERROR_CODE, String.format(AUTHORIZE_ERROR_MESSAGE_FORMAT, authException.error, authException.errorDescription), getCauseFromException(authException));
        }
    }

    private Map<String, Object> tokenResponseToMap(TokenResponse tokenResponse, AuthorizationResponse authResponse) {
        Map<String, Object> responseMap = new HashMap<>();
        responseMap.put("accessToken", tokenResponse.accessToken);
        responseMap.put("accessTokenExpirationTime", tokenResponse.accessTokenExpirationTime != null ? tokenResponse.accessTokenExpirationTime.doubleValue() : null);
        responseMap.put("refreshToken", tokenResponse.refreshToken);
        responseMap.put("idToken", tokenResponse.idToken);
        responseMap.put("tokenType", tokenResponse.tokenType);
        responseMap.put("scopes", tokenResponse.scope != null ? Arrays.asList(tokenResponse.scope.split(" ")) : null);
        if (authResponse != null) {
            responseMap.put("authorizationAdditionalParameters", authResponse.additionalParameters);
        }
        responseMap.put("tokenAdditionalParameters", tokenResponse.additionalParameters);

        return responseMap;
    }

    private Map<String, Object> authorizationResponseToMap(AuthorizationResponse authResponse) {
        Map<String, Object> responseMap = new HashMap<>();
        responseMap.put("codeVerifier", authResponse.request.codeVerifier);
        responseMap.put("nonce", authResponse.request.nonce);
        responseMap.put("authorizationCode", authResponse.authorizationCode);
        responseMap.put("authorizationAdditionalParameters", authResponse.additionalParameters);
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
        final String codeVerifier;
        final String nonce;
        final String authorizationCode;
        final Map<String, String> serviceConfigurationParameters;
        final Map<String, String> additionalParameters;

        private TokenRequestParameters(String clientId, String issuer, String discoveryUrl, ArrayList<String> scopes, String redirectUrl, String refreshToken, String authorizationCode, String codeVerifier, String nonce, String grantType, Map<String, String> serviceConfigurationParameters, Map<String, String> additionalParameters) {
            this.clientId = clientId;
            this.issuer = issuer;
            this.discoveryUrl = discoveryUrl;
            this.scopes = scopes;
            this.redirectUrl = redirectUrl;
            this.refreshToken = refreshToken;
            this.authorizationCode = authorizationCode;
            this.codeVerifier = codeVerifier;
            this.nonce = nonce;
            this.grantType = grantType;
            this.serviceConfigurationParameters = serviceConfigurationParameters;
            this.additionalParameters = additionalParameters;
        }
    }

    private class EndSessionRequestParameters {
        final String idTokenHint;
        final String postLogoutRedirectUrl;
        final String state;
        final String issuer;
        final String discoveryUrl;
        final boolean allowInsecureConnections;
        final Map<String, String> serviceConfigurationParameters;
        final Map<String, String> additionalParameters;

        private EndSessionRequestParameters(String idTokenHint, String postLogoutRedirectUrl, String state, String issuer, String discoveryUrl, boolean allowInsecureConnections, Map<String, String> serviceConfigurationParameters, Map<String, String> additionalParameters) {
            this.idTokenHint = idTokenHint;
            this.postLogoutRedirectUrl = postLogoutRedirectUrl;
            this.state = state;
            this.issuer = issuer;
            this.discoveryUrl = discoveryUrl;
            this.allowInsecureConnections = allowInsecureConnections;
            this.serviceConfigurationParameters = serviceConfigurationParameters;
            this.additionalParameters = additionalParameters;
        }
    }

    private class AuthorizationTokenRequestParameters extends TokenRequestParameters {
        final String loginHint;
        final ArrayList<String> promptValues;
        final String responseMode;

        private AuthorizationTokenRequestParameters(String clientId, String issuer, String discoveryUrl, ArrayList<String> scopes, String redirectUrl, Map<String, String> serviceConfigurationParameters, Map<String, String> additionalParameters, String loginHint, String nonce, ArrayList<String> promptValues, String responseMode) {
            super(clientId, issuer, discoveryUrl, scopes, redirectUrl, null, null, null, nonce, null, serviceConfigurationParameters, additionalParameters);
            this.loginHint = loginHint;
            this.promptValues = promptValues;
            this.responseMode = responseMode;
        }
    }

}
