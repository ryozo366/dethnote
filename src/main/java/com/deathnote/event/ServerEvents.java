package com.deathnote.event;

import com.deathnote.DeathNoteMod;
import com.deathnote.death.DeathScheduler;
import net.minecraftforge.event.server.ServerStoppingEvent;
import net.minecraftforge.eventbus.api.SubscribeEvent;
import net.minecraftforge.fml.common.Mod;

@Mod.EventBusSubscriber(modid = DeathNoteMod.MODID)
public class ServerEvents {

    @SubscribeEvent
    public static void onServerStopping(ServerStoppingEvent event) {
        DeathScheduler.clearAll();
    }
}
