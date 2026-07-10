package io.crossingthestreams.flutterappauth;

import android.net.Uri;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import net.openid.appauth.AuthorizationManagementActivity;

/**
 * Receives OAuth redirect URIs for flutter_appauth.
 *
 * <p>Implicit flows ({@code id_token token}, etc.) are handled manually so query and fragment
 * parameters are both parsed. Authorization code flows are forwarded to AppAuth as usual.
 *
 * <p>{@link AuthorizationManagementActivity} is always notified so the browser tab opened during
 * authorization is removed from the back stack.
 */
public class FlutterAppAuthRedirectUriReceiverActivity extends AppCompatActivity {
  @Override
  public void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);

    Uri uri = getIntent() != null ? getIntent().getData() : null;
    FlutterAppauthPlugin.handleManualImplicitRedirectUri(uri);

    startActivity(
        AuthorizationManagementActivity.createResponseHandlingIntent(this, uri));
    finish();
  }
}
