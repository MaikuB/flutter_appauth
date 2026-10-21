package io.crossingthestreams.flutterappauth;

import android.net.Uri;

import androidx.annotation.NonNull;

import net.openid.appauth.connectivity.ConnectionBuilder;

import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.URL;
import java.security.SecureRandom;
import java.security.cert.X509Certificate;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;

public class InsecureConnectionBuilder implements ConnectionBuilder {

  public static final InsecureConnectionBuilder INSTANCE = new InsecureConnectionBuilder();

  private InsecureConnectionBuilder() {}

  @NonNull
  @Override
  public HttpURLConnection openConnection(@NonNull Uri uri) throws IOException {
    HttpURLConnection conn = (HttpURLConnection) new URL(uri.toString()).openConnection();
    if (conn instanceof HttpsURLConnection) {
      try {
        SSLContext sslContext = SSLContext.getInstance("TLS");
        sslContext.init(null, new TrustManager[] { new X509TrustManager() {
          public void checkClientTrusted(X509Certificate[] chain, String authType) {}
          public void checkServerTrusted(X509Certificate[] chain, String authType) {}
          public X509Certificate[] getAcceptedIssuers() { return new X509Certificate[0]; }
        }}, new SecureRandom());
        ((HttpsURLConnection) conn).setSSLSocketFactory(sslContext.getSocketFactory());
        ((HttpsURLConnection) conn).setHostnameVerifier((hostname, session) -> true);
      } catch (Exception e) {
        throw new IOException("Failed to configure insecure connection", e);
      }
    }
    return conn;
  }
}
