var sql = require('mssql/msnodesqlv8')

// Các thông tin kết nối CSDL
const config = {
    server: 'localhost\\NGOTOAIMSSQLSV', // You can use 'localhost\\instance' to connect to named instance
    user: 'toaingo',
    password: '123',
    database: 'QLBH',
    // trustServerCertificate: true,
    driver: "msnodesqlv8"
}

const conn = new sql.ConnectionPool(config)
.connect().then(pool => {
    return pool
})

// xuất ra dưới dạng module gồm 2 thuộc tính là conn và sql
module.exports = {
    conn: conn,
    sql: sql
}