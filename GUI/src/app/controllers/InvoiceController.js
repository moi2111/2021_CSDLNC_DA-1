
var invoiceModel = require('../models/InvoiceModel')
var Invoice = new invoiceModel()

class InvoiceController {

    // [GET] /invoices
    getList(req, res, next) {
        // pagination
        const page = parseInt(req.query.page)
        const limit = parseInt(req.query.limit) || 8

        const startIndex = (page - 1) * limit
        const endIndex = page * limit

        // render invoices
        Invoice.getAll()
            .then(invoices => {
                const results = {}

                if (endIndex < invoices.length) {
                    results.next = {
                        page: page + 1
                    }
                }
                
                if (startIndex > 0) {
                    results.previous = {
                        page: page - 1
                    }
                }
                results.pagination = Math.ceil(invoices.length / limit)
                results.invoices = invoices.slice(startIndex, endIndex)

                res.render('home', {
                    pagination: results.pagination,
                    invoices: results.invoices,
                    next: results.next,
                    previous: results.previous,
                })
                // res.json({
                //     pagination: results.pagination,
                //     next: results.next,
                //     previous: results.previous,
                //     invoices: results.invoices,
                // })
            })
            .catch(next)
    }
    
    // [GET] /invoices/create
    create(req, res, next) {
        res.render('invoices/create')
    }

    // [POST] /hinvoices/create
    add(req, res, next) {
        let invoice = {...req.body}
        Invoice.addInvoice(invoice)
            .then(() => {
                res.redirect('/invoices?page=1')
            })
            .catch(next)
    }

    // [GET] /invoices/statistic
    statistic(req, res, next) {
        const month = parseInt(req.query.month)
        Invoice.getMonth(month)
            .then(invoices => {
                res.render('invoices/statistic', {
                    invoices,
                    month: [1,2,3,4,5,6,7,8,9,10,11,12],
                })
            })
            .catch(next)
    }

    // [GET] /invoices/details
    details(req, res, next) {
        res.render('invoices/details', {
            MaHD: req.query.MaHD,
        })
    }

    // [POST] /invoices/details
    addDetails(req, res, next) {
        let detail = {...req.body}
        Invoice.addDetail(detail)
            .then(() => {
                res.redirect('/invoices?page=1')
            })
            .catch(next)
    }
}

module.exports = new InvoiceController()

