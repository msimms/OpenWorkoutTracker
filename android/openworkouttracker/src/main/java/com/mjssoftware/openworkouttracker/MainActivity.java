package com.mjssoftware.openworkouttracker;

import androidx.appcompat.app.AppCompatActivity;

import android.view.MenuItem;
import android.view.View;
import android.widget.Button;
import android.widget.PopupMenu;
import android.os.Bundle;

public class MainActivity extends AppCompatActivity {

    Button start_btn;
    Button view_btn;
    Button edit_btn;
    Button reset_btn;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        start_btn = findViewById(R.id.start_workout);
        view_btn = findViewById(R.id.view);
        edit_btn = findViewById(R.id.edit);
        reset_btn = findViewById(R.id.reset);

        start_btn.setOnClickListener(view -> {
            PopupMenu popup = new PopupMenu(MainActivity.this, start_btn);
            popup.getMenu().add("Foo");

            popup.setOnMenuItemClickListener(new PopupMenu.OnMenuItemClickListener() {
                public boolean onMenuItemClick(MenuItem item) {
                    return true;
                }
            });

            popup.show();
        });

        view_btn.setOnClickListener(view -> {
        });

        edit_btn.setOnClickListener(view -> {
        });

        reset_btn.setOnClickListener(view -> {
        });
    }
}