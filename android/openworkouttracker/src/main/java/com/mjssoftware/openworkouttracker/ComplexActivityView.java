package com.mjssoftware.openworkouttracker;

import androidx.appcompat.app.AppCompatActivity;
import android.view.View;
import android.widget.Button;
import android.os.Bundle;

public class ComplexActivityView extends AppCompatActivity {

    Button startStopButton;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_complex_view);

        startStopButton = findViewById(R.id.start);

        startStopButton.setOnClickListener(view -> {
        });
    }
}