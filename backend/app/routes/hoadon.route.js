
module.exports = (app) => {
    var hoadonController = require('../controllers/hoadon.controller.js')

    app.get('/hoadon',hoadonController.getList)
    
    app.get('/hoadon/:MaHD', hoadonController.getById)

    app.post('/hoadon', hoadonController.addNew)
    
    app.patch('/hoadon/:MaHD', hoadonController.update)
    
    app.delete('/hoadon/:MaHD', hoadonController.delete)
}

