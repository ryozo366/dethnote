package com.deathnote.network;

import com.deathnote.death.DeathCause;
import com.deathnote.item.DeathNoteItem;
import net.minecraft.network.FriendlyByteBuf;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.item.ItemStack;
import net.minecraftforge.network.NetworkEvent;

import java.util.function.Supplier;

public class WriteNamePacket {
    private final InteractionHand hand;
    private final String targetName;
    private final String causeKey;

    public WriteNamePacket(InteractionHand hand, String targetName, String causeKey) {
        this.hand = hand;
        this.targetName = targetName == null ? "" : targetName;
        this.causeKey = causeKey == null ? "" : causeKey;
    }

    public static void encode(WriteNamePacket msg, FriendlyByteBuf buf) {
        buf.writeEnum(msg.hand);
        buf.writeUtf(msg.targetName, 64);
        buf.writeUtf(msg.causeKey, 32);
    }

    public static WriteNamePacket decode(FriendlyByteBuf buf) {
        InteractionHand h = buf.readEnum(InteractionHand.class);
        String name = buf.readUtf(64);
        String cause = buf.readUtf(32);
        return new WriteNamePacket(h, name, cause);
    }

    public static void handle(WriteNamePacket msg, Supplier<NetworkEvent.Context> ctxSup) {
        NetworkEvent.Context ctx = ctxSup.get();
        ctx.enqueueWork(() -> {
            ServerPlayer sender = ctx.getSender();
            if (sender == null) return;
            ItemStack stack = sender.getItemInHand(msg.hand);
            if (!(stack.getItem() instanceof DeathNoteItem)) return;
            DeathCause cause = msg.causeKey.isEmpty() ? DeathCause.HEART_ATTACK : DeathCause.fromString(msg.causeKey);
            DeathNoteItem.writeName(sender, stack, msg.targetName, cause);
        });
        ctx.setPacketHandled(true);
    }
}
