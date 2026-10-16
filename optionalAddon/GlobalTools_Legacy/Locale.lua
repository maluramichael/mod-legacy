--[[
    GlobalTools_Legacy - localization

    All player-facing text lives here, keyed by client locale. enUS is the base
    and is always complete; every other locale only needs to override the keys it
    wants to translate, anything missing falls back to enUS.

    NOTE: strings that are matched against the server's chat output (in Legacy.lua)
    are NOT localized here. The server answers in English, so that parsing stays in
    English on purpose.
]]

GlobalToolsLegacy = GlobalToolsLegacy or {}
local L = GlobalToolsLegacy

L.locales = {}

-- ============================================================================
-- enUS (base / fallback)
-- ============================================================================
L.locales.enUS = {
    PANEL_TITLE        = "Legacy System",
    POINTS_LOADING     = "Available Points: |cff00ff00Loading...|r",
    POINTS_FMT         = "Available Account Legacy Points: |cff00ff00%d point(s)|r",
    BTN_SYNC           = "Sync",
    BTN_BUY            = "+1 Rank",
    BTN_RESET          = "Reset Spent Points",
    BTN_DEFAULT        = "Open",
    BADGE_LOCKED       = "|cff808080[Locked]|r",
    BADGE_RANK0        = "|cffffd100Rank 0/3|r",
    BADGE_MAX          = "|cff00ff00[Rank 3/3 MAX]|r",
    BADGE_RANK_FMT     = "|cffffd100[Rank %d/3]|r |cff808080(Next: %d pt)|r",
    CONFIRM_ACCEPT     = "Accept",
    CONFIRM_CANCEL     = "Cancel",
    COMBAT_WARN        = "|cffff2020[Legacy] Warning: You are in combat.|r",
    CONFIRM_BUY_FMT    = "Spend Legacy point(s) to raise %s?",
    CONFIRM_RESET      = "Are you sure you want to reset all Legacy points?",
    WINDOW_TITLE       = "|cff00ccffGlobalTools|r Legacy",

    MENU_STATUS_NAME   = "Check Legacy Points",
    MENU_STATUS_DESC   = "Shows your available points and current ranks in chat.",
    CONFIRM_MENU_BUY_FMT = "Spend 1 Legacy point on %s?",
    MENU_RESET_NAME    = "|cffff2020Reset Legacy Points|r",
    MENU_RESET_DESC    = "Returns all points spent by this character to the account pool.",
    CONFIRM_MENU_RESET = "Are you sure you want to reset (Refund) all Legacy nodes of this character?",
    MENU_ROOT_NAME     = "Legacy System",
    MENU_ROOT_TOOLTIP  = "Account-bound progression. Spend Legacy points across 3 perk trees.",

    HUB_MODULE_NAME    = "Legacy System",
    HUB_HELP           = "|cffffd100/glegacy|r - Opens the Legacy window",

    PRINT_SYNCING      = "Syncing Legacy points...",
    PRINT_HIDECHAT_FMT = "Hide chat responses: %s",
    PRINT_YES          = "|cff00ff00yes|r",
    PRINT_NO           = "|cffff2020no|r",
    PRINT_HELP         = "Commands: |cffffd100/glegacy|r opens the window, |cffffd100/glegacy sync|r syncs, |cffffd100/glegacy chat|r hides/shows chat responses.",

    trees = {
        tree_adventure = {
            tabTitle = "|cff33ff33Tree 1: Adventure|r",
            menuName = "Tree: Adventure (Speed & XP)",
            menuDesc = "Movement speed and experience bonuses.",
            nodes = {
                leg_adv_1 = {
                    tabDesc  = "+Passive movement speed.",
                    menuName = "Swift Boots (+Move Speed)",
                    menuDesc = "Increases your character's passive movement speed.",
                },
                leg_adv_2 = {
                    tabDesc  = "+XP from all sources.",
                    menuName = "Quick Study (+Global XP)",
                    menuDesc = "Increases experience gained from all sources.",
                },
                leg_adv_3 = {
                    tabDesc  = "+Extra XP from exploration.",
                    menuName = "Wanderlust (+Exploration XP)",
                    menuDesc = "Experience bonus for discovering new areas (stacks with Quick Study).",
                },
            },
        },
        tree_professions = {
            tabTitle = "|cff33ccffTree 2: Professions|r",
            menuName = "Tree: Professions (Leveling & Crafting)",
            menuDesc = "Improvements for gathering and crafting items.",
            nodes = {
                leg_prof_1 = {
                    tabDesc  = "+Gathering skill-up chance.",
                    menuName = "Steady Hands (+Gathering Skill)",
                    menuDesc = "Increases skill-up chance for Mining, Herbalism and Skinning.",
                },
                leg_prof_2 = {
                    tabDesc  = "+Crafting skill-up chance.",
                    menuName = "Master Crafter (+Crafting Skill)",
                    menuDesc = "Increases skill-up chance in crafting professions.",
                },
                leg_prof_3 = {
                    tabDesc  = "Reserved node in v1 (locked).",
                    menuName = "|cff808080Bountiful Harvest (Locked)|r",
                    menuDesc = "Node reserved for future server updates.",
                },
            },
        },
        tree_resources = {
            tabTitle = "|cffffd100Tree 3: Resourcefulness|r",
            menuName = "Tree: Resourcefulness (Gold & Discounts)",
            menuDesc = "More gold from creatures and discounts at vendors and repairs.",
            nodes = {
                leg_res_1 = {
                    tabDesc  = "+Gold looted from creatures and chests.",
                    menuName = "Grave Robber (+Loot Gold)",
                    menuDesc = "Increases coins obtained from creatures and chests.",
                },
                leg_res_2 = {
                    tabDesc  = "Discount on vendor purchases.",
                    menuName = "Haggler (Vendor Discount)",
                    menuDesc = "Discount when buying from faction vendors.",
                },
                leg_res_3 = {
                    tabDesc  = "Additional discount on equipment repairs.",
                    menuName = "Frugal Repairs (Repair Discount)",
                    menuDesc = "Additional discount on equipment repair costs.",
                },
            },
        },
    },
}

-- ============================================================================
-- deDE
-- ============================================================================
L.locales.deDE = {
    PANEL_TITLE        = "Legacy-System",
    POINTS_LOADING     = "Verfügbare Punkte: |cff00ff00Lädt...|r",
    POINTS_FMT         = "Verfügbare Account-Legacy-Punkte: |cff00ff00%d Punkt(e)|r",
    BTN_SYNC           = "Synchronisieren",
    BTN_BUY            = "+1 Rang",
    BTN_RESET          = "Ausgegebene Punkte zurücksetzen",
    BTN_DEFAULT        = "Öffnen",
    BADGE_LOCKED       = "|cff808080[Gesperrt]|r",
    BADGE_RANK0        = "|cffffd100Rang 0/3|r",
    BADGE_MAX          = "|cff00ff00[Rang 3/3 MAX]|r",
    BADGE_RANK_FMT     = "|cffffd100[Rang %d/3]|r |cff808080(Nächster: %d Pkt)|r",
    CONFIRM_ACCEPT     = "Akzeptieren",
    CONFIRM_CANCEL     = "Abbrechen",
    COMBAT_WARN        = "|cffff2020[Legacy] Warnung: Du bist im Kampf.|r",
    CONFIRM_BUY_FMT    = "Legacy-Punkt(e) ausgeben, um %s zu verbessern?",
    CONFIRM_RESET      = "Möchtest du wirklich alle Legacy-Punkte zurücksetzen?",
    WINDOW_TITLE       = "|cff00ccffGlobalTools|r Legacy",

    MENU_STATUS_NAME   = "Legacy-Punkte anzeigen",
    MENU_STATUS_DESC   = "Zeigt deine verfügbaren Punkte und aktuellen Ränge im Chat.",
    CONFIRM_MENU_BUY_FMT = "1 Legacy-Punkt für %s ausgeben?",
    MENU_RESET_NAME    = "|cffff2020Legacy-Punkte zurücksetzen|r",
    MENU_RESET_DESC    = "Gibt alle von diesem Charakter ausgegebenen Punkte an den Account-Pool zurück.",
    CONFIRM_MENU_RESET = "Möchtest du wirklich alle Legacy-Knoten dieses Charakters zurücksetzen (Refund)?",
    MENU_ROOT_NAME     = "Legacy-System",
    MENU_ROOT_TOOLTIP  = "Account-gebundener Fortschritt. Gib Legacy-Punkte in 3 Vorteilsbäumen aus.",

    HUB_MODULE_NAME    = "Legacy-System",
    HUB_HELP           = "|cffffd100/glegacy|r - Öffnet das eigene Legacy-Fenster",

    PRINT_SYNCING      = "Synchronisiere Legacy-Punkte...",
    PRINT_HIDECHAT_FMT = "Chat-Antworten ausblenden: %s",
    PRINT_YES          = "|cff00ff00ja|r",
    PRINT_NO           = "|cffff2020nein|r",
    PRINT_HELP         = "Befehle: |cffffd100/glegacy|r öffnet das Fenster, |cffffd100/glegacy sync|r synchronisiert, |cffffd100/glegacy chat|r blendet die Chat-Antworten aus/ein.",

    trees = {
        tree_adventure = {
            tabTitle = "|cff33ff33Baum 1: Abenteuer|r",
            menuName = "Baum: Abenteuer (Tempo & XP)",
            menuDesc = "Verbesserungen für Lauftempo und Erfahrungsbonus.",
            nodes = {
                leg_adv_1 = {
                    tabDesc  = "+Passives Lauftempo.",
                    menuName = "Swift Boots (+Lauftempo)",
                    menuDesc = "Erhöht das passive Lauftempo deines Charakters.",
                },
                leg_adv_2 = {
                    tabDesc  = "+XP aus allen Quellen.",
                    menuName = "Quick Study (+XP global)",
                    menuDesc = "Erhöht die Erfahrung aus allen Quellen.",
                },
                leg_adv_3 = {
                    tabDesc  = "+Zusätzliche XP beim Erkunden.",
                    menuName = "Wanderlust (+Erkundungs-XP)",
                    menuDesc = "Erfahrungsbonus beim Entdecken neuer Gebiete (stapelt mit Quick Study).",
                },
            },
        },
        tree_professions = {
            tabTitle = "|cff33ccffBaum 2: Berufe|r",
            menuName = "Baum: Berufe (Lernen & Herstellen)",
            menuDesc = "Verbesserungen für Sammeln und Herstellen von Gegenständen.",
            nodes = {
                leg_prof_1 = {
                    tabDesc  = "+Chance auf Fertigkeitspunkte beim Sammeln.",
                    menuName = "Steady Hands (+Sammel-Fertigkeit)",
                    menuDesc = "Erhöht die Chance auf Fertigkeitspunkte bei Bergbau, Kräuterkunde und Kürschnerei.",
                },
                leg_prof_2 = {
                    tabDesc  = "+Chance auf Fertigkeitspunkte beim Herstellen.",
                    menuName = "Master Crafter (+Herstellungs-Fertigkeit)",
                    menuDesc = "Erhöht die Chance auf Fertigkeitspunkte in Herstellungsberufen.",
                },
                leg_prof_3 = {
                    tabDesc  = "In v1 reservierter Knoten (gesperrt).",
                    menuName = "|cff808080Bountiful Harvest (Gesperrt)|r",
                    menuDesc = "Für künftige Server-Updates reservierter Knoten.",
                },
            },
        },
        tree_resources = {
            tabTitle = "|cffffd100Baum 3: Ressourcen|r",
            menuName = "Baum: Ressourcen (Gold & Rabatte)",
            menuDesc = "Mehr Gold von Kreaturen und Rabatte bei Händlern und Reparaturen.",
            nodes = {
                leg_res_1 = {
                    tabDesc  = "+Gold aus Kreaturen und Truhen.",
                    menuName = "Grave Robber (+Beute-Gold)",
                    menuDesc = "Erhöht die Menge an Münzen von Kreaturen und Truhen.",
                },
                leg_res_2 = {
                    tabDesc  = "Rabatt bei Händlerkäufen.",
                    menuName = "Haggler (Händlerrabatt)",
                    menuDesc = "Rabatt beim Kauf bei Fraktionshändlern.",
                },
                leg_res_3 = {
                    tabDesc  = "Zusätzlicher Rabatt bei Ausrüstungsreparatur.",
                    menuName = "Frugal Repairs (Reparaturrabatt)",
                    menuDesc = "Zusätzlicher Rabatt auf die Reparaturkosten der Ausrüstung.",
                },
            },
        },
    },
}

-- ============================================================================
-- esES (original Spanish from the addon author)
-- ============================================================================
L.locales.esES = {
    PANEL_TITLE        = "Sistema Legacy",
    POINTS_LOADING     = "Puntos Disponibles: |cff00ff00Cargando...|r",
    POINTS_FMT         = "Puntos Legacy de Cuenta Disponibles: |cff00ff00%d Punto(s)|r",
    BTN_SYNC           = "Sincronizar",
    BTN_BUY            = "+1 Rango",
    BTN_RESET          = "Reiniciar Puntos Gastados",
    BTN_DEFAULT        = "Abrir",
    BADGE_LOCKED       = "|cff808080[Bloqueado]|r",
    BADGE_RANK0        = "|cffffd100Rango 0/3|r",
    BADGE_MAX          = "|cff00ff00[Rango 3/3 MAX]|r",
    BADGE_RANK_FMT     = "|cffffd100[Rango %d/3]|r |cff808080(Sig: %d pt)|r",
    CONFIRM_ACCEPT     = "Aceptar",
    CONFIRM_CANCEL     = "Cancelar",
    COMBAT_WARN        = "|cffff2020[Legacy] Advertencia: Estás en combate.|r",
    CONFIRM_BUY_FMT    = "¿Gastar punto(s) Legacy en mejorar %s?",
    CONFIRM_RESET      = "¿Estás seguro de que deseas reiniciar todos los puntos Legacy?",
    WINDOW_TITLE       = "|cff00ccffGlobalTools|r Legacy",

    MENU_STATUS_NAME   = "Consultar Puntos Legacy",
    MENU_STATUS_DESC   = "Muestra en el chat tus puntos disponibles y rangos actuales.",
    CONFIRM_MENU_BUY_FMT = "¿Gastar 1 punto Legacy en %s?",
    MENU_RESET_NAME    = "|cffff2020Reiniciar Puntos Legacy|r",
    MENU_RESET_DESC    = "Devuelve todos los puntos gastados por este personaje al pozo de la cuenta.",
    CONFIRM_MENU_RESET = "¿Estás seguro de que deseas reiniciar (Refund) todos los nodos Legacy de este personaje?",
    MENU_ROOT_NAME     = "Sistema Legacy",
    MENU_ROOT_TOOLTIP  = "Progresión ligada a la cuenta. Gasta puntos Legacy en 3 árboles de ventajas.",

    HUB_MODULE_NAME    = "Sistema Legacy",
    HUB_HELP           = "|cffffd100/glegacy|r - Abre la ventana propia de Legacy",

    PRINT_SYNCING      = "Sincronizando puntos Legacy...",
    PRINT_HIDECHAT_FMT = "Ocultar respuestas del chat: %s",
    PRINT_YES          = "|cff00ff00sí|r",
    PRINT_NO           = "|cffff2020no|r",
    PRINT_HELP         = "Comandos: |cffffd100/glegacy|r abre la ventana, |cffffd100/glegacy sync|r sincroniza, |cffffd100/glegacy chat|r oculta/muestra las respuestas del chat.",

    trees = {
        tree_adventure = {
            tabTitle = "|cff33ff33Árbol 1: Aventura|r",
            menuName = "Árbol: Aventura (Velocidad y XP)",
            menuDesc = "Mejoras de velocidad de movimiento y bonificación de experiencia.",
            nodes = {
                leg_adv_1 = {
                    tabDesc  = "+Velocidad de Movimiento pasiva.",
                    menuName = "Swift Boots (+Velocidad de Mov.)",
                    menuDesc = "Aumenta la velocidad de movimiento pasiva de tu personaje.",
                },
                leg_adv_2 = {
                    tabDesc  = "+XP de todas las fuentes de juego.",
                    menuName = "Quick Study (+XP Global)",
                    menuDesc = "Incrementa la experiencia obtenida de todas las fuentes.",
                },
                leg_adv_3 = {
                    tabDesc  = "+XP adicional al explorar zonas.",
                    menuName = "Wanderlust (+XP Exploración)",
                    menuDesc = "Bonus de experiencia al descubrir nuevas zonas (se acumula con Quick Study).",
                },
            },
        },
        tree_professions = {
            tabTitle = "|cff33ccffÁrbol 2: Profesiones|r",
            menuName = "Árbol: Profesiones (Subida y Crafteo)",
            menuDesc = "Mejoras para recolección y creación de objetos.",
            nodes = {
                leg_prof_1 = {
                    tabDesc  = "+Probabilidad de subir skill en recolección.",
                    menuName = "Steady Hands (+Skill Recolección)",
                    menuDesc = "Aumenta la probabilidad de subir habilidad en Minería, Herboristería y Desuello.",
                },
                leg_prof_2 = {
                    tabDesc  = "+Probabilidad de subir skill en crafteo.",
                    menuName = "Master Crafter (+Skill Crafteo)",
                    menuDesc = "Aumenta la probabilidad de subir nivel en profesiones de crafteo.",
                },
                leg_prof_3 = {
                    tabDesc  = "Nodo reservado en v1 (bloqueado).",
                    menuName = "|cff808080Bountiful Harvest (Bloqueado)|r",
                    menuDesc = "Nodo reservado para futuras actualizaciones del servidor.",
                },
            },
        },
        tree_resources = {
            tabTitle = "|cffffd100Árbol 3: Recursos|r",
            menuName = "Árbol: Recursos (Oro y Descuentos)",
            menuDesc = "Más oro de criaturas y descuentos en vendedores y reparaciones.",
            nodes = {
                leg_res_1 = {
                    tabDesc  = "+Oro saqueado de criaturas y cofres.",
                    menuName = "Grave Robber (+Oro de Botín)",
                    menuDesc = "Aumenta la cantidad de monedas obtenidas de criaturas y cofres.",
                },
                leg_res_2 = {
                    tabDesc  = "Descuento en compras a vendedores.",
                    menuName = "Haggler (Descuento Vendedores)",
                    menuDesc = "Descuento en compras a vendedores de facción.",
                },
                leg_res_3 = {
                    tabDesc  = "Descuento adicional en reparación de equipo.",
                    menuName = "Frugal Repairs (Descuento Reparación)",
                    menuDesc = "Descuento adicional en el coste de reparar equipo.",
                },
            },
        },
    },
}

-- esMX shares the Spanish text
L.locales.esMX = L.locales.esES

-- ============================================================================
-- frFR
-- ============================================================================
L.locales.frFR = {
    PANEL_TITLE        = "Système Legacy",
    POINTS_LOADING     = "Points disponibles : |cff00ff00Chargement...|r",
    POINTS_FMT         = "Points Legacy de compte disponibles : |cff00ff00%d point(s)|r",
    BTN_SYNC           = "Synchroniser",
    BTN_BUY            = "+1 rang",
    BTN_RESET          = "Réinitialiser les points dépensés",
    BTN_DEFAULT        = "Ouvrir",
    BADGE_LOCKED       = "|cff808080[Verrouillé]|r",
    BADGE_RANK0        = "|cffffd100Rang 0/3|r",
    BADGE_MAX          = "|cff00ff00[Rang 3/3 MAX]|r",
    BADGE_RANK_FMT     = "|cffffd100[Rang %d/3]|r |cff808080(Suivant : %d pt)|r",
    CONFIRM_ACCEPT     = "Accepter",
    CONFIRM_CANCEL     = "Annuler",
    COMBAT_WARN        = "|cffff2020[Legacy] Attention : vous êtes en combat.|r",
    CONFIRM_BUY_FMT    = "Dépenser des points Legacy pour améliorer %s ?",
    CONFIRM_RESET      = "Voulez-vous vraiment réinitialiser tous les points Legacy ?",
    WINDOW_TITLE       = "|cff00ccffGlobalTools|r Legacy",

    MENU_STATUS_NAME   = "Consulter les points Legacy",
    MENU_STATUS_DESC   = "Affiche dans le chat vos points disponibles et vos rangs actuels.",
    CONFIRM_MENU_BUY_FMT = "Dépenser 1 point Legacy pour %s ?",
    MENU_RESET_NAME    = "|cffff2020Réinitialiser les points Legacy|r",
    MENU_RESET_DESC    = "Rend tous les points dépensés par ce personnage à la réserve du compte.",
    CONFIRM_MENU_RESET = "Voulez-vous vraiment réinitialiser (rembourser) tous les nœuds Legacy de ce personnage ?",
    MENU_ROOT_NAME     = "Système Legacy",
    MENU_ROOT_TOOLTIP  = "Progression liée au compte. Dépensez des points Legacy dans 3 arbres d'avantages.",

    HUB_MODULE_NAME    = "Système Legacy",
    HUB_HELP           = "|cffffd100/glegacy|r - Ouvre la fenêtre Legacy",

    PRINT_SYNCING      = "Synchronisation des points Legacy...",
    PRINT_HIDECHAT_FMT = "Masquer les réponses du chat : %s",
    PRINT_YES          = "|cff00ff00oui|r",
    PRINT_NO           = "|cffff2020non|r",
    PRINT_HELP         = "Commandes : |cffffd100/glegacy|r ouvre la fenêtre, |cffffd100/glegacy sync|r synchronise, |cffffd100/glegacy chat|r masque/affiche les réponses du chat.",

    trees = {
        tree_adventure = {
            tabTitle = "|cff33ff33Arbre 1 : Aventure|r",
            menuName = "Arbre : Aventure (Vitesse et XP)",
            menuDesc = "Améliorations de vitesse de déplacement et bonus d'expérience.",
            nodes = {
                leg_adv_1 = {
                    tabDesc  = "+Vitesse de déplacement passive.",
                    menuName = "Swift Boots (+Vitesse de dépl.)",
                    menuDesc = "Augmente la vitesse de déplacement passive de votre personnage.",
                },
                leg_adv_2 = {
                    tabDesc  = "+XP de toutes les sources.",
                    menuName = "Quick Study (+XP globale)",
                    menuDesc = "Augmente l'expérience obtenue de toutes les sources.",
                },
                leg_adv_3 = {
                    tabDesc  = "+XP supplémentaire à l'exploration.",
                    menuName = "Wanderlust (+XP d'exploration)",
                    menuDesc = "Bonus d'expérience en découvrant de nouvelles zones (cumulable avec Quick Study).",
                },
            },
        },
        tree_professions = {
            tabTitle = "|cff33ccffArbre 2 : Métiers|r",
            menuName = "Arbre : Métiers (Progression et artisanat)",
            menuDesc = "Améliorations pour la récolte et la fabrication d'objets.",
            nodes = {
                leg_prof_1 = {
                    tabDesc  = "+Chance de gain de compétence en récolte.",
                    menuName = "Steady Hands (+Compétence de récolte)",
                    menuDesc = "Augmente la chance de gagner des points de compétence en minage, herboristerie et dépeçage.",
                },
                leg_prof_2 = {
                    tabDesc  = "+Chance de gain de compétence en artisanat.",
                    menuName = "Master Crafter (+Compétence d'artisanat)",
                    menuDesc = "Augmente la chance de gagner des points de compétence dans les métiers de fabrication.",
                },
                leg_prof_3 = {
                    tabDesc  = "Nœud réservé en v1 (verrouillé).",
                    menuName = "|cff808080Bountiful Harvest (Verrouillé)|r",
                    menuDesc = "Nœud réservé pour de futures mises à jour du serveur.",
                },
            },
        },
        tree_resources = {
            tabTitle = "|cffffd100Arbre 3 : Ressources|r",
            menuName = "Arbre : Ressources (Or et remises)",
            menuDesc = "Plus d'or des créatures et des remises chez les marchands et pour les réparations.",
            nodes = {
                leg_res_1 = {
                    tabDesc  = "+Or pillé sur les créatures et les coffres.",
                    menuName = "Grave Robber (+Or de butin)",
                    menuDesc = "Augmente la quantité de pièces obtenues des créatures et des coffres.",
                },
                leg_res_2 = {
                    tabDesc  = "Remise sur les achats chez les marchands.",
                    menuName = "Haggler (Remise marchand)",
                    menuDesc = "Remise lors des achats chez les marchands de faction.",
                },
                leg_res_3 = {
                    tabDesc  = "Remise supplémentaire sur la réparation de l'équipement.",
                    menuName = "Frugal Repairs (Remise réparation)",
                    menuDesc = "Remise supplémentaire sur le coût de réparation de l'équipement.",
                },
            },
        },
    },
}

-- ============================================================================
-- Resolve the active locale (client locale, else same language, else enUS)
-- and build L.T by overlaying it on the enUS base so missing keys fall back.
-- ============================================================================
local function deepmerge(base, over)
    local out = {}
    for k, v in pairs(base) do
        if type(v) == "table" then out[k] = deepmerge(v, nil) else out[k] = v end
    end
    if type(over) == "table" then
        for k, v in pairs(over) do
            if type(v) == "table" and type(out[k]) == "table" then
                out[k] = deepmerge(out[k], v)
            else
                out[k] = v
            end
        end
    end
    return out
end

local function pickLocale()
    local code = (GetLocale and GetLocale()) or "enUS"
    if L.locales[code] then return code end
    local lang = code:sub(1, 2)
    for c in pairs(L.locales) do
        if c:sub(1, 2) == lang then return c end
    end
    return "enUS"
end

local code = pickLocale()
L.T = deepmerge(L.locales.enUS, code ~= "enUS" and L.locales[code] or nil)
L.T.code = code
