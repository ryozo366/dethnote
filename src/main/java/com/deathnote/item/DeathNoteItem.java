package com.deathnote.item;

import com.deathnote.death.DeathCause;
import com.deathnote.death.DeathScheduler;
import net.minecraftforge.api.distmarker.Dist;
import net.minecraftforge.fml.DistExecutor;
import net.minecraft.ChatFormatting;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.nbt.ListTag;
import net.minecraft.nbt.StringTag;
import net.minecraft.network.chat.Component;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResultHolder;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.TooltipFlag;
import net.minecraft.world.level.Level;

import javax.annotation.Nullable;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class DeathNoteItem extends Item {
    public static final String TAG_OWNER = "Owner";
    public static final String TAG_OWNER_NAME = "OwnerName";
    public static final String TAG_ENTRIES = "Entries";

    public DeathNoteItem(Properties properties) {
        super(properties);
    }

    @Override
    public InteractionResultHolder<ItemStack> use(Level level, Player player, InteractionHand hand) {
        ItemStack stack = player.getItemInHand(hand);

        bindOwnerIfNeeded(stack, player);

        if (!isOwner(stack, player)) {
            if (!level.isClientSide) {
                player.displayClientMessage(
                        Component.translatable("message.deathnote.not_owner").withStyle(ChatFormatting.DARK_RED),
                        true);
            }
            return InteractionResultHolder.fail(stack);
        }

        if (level.isClientSide) {
            DistExecutor.unsafeRunWhenOn(Dist.CLIENT,
                    () -> () -> com.deathnote.client.ClientHooks.openDeathNoteScreen(hand));
        }
        return InteractionResultHolder.sidedSuccess(stack, level.isClientSide);
    }

    @Override
    public void appendHoverText(ItemStack stack, @Nullable Level level, List<Component> tooltip, TooltipFlag flag) {
        super.appendHoverText(stack, level, tooltip, flag);
        tooltip.add(Component.translatable("tooltip.deathnote.rule1").withStyle(ChatFormatting.GRAY));
        tooltip.add(Component.translatable("tooltip.deathnote.rule2").withStyle(ChatFormatting.GRAY));
        tooltip.add(Component.translatable("tooltip.deathnote.rule3").withStyle(ChatFormatting.GRAY));
        tooltip.add(Component.translatable("tooltip.deathnote.rule4").withStyle(ChatFormatting.GRAY));

        CompoundTag tag = stack.getTag();
        if (tag != null && tag.contains(TAG_OWNER_NAME)) {
            tooltip.add(Component.translatable("tooltip.deathnote.owner", tag.getString(TAG_OWNER_NAME))
                    .withStyle(ChatFormatting.DARK_PURPLE));
        }
        List<String> entries = readEntries(stack);
        if (!entries.isEmpty()) {
            tooltip.add(Component.translatable("tooltip.deathnote.entries", entries.size())
                    .withStyle(ChatFormatting.DARK_RED));
        }
    }

    public static void bindOwnerIfNeeded(ItemStack stack, Player player) {
        CompoundTag tag = stack.getOrCreateTag();
        if (!tag.hasUUID(TAG_OWNER)) {
            tag.putUUID(TAG_OWNER, player.getUUID());
            tag.putString(TAG_OWNER_NAME, player.getGameProfile().getName());
        }
    }

    public static boolean isOwner(ItemStack stack, Player player) {
        CompoundTag tag = stack.getTag();
        if (tag == null || !tag.hasUUID(TAG_OWNER)) return true;
        return tag.getUUID(TAG_OWNER).equals(player.getUUID());
    }

    public static UUID getOwner(ItemStack stack) {
        CompoundTag tag = stack.getTag();
        if (tag == null || !tag.hasUUID(TAG_OWNER)) return null;
        return tag.getUUID(TAG_OWNER);
    }

    public static List<String> readEntries(ItemStack stack) {
        List<String> out = new ArrayList<>();
        CompoundTag tag = stack.getTag();
        if (tag == null || !tag.contains(TAG_ENTRIES)) return out;
        ListTag list = tag.getList(TAG_ENTRIES, 8);
        for (int i = 0; i < list.size(); i++) out.add(list.getString(i));
        return out;
    }

    public static void appendEntry(ItemStack stack, String line) {
        CompoundTag tag = stack.getOrCreateTag();
        ListTag list = tag.getList(TAG_ENTRIES, 8);
        list.add(StringTag.valueOf(line));
        tag.put(TAG_ENTRIES, list);
    }

    public static boolean writeName(ServerPlayer writer, ItemStack stack, String targetName, @Nullable DeathCause cause) {
        if (targetName == null || targetName.isBlank()) return false;
        if (!isOwner(stack, writer)) return false;
        if (!hasPenInInventory(writer)) {
            writer.displayClientMessage(Component.translatable("message.deathnote.need_pen")
                    .withStyle(ChatFormatting.RED), true);
            return false;
        }

        ServerLevel serverLevel = writer.serverLevel();
        LivingEntity target = findTargetByName(serverLevel, targetName);
        if (target == null) {
            writer.displayClientMessage(Component.translatable("message.deathnote.unknown_name", targetName)
                    .withStyle(ChatFormatting.GRAY), true);
            return false;
        }

        if (DeathScheduler.isScheduled(target)) {
            writer.displayClientMessage(Component.translatable("message.deathnote.already_written")
                    .withStyle(ChatFormatting.GRAY), true);
            return false;
        }

        DeathCause effective = cause == null ? DeathCause.HEART_ATTACK : cause;
        int delayTicks = effective == DeathCause.HEART_ATTACK ? 40 * 20 : 6 * 20;

        DeathScheduler.schedule(serverLevel, target, writer, effective, delayTicks);
        appendEntry(stack, targetName + " — " + effective.getDisplayName());
        consumePenDurability(writer);

        writer.displayClientMessage(Component.translatable("message.deathnote.written", targetName,
                effective.getDisplayName()).withStyle(ChatFormatting.DARK_RED), false);
        return true;
    }

    @Nullable
    private static LivingEntity findTargetByName(ServerLevel level, String name) {
        for (ServerPlayer p : level.getServer().getPlayerList().getPlayers()) {
            if (p.getGameProfile().getName().equalsIgnoreCase(name)) return p;
        }
        return null;
    }

    private static boolean hasPenInInventory(Player player) {
        for (ItemStack s : player.getInventory().items) {
            if (s.getItem() instanceof DeathPenItem) return true;
        }
        return player.getOffhandItem().getItem() instanceof DeathPenItem;
    }

    private static void consumePenDurability(Player player) {
        for (ItemStack s : player.getInventory().items) {
            if (s.getItem() instanceof DeathPenItem) {
                s.hurtAndBreak(1, player, p -> {});
                return;
            }
        }
        ItemStack off = player.getOffhandItem();
        if (off.getItem() instanceof DeathPenItem) {
            off.hurtAndBreak(1, player, p -> {});
        }
    }
}
