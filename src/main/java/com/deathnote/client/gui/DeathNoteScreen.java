package com.deathnote.client.gui;

import com.deathnote.death.DeathCause;
import com.deathnote.network.ModNetwork;
import com.deathnote.network.WriteNamePacket;
import com.mojang.blaze3d.systems.RenderSystem;
import net.minecraft.ChatFormatting;
import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.client.gui.components.Button;
import net.minecraft.client.gui.components.CycleButton;
import net.minecraft.client.gui.components.EditBox;
import net.minecraft.client.gui.screens.Screen;
import net.minecraft.network.chat.Component;
import net.minecraft.world.InteractionHand;
import net.minecraftforge.api.distmarker.Dist;
import net.minecraftforge.api.distmarker.OnlyIn;

@OnlyIn(Dist.CLIENT)
public class DeathNoteScreen extends Screen {
    private final InteractionHand hand;
    private EditBox nameBox;
    private CycleButton<DeathCause> causeButton;
    private DeathCause selectedCause = DeathCause.HEART_ATTACK;

    public DeathNoteScreen(InteractionHand hand) {
        super(Component.translatable("screen.deathnote.title"));
        this.hand = hand;
    }

    @Override
    protected void init() {
        int cx = this.width / 2;
        int cy = this.height / 2;

        nameBox = new EditBox(this.font, cx - 100, cy - 30, 200, 20, Component.translatable("screen.deathnote.name_field"));
        nameBox.setMaxLength(64);
        nameBox.setHint(Component.translatable("screen.deathnote.name_hint").withStyle(ChatFormatting.DARK_GRAY));
        addRenderableWidget(nameBox);
        setInitialFocus(nameBox);

        causeButton = CycleButton.<DeathCause>builder(c -> Component.literal(c.getDisplayName()))
                .withValues(DeathCause.values())
                .withInitialValue(DeathCause.HEART_ATTACK)
                .create(cx - 100, cy, 200, 20,
                        Component.translatable("screen.deathnote.cause"),
                        (b, v) -> selectedCause = v);
        addRenderableWidget(causeButton);

        addRenderableWidget(Button.builder(Component.translatable("screen.deathnote.write"), b -> submit())
                .bounds(cx - 100, cy + 30, 95, 20).build());

        addRenderableWidget(Button.builder(Component.translatable("gui.cancel"), b -> onClose())
                .bounds(cx + 5, cy + 30, 95, 20).build());
    }

    private void submit() {
        String name = nameBox.getValue().trim();
        if (name.isEmpty()) return;
        ModNetwork.CHANNEL.sendToServer(new WriteNamePacket(hand, name, selectedCause.name()));
        onClose();
    }

    @Override
    public void render(GuiGraphics gfx, int mx, int my, float partial) {
        renderBackground(gfx);
        RenderSystem.enableBlend();
        super.render(gfx, mx, my, partial);

        int cx = this.width / 2;
        gfx.drawCenteredString(this.font, this.title.copy().withStyle(ChatFormatting.DARK_RED),
                cx, this.height / 2 - 70, 0xFFFFFFFF);
        gfx.drawCenteredString(this.font,
                Component.translatable("screen.deathnote.rule").withStyle(ChatFormatting.GRAY),
                cx, this.height / 2 - 50, 0xFFAAAAAA);
    }

    @Override
    public boolean isPauseScreen() { return false; }
}
