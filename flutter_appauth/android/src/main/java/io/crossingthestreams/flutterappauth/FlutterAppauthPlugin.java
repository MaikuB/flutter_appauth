package io.crossingthestreams.flutterappauth;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;

import net.openid.appauth.AppAuthConfiguration;
import net.openid.appauth.AuthorizationException;
import net.openid.appauth.AuthorizationRequest;
import net.openid.appauth.AuthorizationResponse;
import net.openid.appauth.AuthorizationService;
import net.openid.appauth.AuthorizationServiceConfiguration;
import net.openid.appauth.ClientSecretBasic;
import net.openid.appauth.ResponseTypeValues;
import net.openid.appauth.TokenRequest;
import net.openid.appauth.TokenResponse;

import net.openid.appauth.connectivity.DefaultConnectionBuilder;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import androidx.annotation.Nullable;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.view.FlutterNativeView;

/**
 * FlutterAppauthPlugin
 */
public class FlutterAppauthPlugin implements FlutterPlugin, MethodCallHandler, PluginRegistry.ActivityResultListener, ActivityAware {
    private static final String AUTHORIZE_AND_EXCHANGE_CODE_METHOD = "authorizeAndExchangeCode";
    private static final String AUTHORIZE_METHOD = "authorize";
    private static final String TOKEN_METHOD = "token";

    private static final String DISCOVERY_ERROR_CODE = "discovery_failed";
    private static final String AUTHORIZE_AND_EXCHANGE_CODE_ERROR_CODE = "authorize_and_exchange_code_failed";
    private static final String AUTHORIZE_ERROR_CODE = "authorize_failed";
    private static final String TOKEN_ERROR_CODE = "token_failed";

    private static final String DISCOVERY_ERROR_MESSAGE_FORMAT = "Error retrieving discovery document: [error: %s, description: %s]";
    private static final String TOKEN_ERROR_MESSAGE_FORMAT = "Failed to get token: [error: %s, description: %s]";
    private static final String AUTHORIZE_ERROR_MESSAGE_FORMAT = "Failed to authorize: [error: %s, description: %s]";

    private final int RC_AUTH_EXCHANGE_CODE = 65030;
    private final int RC_AUTH = 65031;
    private Context applicationContext;
    private Activity mainActivity;
    private PendingOperation pendingOperation;
    private String clientSecret;
    private boolean allowInsecureConnections;
    private AuthorizationService defaultAuthorizationService;
    private AuthorizationService insecureAuthorizationService;

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final FlutterAppauthPlugin plugin = new FlutterAppauthPlugin();
        plugin.setActivity(registrar.activity());
        plugin.onAttachedToEngine(registrar.context(), registrar.messenger());
        registrar.addActivityResultListener(plugin);
        registrar.addViewDestroyListener(
                new PluginRegistry.ViewDestroyListener() {
                    @Override
                    public boolean onViewDestroy(FlutterNativeView view) {
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
        insecureAuthorizationService = new AuthorizationService(applicationContext, authConfigBuilder.build());
        final MethodChannel channel = new MethodChannel(binaryMessenger, "crossingthestreams.io/flutter_appauth");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        onAttachedToEngine(binding.getApplicationContext(), binding.getBinaryMessenger());
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
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
    public void onMethodCall(MethodCall call, Result result) {
        Map<String, Object> arguments = call.arguments();
        switch (call.method) {
            case AUTHORIZE_AND_EXCHANGE_CODE_METHOD:
                try {
                    checkAndSetPendingOperation(call.method, result);
                    handleAuthorizeMethodCall(arguments, true);
                } catch(Exception ex) {
                    finishWithError(AUTHORIZE_AND_EXCHANGE_CODE_ERROR_CODE, ex.getLocalizedMessage());
                }
                break;
            case AUTHORIZE_METHOD:
                try {
                    checkAndSetPendingOperation(call.method, result);
                    handleAuthorizeMethodCall(arguments, false);
                } catch(Exception ex) {
                    finishWithError(AUTHORIZE_ERROR_CODE, ex.getLocalizedMessage());
                }
                break;
            case TOKEN_METHOD:
                try {
                    checkAndSetPendingOperation(call.method, result);
                    handleTokenMethodCall(arguments);
                } catch(Exception ex) {
                    finishWithError(TOKEN_ERROR_CODE, ex.getLocalizedMessage());
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
        clientSecret = (String) arguments.get("clientSecret");
        final ArrayList<String> scopes = (ArrayList<String>) arguments.get("scopes");
        final ArrayList<String> promptValues = (ArrayList<String>) arguments.get("promptValues");
        Map<String, String> serviceConfigurationParameters = (Map<String, String>) arguments.get("serviceConfiguration");
        Map<String, String> additionalParameters = (Map<String, String>) arguments.get("additionalParameters");
        allowInsecureConnections = (boolean) arguments.get("allowInsecureConnections");
        return new AuthorizationTokenRequestParameters(clientId, issuer, discoveryUrl, scopes, redirectUrl, serviceConfigurationParameters, additionalParameters, loginHint, promptValues);
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
        final ArrayList<String> scopes = (ArrayList<String>) arguments.get("scopes");
        Map<String, String> serviceConfigurationParameters = (Map<String, String>) arguments.get("serviceConfiguration");
        Map<String, String> additionalParameters = (Map<String, String>) arguments.get("additionalParameters");
        allowInsecureConnections = (boolean) arguments.get("allowInsecureConnections");
        return new TokenRequestParameters(clientId, issuer, discoveryUrl, scopes, redirectUrl, refreshToken, authorizationCode, codeVerifier, grantType, serviceConfigurationParameters, additionalParameters);
    }

    private void handleAuthorizeMethodCall(Map<String, Object> arguments, final boolean exchangeCode) {
        final AuthorizationTokenRequestParameters tokenRequestParameters = processAuthorizationTokenRequestArguments(arguments);
        if (tokenRequestParameters.serviceConfigurationParameters != null) {
            AuthorizationServiceConfiguration serviceConfiguration = requestParametersToServiceConfiguration(tokenRequestParameters);
            performAuthorization(serviceConfiguration, tokenRequestParameters.clientId, tokenRequestParameters.redirectUrl, tokenRequestParameters.scopes, tokenRequestParameters.loginHint, tokenRequestParameters.additionalParameters, exchangeCode, tokenRequestParameters.promptValues);
        } else {
            AuthorizationServiceConfiguration.RetrieveConfigurationCallback callback = new AuthorizationServiceConfiguration.RetrieveConfigurationCallback() {
                @Override
                public void onFetchConfigurationCompleted(@Nullable AuthorizationServiceConfiguration serviceConfiguration, @Nullable AuthorizationException ex) {
                    if (ex == null) {
                        performAuthorization(serviceConfiguration, tokenRequestParameters.clientId, tokenRequestParameters.redirectUrl, tokenRequestParameters.scopes, tokenRequestParameters.loginHint, tokenRequestParameters.additionalParameters, exchangeCode, tokenRequestParameters.promptValues);
                    } else {
                        finishWithDiscoveryError(ex);
                    }
                }
            };
            if (tokenRequestParameters.discoveryUrl != null) {
                AuthorizationServiceConfiguration.fetchFromUrl(Uri.parse(tokenRequestParameters.discoveryUrl), callback, allowInsecureConnections ? InsecureConnectionBuilder.INSTANCE : DefaultConnectionBuilder.INSTANCE);
            } else {
                AuthorizationServiceConfiguration.fetchFromIssuer(Uri.parse(tokenRequestParameters.issuer), callback);
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
            performTokenRequest(serviceConfiguration, tokenRequestParameters);
        } else {
            if (tokenRequestParameters.discoveryUrl != null) {
                AuthorizationServiceConfiguration.fetchFromUrl(Uri.parse(tokenRequestParameters.discoveryUrl), new AuthorizationServiceConfiguration.RetrieveConfigurationCallback() {
                    @Override
                    public void onFetchConfigurationCompleted(@Nullable AuthorizationServiceConfiguration serviceConfiguration, @Nullable AuthorizationException ex) {
                        if (ex == null) {
                            performTokenRequest(serviceConfiguration, tokenRequestParameters);
                        } else {
                            finishWithDiscoveryError(ex);
                        }
                    }
                }, allowInsecureConnections ? InsecureConnectionBuilder.INSTANCE : DefaultConnectionBuilder.INSTANCE);

            } else {

                AuthorizationServiceConfiguration.fetchFromIssuer(Uri.parse(tokenRequestParameters.issuer), new AuthorizationServiceConfiguration.RetrieveConfigurationCallback() {
                    @Override
                    public void onFetchConfigurationCompleted(@Nullable AuthorizationServiceConfiguration serviceConfiguration, @Nullable AuthorizationException ex) {
                        if (ex == null) {
                            performTokenRequest(serviceConfiguration, tokenRequestParameters);
                        } else {
                            finishWithDiscoveryError(ex);
                        }
                    }
                });
            }
        }
    }


    private void performAuthorization(AuthorizationServiceConfiguration serviceConfiguration, String clientId, String redirectUrl, ArrayList<String> scopes, String loginHint, Map<String, String> additionalParameters, boolean exchangeCode, ArrayList<String> promptValues) {
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

        if(promptValues != null && !promptValues.isEmpty()) {
            authRequestBuilder.setPromptValues(promptValues);
        }

        if (additionalParameters != null && !additionalParameters.isEmpty()) {
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

    private void finishWithTokenError(AuthorizationException ex) {
        finishWithError(TOKEN_ERROR_CODE, String.format(TOKEN_ERROR_MESSAGE_FORMAT, ex.error, ex.errorDescription));
    }


    private void finishWithSuccess(Object data) {
        if (pendingOperation != null) {
            pendingOperation.result.success(data);
            pendingOperation = null;
        }
    }

    private void finishWithError(String errorCode, String errorMessage) {
        if (pendingOperation != null) {
            pendingOperation.result.error(errorCode, errorMessage, null);
            pendingOperation = null;
        }
    }

    private void finishWithDiscoveryError(AuthorizationException ex) {
        finishWithError(DISCOVERY_ERROR_CODE, String.format(DISCOVERY_ERROR_MESSAGE_FORMAT, ex.error, ex.errorDescription));
    }


    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent intent) {
        if (intent == null) {
            return false;
        }        
        if (pendingOperation == null) {
            return false;
        }
        if (requestCode == RC_AUTH_EXCHANGE_CODE || requestCode == RC_AUTH) {
            final AuthorizationResponse authResponse = AuthorizationResponse.fromIntent(intent);
            AuthorizationException ex = AuthorizationException.fromIntent(intent);
            processAuthorizationData(authResponse, ex, requestCode == RC_AUTH_EXCHANGE_CODE);
            return true;
        }
        return false;
    }

    private void processAuthorizationData(final AuthorizationResponse authResponse, AuthorizationException authException, boolean exchangeCode) {
        if (authException == null) {
            if (exchangeCode) {
                AppAuthConfiguration.Builder authConfigBuilder = new AppAuthConfiguration.Builder();
                if (allowInsecureConnections) {
                    authConfigBuilder.setConnectionBuilder(InsecureConnectionBuilder.INSTANCE);
                }

                AuthorizationService authService = new AuthorizationService(applicationContext, authConfigBuilder.build());
                AuthorizationService.TokenResponseCallback tokenResponseCallback = new AuthorizationService.TokenResponseCallback() {
                    @Override
                    public void onTokenRequestCompleted(
                            TokenResponse resp, AuthorizationException ex) {
                        if (resp != null) {
                            finishWithSuccess(tokenResponseToMap(resp, authResponse));
                        } else {
                            finishWithError(AUTHORIZE_AND_EXCHANGE_CODE_ERROR_CODE, String.format(AUTHORIZE_ERROR_MESSAGE_FORMAT, ex.error, ex.errorDescription));
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
            finishWithError(exchangeCode ? AUTHORIZE_AND_EXCHANGE_CODE_ERROR_CODE : AUTHORIZE_ERROR_CODE, String.format(AUTHORIZE_ERROR_MESSAGE_FORMAT, authException.error, authException.errorDescription));
        }
    }

    private Map<String, Object> tokenResponseToMap(TokenResponse tokenResponse, AuthorizationResponse authResponse) {
        Map<String, Object> responseMap = new HashMap<>();
        responseMap.put("accessToken", tokenResponse.accessToken);
        responseMap.put("accessTokenExpirationTime", tokenResponse.accessTokenExpirationTime != null ? tokenResponse.accessTokenExpirationTime.doubleValue() : null);
        responseMap.put("refreshToken", tokenResponse.refreshToken);
        responseMap.put("idToken", tokenResponse.idToken);
        responseMap.put("tokenType", tokenResponse.tokenType);
        if (authResponse != null) {
            responseMap.put("authorizationAdditionalParameters", authResponse.additionalParameters);
        }
        responseMap.put("tokenAdditionalParameters", tokenResponse.additionalParameters);

        return responseMap;
    }

    private Map<String, Object> authorizationResponseToMap(AuthorizationResponse authResponse) {
        Map<String, Object> responseMap = new HashMap<>();
        responseMap.put("codeVerifier", authResponse.request.codeVerifier);
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
        final String authorizationCode;
        final Map<String, String> serviceConfigurationParameters;
        final Map<String, String> additionalParameters;

        private TokenRequestParameters(String clientId, String issuer, String discoveryUrl, ArrayList<String> scopes, String redirectUrl, String refreshToken, String authorizationCode, String codeVerifier, String grantType, Map<String, String> serviceConfigurationParameters, Map<String, String> additionalParameters) {
            this.clientId = clientId;
            this.issuer = issuer;
            this.discoveryUrl = discoveryUrl;
            this.scopes = scopes;
            this.redirectUrl = redirectUrl;
            this.refreshToken = refreshToken;
            this.authorizationCode = authorizationCode;
            this.codeVerifier = codeVerifier;
            this.grantType = grantType;
            this.serviceConfigurationParameters = serviceConfigurationParameters;
            this.additionalParameters = additionalParameters;
        }
    }

    private class AuthorizationTokenRequestParameters extends TokenRequestParameters {
        final String loginHint;
        final ArrayList<String> promptValues;

        private AuthorizationTokenRequestParameters(String clientId, String issuer, String discoveryUrl, ArrayList<String> scopes, String redirectUrl, Map<String, String> serviceConfigurationParameters, Map<String, String> additionalParameters, String loginHint, ArrayList<String> promptValues) {
            super(clientId, issuer, discoveryUrl, scopes, redirectUrl, null, null, null, null, serviceConfigurationParameters, additionalParameters);
            this.loginHint = loginHint;
            this.promptValues = promptValues;
        }
    }

}

