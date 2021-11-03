const express = require('express');
const router = express.Router();

const invoiceController = require('../app/controllers/InvoiceController')

router.get('/create',invoiceController.create)

router.post('/create', invoiceController.add)

router.get('/statistic',invoiceController.statistic)

router.get('/details',invoiceController.details)

router.post('/details',invoiceController.addDetails)

router.get('/', invoiceController.getList)


module.exports = router
