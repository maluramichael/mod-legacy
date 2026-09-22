-- mod-legacy: one server-side, passive, hidden "carrier" spell for the Adventure tree's
-- move-speed node ("Swift Boots").
--
-- Applied as a self-aura on the player; its effect amount is rewritten at runtime
-- (AuraEffect::ChangeAmount) to rank * Legacy.Adventure.MoveSpeed.PerRank percent. Every
-- other Legacy perk is applied directly (XP/skill-up/gold scaling, vendor/repair discount)
-- and needs no spell at all - see Legacy.cpp for details.
--
-- Attributes = PASSIVE (0x40) | DO_NOT_DISPLAY (0x80) | NO_IMMUNITIES (0x20000000)
--   -> never sent to the client (no buff icon), never saved to the character DB, not
--      dispellable. The client does not need it in Spell.dbc (no client-side patch required).
-- EquippedItemClass = -1 -> no weapon/item requirement.
-- DurationIndex 21 = infinite, RangeIndex 1 = self, CastingTimeIndex 1 = instant.
-- Effect_1 = 6 (SPELL_EFFECT_APPLY_AURA), ImplicitTargetA_1 = 1 (TARGET_UNIT_CASTER), base points 0.
--
-- 200260 Legacy: Swift Boots - eff1 129 MOD_SPEED_ALWAYS
--
-- Idempotent (DELETE + INSERT), only touches spell id 200260 (within the module's reserved
-- 200260-200279 range).

DELETE FROM `spell_dbc` WHERE `ID` IN (200260);

INSERT INTO `spell_dbc`
(`ID`, `Attributes`, `EquippedItemClass`, `CastingTimeIndex`, `DurationIndex`, `RangeIndex`, `SchoolMask`,
 `Effect_1`, `ImplicitTargetA_1`, `EffectAura_1`, `EffectMiscValue_1`,
 `Name_Lang_enUS`, `Name_Lang_Mask`)
VALUES
(200260, 536871104, -1, 1, 21, 1, 1, 6, 1, 129, 0, 'Legacy: Swift Boots', 16712190);
