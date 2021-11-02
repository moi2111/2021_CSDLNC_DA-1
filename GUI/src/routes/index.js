const invoicesRouter = require('./invoice');

function route(app) {
    app.use('/invoices', invoicesRouter);

    app.use('/', (req, res) => {
        res.render('home')
    })
}

module.exports = route;
