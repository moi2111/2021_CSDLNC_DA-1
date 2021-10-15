const {conn, sql} = require('../../connect.js')

var hoadonModel = require('../models/hoadon.model.js')
var model = new hoadonModel()

exports.getList = (req, res) => {
    model.getAll((err, data) => {
        res.send({result: data, error: err})
    })
}

exports.getById = (req, res) => {
    model.getOne(req.params.MaHD, (err, data) => {
        res.send({result: data, error: err})
    })
}
exports.addNew = (req, res) => {
    model.create(req.body, (err, data) => {
        res.send({result: data, error: err})
    })
}
exports.update = (req, res) => {
    model.update(req.params.MaHD, req.body, (err, data) => {
        res.send({result: data, error: err})
    })
}
exports.delete = (req, res) => {
    model.delete(req.params.MaHD, (err, data) => {
        res.send({result: data, error: err})
    })
}