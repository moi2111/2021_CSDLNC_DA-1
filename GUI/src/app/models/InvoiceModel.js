const config = require('../../config/db/dbconfig')
const sql = require('mssql');

module.exports = function () {

    this.getAll = async () => {
        try {
            let pool = await sql.connect(config);
            let invoices = await pool.request().query("SELECT * FROM HoaDon");
            return invoices.recordset;
        }
        catch (error) {
            console.log(error);
        }
    }

    this.addInvoice = async (invoice) => {
        try {
            let pool = await sql.connect(config);
            await pool.request()
                .input('makh', sql.Int, invoice.MaKH)
                .input('ngaylap', sql.DateTime, invoice.NgayLap)
                .query("INSERT INTO HoaDon (MaKH, NgayLap) VALUES(@makh, @ngaylap)")
        }
        catch (err) {
            console.log(err);
        }
    }

    this.getMonth = async (month) => {
        try {
            let pool = await sql.connect(config);
            let invoices = await pool.request()
                .input('month', sql.Int, month)
                .query("SELECT * FROM HoaDon WHERE MONTH(NgayLap) = @month")
            return invoices.recordset;
        }
        catch (err) {
            console.log(err);
        }
    }
}