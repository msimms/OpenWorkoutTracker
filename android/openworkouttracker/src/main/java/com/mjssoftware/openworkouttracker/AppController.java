package com.mjssoftware.openworkouttracker;

public class AppController {

    private static AppController instance = new AppController();

    private AppController(){}

    public static AppController getInstance(){
        return instance;
    }
}
