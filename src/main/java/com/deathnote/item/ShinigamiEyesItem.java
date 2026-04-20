package com.deathnote.item;

import net.minecraft.ChatFormatting;
import net.minecraft.network.chat.Component;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResultHolder;
import net.minecraft.world.effect.MobEffectInstance;
import net.minecraft.world.effect.MobEffects;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.TooltipFlag;
import net.minecraft.world.level.Level;

import javax.annotation.Nullable;
import java.util.List;

public class ShinigamiEyesItem extends Item {
    public static final String TAG_ACTIVE = "Active";

    public ShinigamiEyesItem(Properties properties) {
        super(properties);
    }

    public static boolean isActive(ItemStack stack) {
        return stack.getOrCreateTag().getBoolean(TAG_ACTIVE);
    }

    @Override
    public InteractionResultHolder<ItemStack> use(Level level, Player player, InteractionHand hand) {
        ItemStack stack = player.getItemInHand(hand);
        boolean now = !isActive(stack);
        stack.getOrCreateTag().putBoolean(TAG_ACTIVE, now);

        if (!level.isClientSide) {
            if (now) {
                player.addEffect(new MobEffectInstance(MobEffects.NIGHT_VISION, 24000, 0, true, false, true));
                player.displayClientMessage(Component.translatable("message.deathnote.eyes_on")
                        .withStyle(ChatFormatting.DARK_RED), true);
            } else {
                player.removeEffect(MobEffects.NIGHT_VISION);
                player.displayClientMessage(Component.translatable("message.deathnote.eyes_off")
                        .withStyle(ChatFormatting.GRAY), true);
            }
            level.playSound(null, player.blockPosition(), SoundEvents.END_PORTAL_SPAWN, player.getSoundSource(), 0.3F, 2.0F);
        }
        return InteractionResultHolder.sidedSuccess(stack, level.isClientSide);
    }

    @Override
    public void appendHoverText(ItemStack stack, @Nullable Level level, List<Component> tooltip, TooltipFlag flag) {
        super.appendHoverText(stack, level, tooltip, flag);
        tooltip.add(Component.translatable("tooltip.deathnote.eyes1").withStyle(ChatFormatting.GRAY));
        tooltip.add(Component.translatable("tooltip.deathnote.eyes2").withStyle(ChatFormatting.DARK_GRAY));
        tooltip.add(Component.translatable(isActive(stack)
                ? "tooltip.deathnote.eyes_state_on"
                : "tooltip.deathnote.eyes_state_off")
                .withStyle(isActive(stack) ? ChatFormatting.RED : ChatFormatting.DARK_GRAY));
    }
}
