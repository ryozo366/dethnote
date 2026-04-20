package com.deathnote.death;

import com.deathnote.DeathNoteMod;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.world.damagesource.DamageTypes;
import net.minecraft.world.effect.MobEffectInstance;
import net.minecraft.world.effect.MobEffects;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.LightningBolt;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.level.Level;
import net.minecraftforge.event.TickEvent;
import net.minecraftforge.eventbus.api.SubscribeEvent;
import net.minecraftforge.fml.common.Mod;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.UUID;

@Mod.EventBusSubscriber(modid = DeathNoteMod.MODID)
public class DeathScheduler {
    private static final Map<UUID, PendingDeath> PENDING = new HashMap<>();

    public static boolean isScheduled(LivingEntity target) {
        return PENDING.containsKey(target.getUUID());
    }

    public static void schedule(ServerLevel level, LivingEntity target, ServerPlayer writer,
                                DeathCause cause, int delayTicks) {
        PENDING.put(target.getUUID(), new PendingDeath(target.getUUID(), writer.getUUID(), cause, delayTicks));
    }

    @SubscribeEvent
    public static void onServerTick(TickEvent.ServerTickEvent event) {
        if (event.phase != TickEvent.Phase.END) return;
        if (event.getServer() == null) return;

        Iterator<Map.Entry<UUID, PendingDeath>> it = PENDING.entrySet().iterator();
        while (it.hasNext()) {
            PendingDeath pd = it.next().getValue();
            pd.ticksLeft--;
            if (pd.ticksLeft <= 0) {
                executeDeath(event.getServer(), pd);
                it.remove();
            }
        }
    }

    private static void executeDeath(MinecraftServer server, PendingDeath pd) {
        LivingEntity target = null;
        for (ServerLevel lvl : server.getAllLevels()) {
            Entity e = lvl.getEntity(pd.targetId);
            if (e instanceof LivingEntity le) { target = le; break; }
        }
        if (target == null) return;
        ServerLevel world = (ServerLevel) target.level();

        switch (pd.cause) {
            case HEART_ATTACK -> {
                world.playSound(null, target.blockPosition(), SoundEvents.PLAYER_HURT, target.getSoundSource(), 1.0F, 0.6F);
                target.hurt(target.damageSources().magic(), Float.MAX_VALUE);
            }
            case EXPLOSION -> world.explode(null, target.getX(), target.getY(), target.getZ(),
                    4.0F, Level.ExplosionInteraction.NONE);
            case LIGHTNING -> {
                LightningBolt bolt = EntityType.LIGHTNING_BOLT.create(world);
                if (bolt != null) {
                    bolt.moveTo(target.getX(), target.getY(), target.getZ());
                    world.addFreshEntity(bolt);
                }
                target.hurt(target.damageSources().lightningBolt(), Float.MAX_VALUE);
            }
            case FIRE -> {
                target.setSecondsOnFire(20);
                target.hurt(target.damageSources().inFire(), Float.MAX_VALUE);
            }
            case SUFFOCATION -> target.hurt(target.damageSources().source(DamageTypes.IN_WALL), Float.MAX_VALUE);
            case FALL -> target.hurt(target.damageSources().fall(), Float.MAX_VALUE);
            case DROWNING -> target.hurt(target.damageSources().drown(), Float.MAX_VALUE);
            case POISON -> {
                target.addEffect(new MobEffectInstance(MobEffects.POISON, 200, 4));
                target.hurt(target.damageSources().magic(), target.getMaxHealth() * 2);
            }
            case WITHER -> {
                target.addEffect(new MobEffectInstance(MobEffects.WITHER, 200, 4));
                target.hurt(target.damageSources().wither(), target.getMaxHealth() * 2);
            }
            case ACCIDENT -> target.hurt(target.damageSources().generic(), Float.MAX_VALUE);
        }
    }

    public static void clearAll() { PENDING.clear(); }

    private static class PendingDeath {
        final UUID targetId;
        final UUID writerId;
        final DeathCause cause;
        int ticksLeft;

        PendingDeath(UUID targetId, UUID writerId, DeathCause cause, int ticksLeft) {
            this.targetId = targetId;
            this.writerId = writerId;
            this.cause = cause;
            this.ticksLeft = ticksLeft;
        }
    }
}
