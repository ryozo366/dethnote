package com.deathnote.client;

import com.deathnote.client.gui.DeathNoteScreen;
import net.minecraft.client.Minecraft;
import net.minecraft.world.InteractionHand;
import net.minecraftforge.api.distmarker.Dist;
import net.minecraftforge.api.distmarker.OnlyIn;

public final class ClientHooks {
    public static void openDeathNoteScreen(InteractionHand hand) {
        openOnClient(hand);
    }

    @OnlyIn(Dist.CLIENT)
    private static void openOnClient(InteractionHand hand) {
        Minecraft.getInstance().setScreen(new DeathNoteScreen(hand));
    }

    private ClientHooks() {}
}
