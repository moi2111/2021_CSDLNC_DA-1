
module.exports = (app) => {
    var ct_hoadonController = require('../controllers/ct_hoadon.controller.js')

    app.get('/ct_hoadon',ct_hoadonController.getList)
    
    app.get('/ct_hoadon/:MaHD', ct_hoadonController.getById)

    app.post('/ct_hoadon', ct_hoadonController.addNew)
    
    // app.patch('/ct_hoadon/:MaHD', ct_hoadonController.update)
    
    // app.delete('/ct_hoadon/:MaHD', ct_hoadonController.delete)
}

