
var hoadonModel = require('../models/hoadon.model.js')
var HoaDon = new hoadonModel()

exports.getList = (req, res) => {
    HoaDon.getAll((err, data) => {
        res.send({
            result: data, 
            error: err, 
            pageCount: Math.ceil(data.length / 10)
        })
    })
}

exports.getById = (req, res) => {
    HoaDon.getOne(req.params.MaHD, (err, data) => {
        res.send({result: data, error: err})
    })
}

exports.getPage = (req, res) => {
    var page = parseInt(req.params.page) || 1;
    var perPage = 10;
    var start = (page - 1) * perPage;
    var end = page * perPage;
    
    HoaDon.getAll((err, data) => {
        res.send({result: data.slice(start, end), error: err,})
    })
}

exports.getById = (req, res) => {
    HoaDon.getOne(req.params.MaHD, (err, data) => {
        res.send({result: data, error: err})
    })
}

exports.getListStatistic = (req, res) => {
    HoaDon.getOfMonth(req.params.month, (err, data) => {
        res.send({result: data, error: err})
    })
}

exports.addNew = (req, res) => {
    HoaDon.create(req.body, (err, data) => {
        res.send({result: data, error: err})
    })
}

exports.update = (req, res) => {
    HoaDon.update(req.params.MaHD, req.body, (err, data) => {
        res.send({result: data, error: err})
    })
}

exports.delete = (req, res) => {
    HoaDon.delete(req.params.MaHD, (err, data) => {
        res.send({result: data, error: err})
    })
}