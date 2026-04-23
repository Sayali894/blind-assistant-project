package com.blindassist.app;

import io.flutter.embedding.android.FlutterActivity;
import android.os.Bundle;
import android.view.WindowManager;

public class MainActivity extends FlutterActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // Keep screen on while app is running
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
    }
}
