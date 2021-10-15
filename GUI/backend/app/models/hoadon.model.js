const {conn, sql} = require('../../connect.js')

module.exports = function () {
    this.getAll = async (result) => {
        var pool = await conn
        var sqlString = "SELECT * FROM HoaDon"
        return await pool.request()
        .query(sqlString, (err, data) => {
            if(data.recordset.length > 0) {
                result(null, data.recordset)
            } else {
                result(true, null)
            }
        })
    }

    this.getOne = async (MaHD, result) => {
        var pool = await conn
        var sqlString = "SELECT * FROM HoaDon WHERE MaHD = @varMaHD"
        return await pool.request()
        .input('varMaHD', sql.Int, MaHD)
        .query(sqlString, (err, data) => {
            if(data.recordset.length > 0) {
                result(null, data.recordset[0])
            } else {
                result(true, null)
            }
        }) 
    }

    this.create = async (newData, result) => {
        var pool = await conn
        var sqlString = "INSERT INTO HoaDon (MaKH, NgayLap) VALUES(@makh, @ngaylap)"
        return await pool.request()
        .input('makh', sql.Int, newData.MaKH)
        .input('ngaylap', sql.DateTime, newData.NgayLap)
        .query(sqlString, (err, data) => {
            if(err) {
                result(true, null)
            } else {
                result(null, newData)
            }
        })
    }

    this.update = async (MaHD, newData, result) => {
        var pool = await conn
        var sqlString = "UPDATE HoaDon SET MaKH = @makh, NgayLap = @ngaylap WHERE MaHD = @varMaHD"
        return await pool.request()
        .input('varMaHD', sql.Int, MaHD)
        .input('makh', sql.Int, newData.MaKH)
        .input('ngaylap', sql.DateTime, newData.NgayLap)
        .query(sqlString, (err, data) => {
            if(err) {
                result(true, null)
            } else {
                result(null, newData)
            }
        })
    }

    this.delete = async (MaHD, result) => {
        var pool = await conn
        var sqlString = "DELETE HoaDon WHERE MaHD = @varMaHD"
        return await pool.request()
        .input('varMaHD', sql.Int, MaHD)
        .query(sqlString, (err, data) => {
            if(err) {
                result(true, null)
            } else {
                result(null, data)
            }
        })
    }
}