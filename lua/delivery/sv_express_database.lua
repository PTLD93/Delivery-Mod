local function InitExpressDB()
    sql.Query([[
        CREATE TABLE IF NOT EXISTS express_dropoffs (
            id      INTEGER PRIMARY KEY AUTOINCREMENT,
            map     TEXT    NOT NULL,
            address TEXT    NOT NULL,
            pos_x   REAL, pos_y REAL, pos_z REAL,
            ang_p   REAL, ang_y REAL, ang_r REAL
        )
    ]])
    sql.Query([[
        CREATE TABLE IF NOT EXISTS express_npcs (
            id    INTEGER PRIMARY KEY AUTOINCREMENT,
            map   TEXT NOT NULL,
            pos_x REAL, pos_y REAL, pos_z REAL,
            ang_p REAL, ang_y REAL, ang_r REAL
        )
    ]])
end
InitExpressDB()

function ExpressDB_SaveDropoff(map, address, pos, ang)
    local res = sql.Query(string.format(
        "INSERT INTO express_dropoffs (map, address, pos_x, pos_y, pos_z, ang_p, ang_y, ang_r) VALUES (%s, %s, %f, %f, %f, %f, %f, %f)",
        sql.SQLStr(map), sql.SQLStr(address), pos.x, pos.y, pos.z, ang.p, ang.y, ang.r
    ))
    if res == false then return nil end
    local row = sql.QueryRow("SELECT last_insert_rowid() AS id")
    return row and tonumber(row.id)
end

function ExpressDB_GetDropoffs(map)
    local rows = sql.Query(string.format(
        "SELECT * FROM express_dropoffs WHERE map = %s", sql.SQLStr(map)
    ))
    return rows or {}
end

function ExpressDB_DeleteDropoff(id)
    sql.Query("DELETE FROM express_dropoffs WHERE id = " .. tonumber(id))
end

function ExpressDB_ClearDropoffs(map)
    sql.Query("DELETE FROM express_dropoffs WHERE map = " .. sql.SQLStr(map))
end

function ExpressDB_SaveNPC(map, pos, ang)
    local res = sql.Query(string.format(
        "INSERT INTO express_npcs (map, pos_x, pos_y, pos_z, ang_p, ang_y, ang_r) VALUES (%s, %f, %f, %f, %f, %f, %f)",
        sql.SQLStr(map), pos.x, pos.y, pos.z, ang.p, ang.y, ang.r
    ))
    if res == false then return nil end
    local row = sql.QueryRow("SELECT last_insert_rowid() AS id")
    return row and tonumber(row.id)
end

function ExpressDB_GetNPCs(map)
    local rows = sql.Query(string.format(
        "SELECT * FROM express_npcs WHERE map = %s", sql.SQLStr(map)
    ))
    return rows or {}
end

function ExpressDB_DeleteNPC(id)
    sql.Query("DELETE FROM express_npcs WHERE id = " .. tonumber(id))
end

function ExpressDB_ClearNPCs(map)
    sql.Query("DELETE FROM express_npcs WHERE map = " .. sql.SQLStr(map))
end
