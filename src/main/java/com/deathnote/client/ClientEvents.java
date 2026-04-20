package com.deathnote.client;

import com.deathnote.DeathNoteMod;
import com.deathnote.item.ModItems;
import com.deathnote.item.ShinigamiEyesItem;
import net.minecraft.ChatFormatting;
import net.minecraft.client.Minecraft;
import net.minecraft.client.player.LocalPlayer;
import net.minecraft.network.chat.Component;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.phys.EntityHitResult;
import net.minecraft.world.phys.HitResult;
import net.minecraftforge.api.distmarker.Dist;
import net.minecraftforge.event.TickEvent;
import net.minecraftforge.eventbus.api.SubscribeEvent;
import net.minecraftforge.fml.common.Mod;

@Mod.EventBusSubscriber(modid = DeathNoteMod.MODID, value = Dist.CLIENT)
public class ClientEvents {

    @SubscribeEvent
    public static void onClientTick(TickEvent.ClientTickEvent event) {
        if (event.phase != TickEvent.Phase.END) return;
        Minecraft mc = Minecraft.getInstance();
        LocalPlayer player = mc.player;
        if (player == null || mc.level == null) return;

        ItemStack main = player.getMainHandItem();
        ItemStack off = player.getOffhandItem();
        boolean hasEyesActive =
                (main.getItem() == ModItems.SHINIGAMI_EYES.get() && ShinigamiEyesItem.isActive(main)) ||
                (off.getItem() == ModItems.SHINIGAMI_EYES.get() && ShinigamiEyesItem.isActive(off));
        if (!hasEyesActive) return;

        HitResult hit = mc.hitResult;
        if (!(hit instanceof EntityHitResult ehr)) return;
        Entity e = ehr.getEntity();
        if (!(e instanceof LivingEntity le)) return;

        String name = le.getName().getString();
        int lifespan = computeLifespan(le);
        Component msg = Component.translatable("message.deathnote.eyes_reveal", name, lifespan)
                .withStyle(ChatFormatting.DARK_RED);
        player.displayClientMessage(msg, true);
    }

    private static int computeLifespan(LivingEntity le) {
        long seed = le.getUUID().getMostSignificantBits() ^ le.getUUID().getLeastSignificantBits();
        int base = 40 + (int)(Math.abs(seed) % 60);
        int penalty = (int)(le.getMaxHealth() / 4);
        return Math.max(1, base - penalty);
    }
}
