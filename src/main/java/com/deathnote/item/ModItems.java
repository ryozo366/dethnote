package com.deathnote.item;

import com.deathnote.DeathNoteMod;
import net.minecraft.world.food.FoodProperties;
import net.minecraft.world.effect.MobEffectInstance;
import net.minecraft.world.effect.MobEffects;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.Rarity;
import net.minecraftforge.registries.DeferredRegister;
import net.minecraftforge.registries.ForgeRegistries;
import net.minecraftforge.registries.RegistryObject;

public final class ModItems {
    public static final DeferredRegister<Item> ITEMS =
            DeferredRegister.create(ForgeRegistries.ITEMS, DeathNoteMod.MODID);

    public static final RegistryObject<Item> DEATH_NOTE = ITEMS.register("death_note",
            () -> new DeathNoteItem(new Item.Properties().stacksTo(1).rarity(Rarity.EPIC).fireResistant()));

    public static final RegistryObject<Item> DEATH_PEN = ITEMS.register("death_pen",
            () -> new DeathPenItem(new Item.Properties().stacksTo(1).rarity(Rarity.RARE).durability(256)));

    public static final RegistryObject<Item> SHINIGAMI_EYES = ITEMS.register("shinigami_eyes",
            () -> new ShinigamiEyesItem(new Item.Properties().stacksTo(1).rarity(Rarity.EPIC)));

    public static final RegistryObject<Item> SHINIGAMI_APPLE = ITEMS.register("shinigami_apple",
            () -> new Item(new Item.Properties()
                    .stacksTo(16)
                    .rarity(Rarity.RARE)
                    .food(new FoodProperties.Builder()
                            .nutrition(8)
                            .saturationMod(1.2F)
                            .alwaysEat()
                            .effect(() -> new MobEffectInstance(MobEffects.REGENERATION, 200, 1), 1.0F)
                            .effect(() -> new MobEffectInstance(MobEffects.ABSORPTION, 1200, 1), 1.0F)
                            .build())));

    private ModItems() {}
}
