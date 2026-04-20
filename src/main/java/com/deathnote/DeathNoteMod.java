package com.deathnote;

import com.deathnote.item.ModItems;
import com.deathnote.network.ModNetwork;
import com.mojang.logging.LogUtils;
import net.minecraft.core.registries.Registries;
import net.minecraft.network.chat.Component;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.item.CreativeModeTab;
import net.minecraft.world.item.ItemStack;
import net.minecraftforge.common.MinecraftForge;
import net.minecraftforge.eventbus.api.IEventBus;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.fml.event.lifecycle.FMLCommonSetupEvent;
import net.minecraftforge.fml.javafmlmod.FMLJavaModLoadingContext;
import net.minecraftforge.registries.DeferredRegister;
import net.minecraftforge.registries.RegistryObject;
import org.slf4j.Logger;

@Mod(DeathNoteMod.MODID)
public class DeathNoteMod {
    public static final String MODID = "deathnote";
    public static final Logger LOGGER = LogUtils.getLogger();

    public static final DeferredRegister<CreativeModeTab> CREATIVE_MODE_TABS =
            DeferredRegister.create(Registries.CREATIVE_MODE_TAB, MODID);

    public static final RegistryObject<CreativeModeTab> DEATH_NOTE_TAB = CREATIVE_MODE_TABS.register("death_note_tab",
            () -> CreativeModeTab.builder()
                    .title(Component.translatable("itemGroup.deathnote"))
                    .icon(() -> new ItemStack(ModItems.DEATH_NOTE.get()))
                    .displayItems((params, output) -> {
                        output.accept(ModItems.DEATH_NOTE.get());
                        output.accept(ModItems.DEATH_PEN.get());
                        output.accept(ModItems.SHINIGAMI_EYES.get());
                        output.accept(ModItems.SHINIGAMI_APPLE.get());
                    })
                    .build());

    public DeathNoteMod() {
        IEventBus modBus = FMLJavaModLoadingContext.get().getModEventBus();

        ModItems.ITEMS.register(modBus);
        CREATIVE_MODE_TABS.register(modBus);

        modBus.addListener(this::commonSetup);

        MinecraftForge.EVENT_BUS.register(this);
    }

    private void commonSetup(final FMLCommonSetupEvent event) {
        event.enqueueWork(ModNetwork::register);
        LOGGER.info("Death Note loaded. Shinigami watch over this world.");
    }

    public static ResourceLocation id(String path) {
        return new ResourceLocation(MODID, path);
    }
}
