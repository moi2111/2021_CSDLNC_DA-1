const invoicesRouter = require('./invoice');

function route(app) {
    app.use('/invoices', invoicesRouter);

}

module.exports = route;
