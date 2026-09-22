/*
 * mod-legacy - shared declarations.
 *
 * Account-wide "Legacy" progression (Kanboard #780): characters earn Legacy Points by
 * leveling, and every character on the account spends from that SAME shared pool to raise
 * ranks in 3 small perk trees (Adventure, Professions, Resourcefulness). Which nodes are
 * active is tracked per character (a character only benefits from the nodes it personally
 * bought), but the points themselves are one account-wide currency: the account cannot
 * spend more in total, across every character, than it has ever earned.
 *
 * v1 scope: earning is levelling only (OnPlayerLevelChanged). More earn-sources (dungeon
 * bosses, achievements, ...) are future work - see README "Limitations".
 *
 * Released under GNU GPL v2; redistribute/modify under version 2 of the License,
 * or (at your option) any later version.
 */

#ifndef MOD_LEGACY_H
#define MOD_LEGACY_H

#include "DataMap.h"

#include <array>
#include <cstdint>
#include <string>

class Player;

namespace Legacy
{
    // ---------------------------------------------------------------------
    //  Trees / nodes layout
    // ---------------------------------------------------------------------

    enum Tree : uint8_t
    {
        TREE_ADVENTURE = 0,
        TREE_PROFESSIONS = 1,
        TREE_RESOURCEFULNESS = 2,
        TREE_COUNT = 3
    };

    enum AdventureNode : uint8_t
    {
        NODE_ADV_MOVE_SPEED = 0,  // +move speed % (carrier aura)
        NODE_ADV_XP = 1,          // +XP % (all sources)
        NODE_ADV_EXPLORE_XP = 2   // +explore XP % (on top of NODE_ADV_XP)
    };

    enum ProfessionsNode : uint8_t
    {
        NODE_PROF_GATHER_RATE = 0, // +gathering skill-up rate %
        NODE_PROF_CRAFT_RATE = 1,  // +crafting skill-up rate %
        NODE_PROF_GATHER_YIELD = 2 // +gather yield chance - STUB, not purchasable in v1
    };

    enum ResourcefulnessNode : uint8_t
    {
        NODE_RES_KILL_GOLD = 0,       // +gold looted from creatures/objects %
        NODE_RES_VENDOR_DISCOUNT = 1, // vendor buy-price discount %
        NODE_RES_REPAIR_DISCOUNT = 2  // additional repair-cost discount %
    };

    constexpr uint8_t NODES_PER_TREE = 3;
    constexpr uint8_t MAX_NODE_RANK = 3;

    // Cost, in Legacy Points, to raise a node from (rank-1) to rank: rank 1 costs 1, rank 2
    // costs 2 more (3 total), rank 3 costs 3 more (6 total). Simple, bounded, triangular.
    constexpr uint32_t CostForRank(uint8_t rank)
    {
        return static_cast<uint32_t>(rank);
    }

    // Total points sunk into a node currently at the given rank (0 if rank == 0).
    constexpr uint32_t TotalCostForRank(uint8_t rank)
    {
        return static_cast<uint32_t>(rank) * (static_cast<uint32_t>(rank) + 1) / 2;
    }

    struct NodeDef
    {
        char const* name;
        char const* description;
        bool stub; // true = defined/documented but not purchasable/applied yet (v1)
    };

    // Static, in-code node catalogue (matches the enums above). Magnitudes are NOT here -
    // those are config driven per node (Config::PerRank), see mod_legacy.conf.dist.
    NodeDef const& GetNodeDef(uint8_t tree, uint8_t node);
    char const* GetTreeName(uint8_t tree);

    // ---------------------------------------------------------------------
    //  Config (populated in WorldScript::OnAfterConfigLoad)
    // ---------------------------------------------------------------------

    struct Config
    {
        bool Enable = true;

        uint32_t PointsPerLevel = 1;
        uint32_t LevelStep = 1;

        // Percent granted PER RANK for each node (rank * PerRank = total percent bonus).
        std::array<std::array<float, NODES_PER_TREE>, TREE_COUNT> PerRank{};
    };

    Config& GetConfig();

    // ---------------------------------------------------------------------
    //  Schema (characters DB, programmatic - see WorldScript::OnStartup)
    // ---------------------------------------------------------------------

    void EnsureSchema();

    // Credits Config::PointsPerLevel to the account's shared pool and reapplies perks. Called
    // from PlayerScript::OnPlayerLevelChanged when GetLevel() crosses a Config::LevelStep
    // boundary. No-op for a null player / disabled module.
    void CreditLevelUpPoints(Player* player);

    // ---------------------------------------------------------------------
    //  Per-session cache (Player::CustomData), loaded on login / refreshed after buy/reset.
    // ---------------------------------------------------------------------

    struct CharacterCache : public DataMap::Base
    {
        bool loaded = false;
        uint32_t accountId = 0;
        uint32_t accountPointsEarned = 0;   // legacy_account.points_earned
        uint32_t accountPointsSpent = 0;    // sum over ALL characters on the account
        std::array<std::array<uint8_t, NODES_PER_TREE>, TREE_COUNT> ranks{}; // THIS character only
    };

    // Loads/refreshes the cache for `player` from the DB. Safe to call repeatedly (e.g. after
    // a buy/reset). No-op for a null player.
    void LoadCache(Player* player);

    // Read-only lookup, works from a `Player const*` (used by const PlayerScript hooks such as
    // OnPlayerGetReputationPriceDiscount). Returns nullptr if the cache has not been loaded yet.
    CharacterCache const* GetCache(Player const* player);

    // Points still available to spend, account-wide (accountPointsEarned - accountPointsSpent).
    // 0 if the cache has not been loaded.
    uint32_t GetAvailablePoints(Player const* player);

    // ---------------------------------------------------------------------
    //  Applying perks
    // ---------------------------------------------------------------------

    // (Re)applies every perk that needs an explicit push (currently: the move-speed carrier
    // aura). The other perks are read live from the cache by their respective hooks and need
    // no separate "apply" step. Call on login and after every buy/reset.
    void ApplyPerks(Player* player);

    // Percent bonuses read live by the PlayerScript hooks. All return 0 if the cache isn't
    // loaded yet or the node is at rank 0.
    float GetXpBonusPercent(Player const* player);
    float GetExploreXpBonusPercent(Player const* player);
    float GetGatherRateBonusPercent(Player const* player);
    float GetCraftRateBonusPercent(Player const* player);
    float GetKillGoldBonusPercent(Player const* player);
    float GetVendorDiscountPercent(Player const* player);
    float GetRepairDiscountPercent(Player const* player);

    // ---------------------------------------------------------------------
    //  Spending
    // ---------------------------------------------------------------------

    enum class BuyResult
    {
        Success,
        Disabled,
        InvalidTree,
        InvalidNode,
        Stub,
        AlreadyMaxRank,
        NotEnoughPoints
    };

    char const* ToString(BuyResult result);

    // Raises the given node by one rank for `player`'s character, spending from the
    // account-wide pool. Persists to the DB, refreshes the cache and re-applies perks.
    BuyResult BuyNode(Player* player, uint8_t tree, uint8_t node);

    // Refunds every node THIS character has bought (does not touch other characters on the
    // account). Persists, refreshes the cache and re-applies perks. Returns points refunded.
    uint32_t ResetCharacter(Player* player);
}

#endif // MOD_LEGACY_H
