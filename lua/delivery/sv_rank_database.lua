sql.Query([[
    CREATE TABLE IF NOT EXISTS rank_purchases (
        steamid TEXT NOT NULL,
        level   INTEGER NOT NULL,
        PRIMARY KEY (steamid, level)
    )
]])

sql.Query([[
    CREATE TABLE IF NOT EXISTS rank_npcs (
        id    INTEGER PRIMARY KEY AUTOINCREMENT,
        map   TEXT NOT NULL DEFAULT '',
        pos_x REAL NOT NULL,
        pos_y REAL NOT NULL,
        pos_z REAL NOT NULL,
        ang_p REAL NOT NULL,
        ang_y REAL NOT NULL,
        ang_r REAL NOT NULL
    )
]])

function RankNPC_Save(pos, ang)
    local map = game.GetMap()
    sql.Query(string.format([[
        INSERT INTO rank_npcs (map, pos_x, pos_y, pos_z, ang_p, ang_y, ang_r)
        VALUES (%s, %f, %f, %f, %f, %f, %f)
    ]],
        sql.SQLStr(map),
        pos.x, pos.y, pos.z,
        ang.p, ang.y, ang.r
    ))
    return tonumber(sql.QueryValue("SELECT last_insert_rowid()"))
end

function RankNPC_Delete(id)
    sql.Query("DELETE FROM rank_npcs WHERE id = " .. tonumber(id))
end

function RankNPC_LoadAll()
    local rows = sql.Query("SELECT * FROM rank_npcs WHERE map = " .. sql.SQLStr(game.GetMap()))
    if not rows then return {} end
    return rows
end

function RankNPC_ClearAll()
    sql.Query("DELETE FROM rank_npcs WHERE map = " .. sql.SQLStr(game.GetMap()))
end

function Rank_ResetPlayer(steamid)
    sql.Query("DELETE FROM rank_purchases WHERE steamid = " .. sql.SQLStr(steamid))
end

function Rank_HasPurchased(ply, level)
    local row = sql.QueryValue(string.format(
        "SELECT 1 FROM rank_purchases WHERE steamid = %s AND level = %d",
        sql.SQLStr(ply:SteamID()), tonumber(level)
    ))
    return row == "1"
end

function Rank_SavePurchase(ply, level)
    sql.Query(string.format(
        "INSERT OR IGNORE INTO rank_purchases (steamid, level) VALUES (%s, %d)",
        sql.SQLStr(ply:SteamID()), tonumber(level)
    ))
end

function Rank_GetOwned(ply)
    local rows = sql.Query(string.format(
        "SELECT level FROM rank_purchases WHERE steamid = %s",
        sql.SQLStr(ply:SteamID())
    ))
    local owned = {}
    if rows then
        for _, row in ipairs(rows) do
            owned[tonumber(row.level)] = true
        end
    end
    return owned
end
