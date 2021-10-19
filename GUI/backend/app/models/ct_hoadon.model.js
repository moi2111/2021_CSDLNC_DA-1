const {conn, sql} = require('../../connect.js')

module.exports = function () {
    this.getAll = async (result) => {
        var pool = await conn
        var sqlString = "SELECT * FROM CT_HoaDon"
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
        var sqlString = "SELECT * FROM CT_HoaDon WHERE MaHD = @varMaHD"
        return await pool.request()
        .input('varMaHD', sql.Int, MaHD)
        .query(sqlString, (err, data) => {
            if(data.recordset.length > 0) {
                result(null, data.recordset)
            } else {
                result(true, null)
            }
        }) 
    }

    this.create = async (newData, result) => {
        var pool = await conn
        var sqlString = "INSERT INTO CT_HoaDon (MaHD, MaSP, SoLuong, GiaBan, GiaGiam, ThanhTien) VALUES(@mahd, @masp, @soluong, @giaban, @giagiam, @thanhtien)"
        return await pool.request()
        .input('mahd', sql.Int, newData.MaHD)
        .input('masp', sql.Int, newData.MaSP)
        .input('soluong', sql.Int, newData.SoLuong)
        .input('giaban', sql.Money, newData.GiaBan)
        .input('giagiam', sql.Float, newData.GiaGiam)
        .input('thanhtien', sql.Money, newData.ThanhTien)
        .query(sqlString, (err, data) => {
            if(err) {
                result(true, null)
            } else {
                result(null, newData)
            }
        })
    }

    // chưa tối ưu
    // this.update = async (MaHD, MaSP, newData, result) => {
    //     var pool = await conn
    //     var sqlString = "UPDATE CT_HoaDon SET SoLuong = @soluong, GiaBan = @giaban, GiaGiam = @giagiam, ThanhTien = @thanhtien WHERE MaHD = @varMaHD and MaSP = @varMaSP"
    //     return await pool.request()
    //     .input('varMaHD', sql.Int, MaHD)
    //     .input('varMaSP', sql.Int, MaSP)
    //     .input('soluong', sql.Int, newData.SoLuong)
    //     .input('giaban', sql.Money, newData.GiaBan)
    //     .input('giagiam', sql.Float, newData.GiaGiam)
    //     .input('thanhtien', sql.Money, newData.ThanhTien)
    //     .query(sqlString, (err, data) => {
    //         if(err) {
    //             result(true, null)
    //         } else {
    //             result(null, newData)
    //         }
    //     })
    // }

    // chưa tối ưu
    // this.delete = async (MaHD, result) => {
    //     var pool = await conn
    //     var sqlString = "DELETE CT_HoaDon WHERE MaHD = @varMaHD"
    //     return await pool.request()
    //     .input('varMaHD', sql.Int, MaHD)
    //     .query(sqlString, (err, data) => {
    //         if(err) {
    //             result(true, null)
    //         } else {
    //             result(null, data)
    //         }
    //     })
    // }
}