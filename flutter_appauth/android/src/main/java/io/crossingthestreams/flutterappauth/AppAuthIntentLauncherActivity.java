package io.crossingthestreams.flutterappauth;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;

public class AppAuthIntentLauncherActivity extends Activity {
  static class IntentExtraKey {
    static String INTENT = "intent";
    static String REQUEST_CODE = "requestCode";
  }

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);

    Intent intent = getIntent().getParcelableExtra(IntentExtraKey.INTENT);
    if (intent != null) {
      int requestCode = getIntent().getIntExtra(IntentExtraKey.REQUEST_CODE, 0);
      startActivityForResult(intent, requestCode);
    } else {
      finish();
    }
  }

  @Override
  protected void onActivityResult(int requestCode, int resultCode, Intent data) {
    super.onActivityResult(requestCode, resultCode, data);

    finish();

    FlutterAppauthPlugin flutterAppauthPlugin = FlutterAppauthPlugin.getInstance();
    if (flutterAppauthPlugin != null) {
      flutterAppauthPlugin.onActivityResult(requestCode, resultCode, data);
    }
  }
}