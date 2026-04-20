package com.deathnote.death;

public enum DeathCause {
    HEART_ATTACK("Heart Attack"),
    EXPLOSION("Explosion"),
    LIGHTNING("Lightning Strike"),
    FIRE("Fire"),
    SUFFOCATION("Suffocation"),
    FALL("Fall"),
    DROWNING("Drowning"),
    POISON("Poison"),
    WITHER("Wither"),
    ACCIDENT("Accident");

    private final String displayName;

    DeathCause(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }

    public static DeathCause fromString(String s) {
        if (s == null) return HEART_ATTACK;
        String key = s.trim().toUpperCase().replace(' ', '_');
        for (DeathCause c : values()) {
            if (c.name().equals(key)) return c;
            if (c.displayName.equalsIgnoreCase(s)) return c;
        }
        return HEART_ATTACK;
    }
}
