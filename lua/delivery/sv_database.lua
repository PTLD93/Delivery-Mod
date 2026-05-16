sql.Query([[
    CREATE TABLE IF NOT EXISTS delivery_npcs (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        map      TEXT NOT NULL DEFAULT '',
        npc_key  TEXT NOT NULL,
        pos_x    REAL NOT NULL,
        pos_y    REAL NOT NULL,
        pos_z    REAL NOT NULL,
        ang_p    REAL NOT NULL,
        ang_y    REAL NOT NULL,
        ang_r    REAL NOT NULL
    )
]])

sql.Query("ALTER TABLE delivery_npcs ADD COLUMN map TEXT NOT NULL DEFAULT ''")

function Delivery_SaveNPC(npcKey, pos, ang)
    local map = game.GetMap()
    sql.Query(string.format([[
        INSERT INTO delivery_npcs (map, npc_key, pos_x, pos_y, pos_z, ang_p, ang_y, ang_r)
        VALUES (%s, %s, %f, %f, %f, %f, %f, %f)
    ]],
        sql.SQLStr(map),
        sql.SQLStr(npcKey),
        pos.x, pos.y, pos.z,
        ang.p, ang.y, ang.r
    ))

    local id = sql.QueryValue("SELECT last_insert_rowid()")
    return tonumber(id)
end

function Delivery_DeleteNPC(id)
    sql.Query("DELETE FROM delivery_npcs WHERE id = " .. tonumber(id))
end

function Delivery_LoadAllNPCs()
    local rows = sql.Query("SELECT * FROM delivery_npcs WHERE map = " .. sql.SQLStr(game.GetMap()))
    if not rows then return {} end
    return rows
end

function Delivery_ClearAllNPCs()
    sql.Query("DELETE FROM delivery_npcs WHERE map = " .. sql.SQLStr(game.GetMap()))
end
