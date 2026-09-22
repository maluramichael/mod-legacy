/*
 * mod-legacy
 *
 * Account-wide "Legacy" progression (Kanboard #780) - first cut, deliberately bounded:
 *
 *   - EARN: leveling grants Legacy Points to the ACCOUNT (any character's level-ups add to
 *     the same pool). v1 earn-source is OnPlayerLevelChanged only; more sources (dungeon
 *     bosses, achievements, ...) are future work, see README "Limitations".
 *   - SPEND: `.legacy buy <tree> <node>` raises a node's rank for THIS character, drawing
 *     from the account-wide pool. The pool is shared: the account can never have spent (in
 *     total, across every character) more than it has ever earned. Which nodes are active is
 *     tracked per character (a character only benefits from the nodes IT bought).
 *   - 3 trees x 3 nodes (Adventure / Professions / Resourcefulness), see Legacy.h for the
 *     enum layout and GetNodeDef() below for names/descriptions. One node (Professions:
 *     "Bountiful Harvest" / gather yield chance) is a documented STUB - no clean, precise
 *     hook exists to raise a specific gather node's yield chance without also touching
 *     unrelated creature loot, so it is listed but not purchasable in v1.
 *
 * How each REAL perk is applied:
 *   - Move speed (Adventure)      -> single hidden, passive, server-side carrier spell
 *                                     (200260, see data/sql/db-world/updates/mod_legacy_*.sql),
 *                                     same technique as mod-group-buffs: the aura is created on
 *                                     demand and its effect amount rewritten with
 *                                     AuraEffect::ChangeAmount. Re-applied on login/buy/reset.
 *   - XP % / Explore XP %         -> PlayerScript::OnPlayerGiveXP, amount is scaled directly.
 *   - Gathering/Crafting skill-up -> PlayerScript::OnPlayerUpdate{Gathering,Crafting}Skill,
 *                                     the `gain` out-param is scaled directly.
 *   - Kill/loot gold %            -> PlayerScript::OnPlayerBeforeLootMoney, Loot::gold is
 *                                     scaled directly before the player is paid.
 *   - Vendor discount             -> PlayerScript::OnPlayerGetReputationPriceDiscount (both
 *                                     overloads); this is the SAME discount the core applies
 *                                     to vendor buy prices AND (via GetReputationPriceDiscount)
 *                                     as the base for repair costs, so it also nudges repairs.
 *   - Repair discount             -> PlayerScript::OnPlayerBeforeDurabilityRepair, stacks
 *                                     multiplicatively ON TOP of the vendor discount above
 *                                     (repair-specific, intentional).
 *
 * Released under GNU GPL v2; redistribute/modify under version 2 of the License,
 * or (at your option) any later version.
 */

#include "Chat.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "LootMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "StringFormat.h"

#include "Legacy.h"

#include <algorithm>
#include <cmath>

namespace
{
    // Server-side passive carrier spell, see data/sql/db-world/updates/mod_legacy_2026_09_22_00.sql.
    constexpr uint32 SPELL_LEGACY_MOVE_SPEED = 200260;

    // False when the carrier spell is missing from spell_dbc (SQL not applied): move speed is
    // then simply not applied, every other perk still works (they don't need a spell).
    bool sMoveSpeedSpellAvailable = true;

    std::string const DATA_KEY = "Legacy";
}

namespace Legacy
{
    Config& GetConfig()
    {
        static Config cfg;
        return cfg;
    }

    NodeDef const& GetNodeDef(uint8 tree, uint8 node)
    {
        static NodeDef const table[TREE_COUNT][NODES_PER_TREE] = {
            { // Adventure
                { "Swift Boots", "+move speed", false },
                { "Quick Study", "+XP from all sources", false },
                { "Wanderlust", "+bonus XP from area exploration (stacks with Quick Study)", false }
            },
            { // Professions
                { "Steady Hands", "+gathering skill-up rate (mining/herbalism/skinning)", false },
                { "Master Crafter", "+crafting skill-up rate", false },
                { "Bountiful Harvest", "+chance for bonus gather yield - reserved, not implemented yet", true }
            },
            { // Resourcefulness
                { "Grave Robber", "+gold looted from creatures/objects", false },
                { "Haggler", "vendor buy-price discount (also nudges repair costs)", false },
                { "Frugal Repairs", "additional repair-cost discount (stacks with Haggler)", false }
            }
        };

        static NodeDef const invalid{ "?", "?", true };
        if (tree >= TREE_COUNT || node >= NODES_PER_TREE)
            return invalid;

        return table[tree][node];
    }

    char const* GetTreeName(uint8 tree)
    {
        static char const* names[TREE_COUNT] = { "Adventure", "Professions", "Resourcefulness" };
        return tree < TREE_COUNT ? names[tree] : "?";
    }

    void EnsureSchema()
    {
        // Deliberately NOT SQL update files: on this fork a failing module SQL aborts the whole
        // worldserver boot, so runtime tables are created programmatically and any failure is
        // tolerated at runtime instead (matches mod-self-found / mod-guild-tax).
        CharacterDatabase.Execute(
            "CREATE TABLE IF NOT EXISTS `legacy_account` ("
            "`account_id` INT UNSIGNED NOT NULL, "
            "`points_earned` INT UNSIGNED NOT NULL DEFAULT 0, "
            "`updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, "
            "PRIMARY KEY (`account_id`)"
            ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

        CharacterDatabase.Execute(
            "CREATE TABLE IF NOT EXISTS `legacy_spent` ("
            "`guid` INT UNSIGNED NOT NULL, "
            "`account_id` INT UNSIGNED NOT NULL, "
            "`tree` TINYINT UNSIGNED NOT NULL, "
            "`node` TINYINT UNSIGNED NOT NULL, "
            "`rank` TINYINT UNSIGNED NOT NULL DEFAULT 0, "
            "PRIMARY KEY (`guid`, `tree`, `node`), "
            "KEY `idx_legacy_spent_account` (`account_id`)"
            ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");
    }

    void LoadCache(Player* player)
    {
        if (!player || !player->GetSession())
            return;

        CharacterCache* cache = player->CustomData.GetDefault<CharacterCache>(DATA_KEY);

        uint32 accountId = player->GetSession()->GetAccountId();
        uint32 guidLow = player->GetGUID().GetCounter();

        cache->accountId = accountId;
        cache->accountPointsEarned = 0;
        cache->accountPointsSpent = 0;
        for (auto& treeRanks : cache->ranks)
            treeRanks.fill(0);

        if (QueryResult result = CharacterDatabase.Query(
            "SELECT `points_earned` FROM `legacy_account` WHERE `account_id` = {}", accountId))
        {
            Field* fields = result->Fetch();
            cache->accountPointsEarned = fields[0].Get<uint32>();
        }

        // Integer DIV (not the `/` operator, which MySQL always promotes to DECIMAL) - rank*(rank+1)
        // is always even, so this is an exact triangular-number sum with no precision surprises.
        if (QueryResult result = CharacterDatabase.Query(
            "SELECT COALESCE(SUM(`rank` * (`rank` + 1) DIV 2), 0) FROM `legacy_spent` WHERE `account_id` = {}",
            accountId))
        {
            Field* fields = result->Fetch();
            cache->accountPointsSpent = fields[0].Get<uint32>();
        }

        if (QueryResult result = CharacterDatabase.Query(
            "SELECT `tree`, `node`, `rank` FROM `legacy_spent` WHERE `guid` = {}", guidLow))
        {
            do
            {
                Field* fields = result->Fetch();
                uint8 tree = fields[0].Get<uint8>();
                uint8 node = fields[1].Get<uint8>();
                uint8 rank = fields[2].Get<uint8>();

                if (tree < TREE_COUNT && node < NODES_PER_TREE)
                    cache->ranks[tree][node] = rank;
            } while (result->NextRow());
        }

        cache->loaded = true;
    }

    CharacterCache const* GetCache(Player const* player)
    {
        if (!player)
            return nullptr;

        return player->CustomData.Get<CharacterCache>(DATA_KEY);
    }

    uint32 GetAvailablePoints(Player const* player)
    {
        CharacterCache const* cache = GetCache(player);
        if (!cache || !cache->loaded)
            return 0;

        if (cache->accountPointsSpent >= cache->accountPointsEarned)
            return 0;

        return cache->accountPointsEarned - cache->accountPointsSpent;
    }

    namespace
    {
        // rank * PerRank[tree][node], or 0 if the cache isn't loaded / rank is 0.
        float RankPercent(Player const* player, uint8 tree, uint8 node)
        {
            CharacterCache const* cache = GetCache(player);
            if (!cache || !cache->loaded)
                return 0.0f;

            uint8 rank = cache->ranks[tree][node];
            if (rank == 0)
                return 0.0f;

            return static_cast<float>(rank) * GetConfig().PerRank[tree][node];
        }
    }

    float GetXpBonusPercent(Player const* player)
    {
        return RankPercent(player, TREE_ADVENTURE, NODE_ADV_XP);
    }

    float GetExploreXpBonusPercent(Player const* player)
    {
        return RankPercent(player, TREE_ADVENTURE, NODE_ADV_EXPLORE_XP);
    }

    float GetGatherRateBonusPercent(Player const* player)
    {
        return RankPercent(player, TREE_PROFESSIONS, NODE_PROF_GATHER_RATE);
    }

    float GetCraftRateBonusPercent(Player const* player)
    {
        return RankPercent(player, TREE_PROFESSIONS, NODE_PROF_CRAFT_RATE);
    }

    float GetKillGoldBonusPercent(Player const* player)
    {
        return RankPercent(player, TREE_RESOURCEFULNESS, NODE_RES_KILL_GOLD);
    }

    float GetVendorDiscountPercent(Player const* player)
    {
        return RankPercent(player, TREE_RESOURCEFULNESS, NODE_RES_VENDOR_DISCOUNT);
    }

    float GetRepairDiscountPercent(Player const* player)
    {
        return RankPercent(player, TREE_RESOURCEFULNESS, NODE_RES_REPAIR_DISCOUNT);
    }

    void ApplyPerks(Player* player)
    {
        if (!player || !sMoveSpeedSpellAvailable)
            return;

        // Sanity clamp (an admin-misconfigured PerRank should not produce an absurd speed aura).
        int32 amount = std::clamp(
            static_cast<int32>(std::lround(RankPercent(player, TREE_ADVENTURE, NODE_ADV_MOVE_SPEED))), 0, 300);

        if (amount <= 0)
        {
            if (player->HasAura(SPELL_LEGACY_MOVE_SPEED))
                player->RemoveAurasDueToSpell(SPELL_LEGACY_MOVE_SPEED);
            return;
        }

        Aura* aura = player->GetAura(SPELL_LEGACY_MOVE_SPEED);
        if (!aura)
            aura = player->AddAura(SPELL_LEGACY_MOVE_SPEED, player);

        if (!aura || aura->IsRemoved())
            return;

        if (AuraEffect* effect = aura->GetEffect(0))
        {
            if (effect->GetAmount() != amount)
                effect->ChangeAmount(amount);
        }
    }

    char const* ToString(BuyResult result)
    {
        switch (result)
        {
            case BuyResult::Success:         return "Success.";
            case BuyResult::Disabled:        return "Legacy progression is currently disabled on this server.";
            case BuyResult::InvalidTree:     return "Invalid tree.";
            case BuyResult::InvalidNode:     return "Invalid node.";
            case BuyResult::Stub:            return "This perk is not yet implemented - no points spent.";
            case BuyResult::AlreadyMaxRank:  return "This node is already at max rank.";
            case BuyResult::NotEnoughPoints: return "Not enough Legacy points available.";
            default:                         return "Unknown error.";
        }
    }

    BuyResult BuyNode(Player* player, uint8 tree, uint8 node)
    {
        Config const& cfg = GetConfig();
        if (!cfg.Enable)
            return BuyResult::Disabled;

        if (!player || !player->GetSession())
            return BuyResult::InvalidTree;

        if (tree >= TREE_COUNT)
            return BuyResult::InvalidTree;

        if (node >= NODES_PER_TREE)
            return BuyResult::InvalidNode;

        NodeDef const& def = GetNodeDef(tree, node);
        if (def.stub)
            return BuyResult::Stub;

        CharacterCache* cache = player->CustomData.GetDefault<CharacterCache>(DATA_KEY);
        if (!cache->loaded)
            LoadCache(player);

        uint8 currentRank = cache->ranks[tree][node];
        if (currentRank >= MAX_NODE_RANK)
            return BuyResult::AlreadyMaxRank;

        uint32 cost = CostForRank(currentRank + 1);
        if (GetAvailablePoints(player) < cost)
            return BuyResult::NotEnoughPoints;

        uint8 newRank = uint8(currentRank + 1);
        uint32 guidLow = player->GetGUID().GetCounter();
        uint32 accountId = cache->accountId;

        CharacterDatabase.Execute(
            "INSERT INTO `legacy_spent` (`guid`, `account_id`, `tree`, `node`, `rank`) VALUES ({}, {}, {}, {}, {}) "
            "ON DUPLICATE KEY UPDATE `rank` = {}",
            guidLow, accountId, uint32(tree), uint32(node), uint32(newRank), uint32(newRank));

        LoadCache(player);
        ApplyPerks(player);
        return BuyResult::Success;
    }

    uint32 ResetCharacter(Player* player)
    {
        if (!player || !player->GetSession())
            return 0;

        CharacterCache* cache = player->CustomData.GetDefault<CharacterCache>(DATA_KEY);
        if (!cache->loaded)
            LoadCache(player);

        uint32 refunded = 0;
        for (uint8 tree = 0; tree < TREE_COUNT; ++tree)
            for (uint8 node = 0; node < NODES_PER_TREE; ++node)
                refunded += TotalCostForRank(cache->ranks[tree][node]);

        if (refunded == 0)
            return 0;

        uint32 guidLow = player->GetGUID().GetCounter();
        CharacterDatabase.Execute("DELETE FROM `legacy_spent` WHERE `guid` = {}", guidLow);

        LoadCache(player);
        ApplyPerks(player);
        return refunded;
    }

    namespace
    {
        // Credits `points` to the account's shared Legacy Points pool. Used by
        // LegacyPlayerScript::OnPlayerLevelChanged (the only earn-source in v1).
        void CreditAccountPoints(uint32 accountId, uint32 points)
        {
            if (!accountId || !points)
                return;

            CharacterDatabase.Execute(
                "INSERT INTO `legacy_account` (`account_id`, `points_earned`) VALUES ({}, {}) "
                "ON DUPLICATE KEY UPDATE `points_earned` = `points_earned` + {}",
                accountId, points, points);
        }
    }

    // Called from LegacyPlayerScript::OnPlayerLevelChanged.
    void CreditLevelUpPoints(Player* player)
    {
        Config const& cfg = GetConfig();
        if (!cfg.Enable || !player || !player->GetSession())
            return;

        CharacterCache const* cache = GetCache(player);
        uint32 accountId = cache ? cache->accountId : player->GetSession()->GetAccountId();

        CreditAccountPoints(accountId, cfg.PointsPerLevel);

        LoadCache(player);
        ApplyPerks(player);
    }
}

using namespace Acore::ChatCommands;

// =====================================================================
//  CommandScript: `.legacy` / `.legacy buy <tree> <node>` / `.legacy reset`
// =====================================================================
class legacy_commandscript : public CommandScript
{
public:
    legacy_commandscript() : CommandScript("legacy_commandscript") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable legacyTable =
        {
            { "",      HandleLegacyStatusCommand, SEC_PLAYER, Console::No },
            { "buy",   HandleLegacyBuyCommand,    SEC_PLAYER, Console::No },
            { "reset", HandleLegacyResetCommand,  SEC_PLAYER, Console::No },
        };

        static ChatCommandTable commandTable =
        {
            { "legacy", legacyTable },
        };

        return commandTable;
    }

    static bool HandleLegacyStatusCommand(ChatHandler* handler)
    {
        Player* player = handler->GetPlayer();
        if (!player)
            return false;

        if (!Legacy::GetConfig().Enable)
        {
            handler->SendSysMessage("Legacy progression is currently disabled on this server.");
            handler->SetSentErrorMessage(true);
            return false;
        }

        Legacy::LoadCache(player); // always show fresh numbers, cheap (one player, on demand)
        Legacy::CharacterCache const* cache = Legacy::GetCache(player);

        handler->PSendSysMessage("|cff4CFF00[Legacy]|r {} point(s) available (account-wide pool).",
            Legacy::GetAvailablePoints(player));

        for (uint8 tree = 0; tree < Legacy::TREE_COUNT; ++tree)
        {
            handler->PSendSysMessage("-- {} --", Legacy::GetTreeName(tree));

            for (uint8 node = 0; node < Legacy::NODES_PER_TREE; ++node)
            {
                Legacy::NodeDef const& def = Legacy::GetNodeDef(tree, node);
                uint8 rank = cache ? cache->ranks[tree][node] : 0;

                std::string status;
                if (def.stub)
                    status = "not yet implemented";
                else if (rank >= Legacy::MAX_NODE_RANK)
                    status = "MAX";
                else
                    status = Acore::StringFormat("next rank costs {}", Legacy::CostForRank(rank + 1));

                handler->PSendSysMessage("  {}.{} {} - {} (rank {}/{}, {})",
                    tree + 1, node + 1, def.name, def.description, uint32(rank), uint32(Legacy::MAX_NODE_RANK), status);
            }
        }

        handler->SendSysMessage("Use '.legacy buy <tree> <node>' to spend a point, '.legacy reset' to refund this character.");
        return true;
    }

    static bool HandleLegacyBuyCommand(ChatHandler* handler, uint32 tree, uint32 node)
    {
        Player* player = handler->GetPlayer();
        if (!player)
            return false;

        if (tree < 1 || tree > Legacy::TREE_COUNT || node < 1 || node > Legacy::NODES_PER_TREE)
        {
            handler->PSendSysMessage("Usage: .legacy buy <tree 1-{}> <node 1-{}>",
                uint32(Legacy::TREE_COUNT), uint32(Legacy::NODES_PER_TREE));
            handler->SetSentErrorMessage(true);
            return false;
        }

        uint8 treeIdx = uint8(tree - 1);
        uint8 nodeIdx = uint8(node - 1);

        Legacy::BuyResult result = Legacy::BuyNode(player, treeIdx, nodeIdx);
        if (result == Legacy::BuyResult::Success)
        {
            Legacy::NodeDef const& def = Legacy::GetNodeDef(treeIdx, nodeIdx);
            Legacy::CharacterCache const* updated = Legacy::GetCache(player);
            uint32 newRank = updated ? uint32(updated->ranks[treeIdx][nodeIdx]) : 0;
            handler->PSendSysMessage("|cff4CFF00[Legacy]|r {} raised to rank {}: {}.",
                def.name, newRank, def.description);
            return true;
        }

        handler->SendSysMessage(Legacy::ToString(result));
        handler->SetSentErrorMessage(true);
        return false;
    }

    static bool HandleLegacyResetCommand(ChatHandler* handler)
    {
        Player* player = handler->GetPlayer();
        if (!player)
            return false;

        uint32 refunded = Legacy::ResetCharacter(player);
        if (refunded == 0)
        {
            handler->SendSysMessage("This character has no Legacy points spent.");
            return true;
        }

        handler->PSendSysMessage("|cff4CFF00[Legacy]|r {} point(s) refunded to the account pool.", refunded);
        return true;
    }
};

// =====================================================================
//  PlayerScript: earn on level-up, apply perks on login, live hooks for the rest.
// =====================================================================
class LegacyPlayerScript : public PlayerScript
{
public:
    LegacyPlayerScript() : PlayerScript("Legacy_PlayerScript") { }

    void OnPlayerLogin(Player* player) override
    {
        if (!Legacy::GetConfig().Enable || !player)
            return;

        Legacy::LoadCache(player);
        Legacy::ApplyPerks(player);
    }

    void OnPlayerLevelChanged(Player* player, uint8 oldlevel) override
    {
        Legacy::Config const& cfg = Legacy::GetConfig();
        if (!cfg.Enable || !player || !player->GetSession())
            return;

        uint32 newLevel = player->GetLevel();
        if (cfg.LevelStep == 0 || newLevel <= oldlevel)
            return;

        // Award once per LevelStep threshold crossed (level normally increases by exactly 1,
        // so this fires every LevelStep levels, e.g. every level when LevelStep == 1).
        if (newLevel % cfg.LevelStep != 0)
            return;

        if (!Legacy::GetCache(player)) // first level-up this session, make sure accountId is cached
            Legacy::LoadCache(player);

        Legacy::CreditLevelUpPoints(player);
    }

    void OnPlayerGiveXP(Player* player, uint32& amount, Unit* /*victim*/, uint8 xpSource) override
    {
        if (!Legacy::GetConfig().Enable || !player || amount == 0)
            return;

        float percent = Legacy::GetXpBonusPercent(player);
        if (xpSource == XPSOURCE_EXPLORE)
            percent += Legacy::GetExploreXpBonusPercent(player);

        if (percent <= 0.0f)
            return;

        uint32 extra = static_cast<uint32>(std::lround(static_cast<float>(amount) * percent / 100.0f));
        amount += extra;
    }

    void OnPlayerUpdateGatheringSkill(Player* player, uint32 /*skill_id*/, uint32 /*current*/, uint32 /*gray*/,
        uint32 /*green*/, uint32 /*yellow*/, uint32& gain) override
    {
        if (!Legacy::GetConfig().Enable || !player || gain == 0)
            return;

        float percent = Legacy::GetGatherRateBonusPercent(player);
        if (percent <= 0.0f)
            return;

        uint32 extra = static_cast<uint32>(std::lround(static_cast<float>(gain) * percent / 100.0f));
        gain += extra;
    }

    void OnPlayerUpdateCraftingSkill(Player* player, SkillLineAbilityEntry const* /*skill*/, uint32 /*current_level*/,
        uint32& gain) override
    {
        if (!Legacy::GetConfig().Enable || !player || gain == 0)
            return;

        float percent = Legacy::GetCraftRateBonusPercent(player);
        if (percent <= 0.0f)
            return;

        uint32 extra = static_cast<uint32>(std::lround(static_cast<float>(gain) * percent / 100.0f));
        gain += extra;
    }

    void OnPlayerBeforeLootMoney(Player* player, Loot* loot) override
    {
        if (!Legacy::GetConfig().Enable || !player || !loot || loot->gold == 0)
            return;

        float percent = Legacy::GetKillGoldBonusPercent(player);
        if (percent <= 0.0f)
            return;

        uint32 extra = static_cast<uint32>(std::lround(static_cast<float>(loot->gold) * percent / 100.0f));
        loot->gold += extra;
    }

    void OnPlayerGetReputationPriceDiscount(Player const* player, Creature const* /*creature*/, float& discount) override
    {
        ApplyVendorDiscount(player, discount);
    }

    void OnPlayerGetReputationPriceDiscount(Player const* player, FactionTemplateEntry const* /*factionTemplate*/,
        float& discount) override
    {
        ApplyVendorDiscount(player, discount);
    }

    void OnPlayerBeforeDurabilityRepair(Player* player, ObjectGuid /*npcGUID*/, ObjectGuid /*itemGUID*/,
        float& discountMod, uint8 /*guildBank*/) override
    {
        if (!Legacy::GetConfig().Enable || !player)
            return;

        float percent = Legacy::GetRepairDiscountPercent(player);
        if (percent <= 0.0f)
            return;

        discountMod *= std::max(0.0f, 1.0f - percent / 100.0f);
    }

private:
    static void ApplyVendorDiscount(Player const* player, float& discount)
    {
        if (!Legacy::GetConfig().Enable || !player)
            return;

        float percent = Legacy::GetVendorDiscountPercent(player);
        if (percent <= 0.0f)
            return;

        discount *= std::max(0.0f, 1.0f - percent / 100.0f);
    }
};

// =====================================================================
//  WorldScript: config load + schema bootstrap + carrier spell sanity check.
// =====================================================================
class LegacyWorldScript : public WorldScript
{
public:
    LegacyWorldScript() : WorldScript("Legacy_WorldScript") { }

    void OnAfterConfigLoad(bool /*reload*/) override
    {
        Legacy::Config& cfg = Legacy::GetConfig();
        cfg.Enable = sConfigMgr->GetOption<bool>("Legacy.Enable", true);
        cfg.PointsPerLevel = sConfigMgr->GetOption<uint32>("Legacy.PointsPerLevel", 1);
        cfg.LevelStep = std::max<uint32>(1, sConfigMgr->GetOption<uint32>("Legacy.LevelStep", 1));

        cfg.PerRank[Legacy::TREE_ADVENTURE][Legacy::NODE_ADV_MOVE_SPEED] =
            sConfigMgr->GetOption<float>("Legacy.Adventure.MoveSpeed.PerRank", 1.0f);
        cfg.PerRank[Legacy::TREE_ADVENTURE][Legacy::NODE_ADV_XP] =
            sConfigMgr->GetOption<float>("Legacy.Adventure.Xp.PerRank", 2.0f);
        cfg.PerRank[Legacy::TREE_ADVENTURE][Legacy::NODE_ADV_EXPLORE_XP] =
            sConfigMgr->GetOption<float>("Legacy.Adventure.ExploreXp.PerRank", 10.0f);

        cfg.PerRank[Legacy::TREE_PROFESSIONS][Legacy::NODE_PROF_GATHER_RATE] =
            sConfigMgr->GetOption<float>("Legacy.Professions.GatherRate.PerRank", 10.0f);
        cfg.PerRank[Legacy::TREE_PROFESSIONS][Legacy::NODE_PROF_CRAFT_RATE] =
            sConfigMgr->GetOption<float>("Legacy.Professions.CraftRate.PerRank", 10.0f);
        cfg.PerRank[Legacy::TREE_PROFESSIONS][Legacy::NODE_PROF_GATHER_YIELD] = 0.0f; // stub

        cfg.PerRank[Legacy::TREE_RESOURCEFULNESS][Legacy::NODE_RES_KILL_GOLD] =
            sConfigMgr->GetOption<float>("Legacy.Resourcefulness.KillGold.PerRank", 5.0f);
        cfg.PerRank[Legacy::TREE_RESOURCEFULNESS][Legacy::NODE_RES_VENDOR_DISCOUNT] =
            sConfigMgr->GetOption<float>("Legacy.Resourcefulness.VendorDiscount.PerRank", 2.0f);
        cfg.PerRank[Legacy::TREE_RESOURCEFULNESS][Legacy::NODE_RES_REPAIR_DISCOUNT] =
            sConfigMgr->GetOption<float>("Legacy.Resourcefulness.RepairDiscount.PerRank", 5.0f);
    }

    void OnStartup() override
    {
        Legacy::EnsureSchema();

        sMoveSpeedSpellAvailable = (sSpellMgr->GetSpellInfo(SPELL_LEGACY_MOVE_SPEED) != nullptr);
        if (!sMoveSpeedSpellAvailable)
        {
            LOG_ERROR("server.loading", "mod-legacy: server-side spell {} is missing from spell_dbc "
                "(data/sql/db-world/updates/mod_legacy_*.sql not applied?). The Adventure move-speed "
                "perk (Swift Boots) is disabled; every other Legacy perk still works.",
                SPELL_LEGACY_MOVE_SPEED);
        }
    }
};

void AddLegacyScripts()
{
    new legacy_commandscript();
    new LegacyPlayerScript();
    new LegacyWorldScript();
}
