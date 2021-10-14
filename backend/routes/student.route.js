var express = require('express');
var studentModel = require('../models/student.model');

var router = express.Router();

router.get('/', (req, res) => {
  studentModel.all().then(rows => {
    res.json(rows);
  })
})

router.get('/:id', (req, res) => {
  studentModel.single(req.params.id).then(rows => {
    if (rows.length > 0)
      res.json(rows[0]);
    else res.status(204).end();
  })
})

router.post('/', (req, res) => {
  studentModel.add(req.body).then(insertId => {
    res.status(201).json({
      id: insertId,
      ...req.body
    });
  })
})

router.delete('/:id', (req, res) => {
  studentModel.del(req.params.id).then(affectedRows => {
    res.json({
      resultCode: 0, // success
      affectedRows: affectedRows
    });
  })
})

router.patch('/:id', (req, res) => {
  var id = req.params.id;
  var entityWoId = req.body;
  studentModel.patch(id, entityWoId).then(changedRows => {
    res.json({
      id,
      ...req.body
    });
  });
})

module.exports = router;
