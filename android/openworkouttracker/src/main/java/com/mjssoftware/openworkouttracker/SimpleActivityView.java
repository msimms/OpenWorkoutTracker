package com.mjssoftware.openworkouttracker;

import androidx.appcompat.app.AppCompatActivity;
import android.widget.TextView;
import android.widget.Button;
import android.os.Bundle;

public class SimpleActivityView extends AppCompatActivity {

    TextView title1;
    TextView value1;
    TextView units1;

    TextView title2;
    TextView value2;
    TextView units2;

    TextView title3;
    TextView value3;
    TextView units3;

    Button startStopButton;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_simple_view);

        title1 = findViewById(R.id.title1);
        value1 = findViewById(R.id.value1);
        units1 = findViewById(R.id.units1);

        title2 = findViewById(R.id.title2);
        value2 = findViewById(R.id.value2);
        units2 = findViewById(R.id.units2);

        title3 = findViewById(R.id.title3);
        value3 = findViewById(R.id.value3);
        units3 = findViewById(R.id.units3);

        startStopButton = findViewById(R.id.start);

        startStopButton.setOnClickListener(view -> {
        });
    }
}