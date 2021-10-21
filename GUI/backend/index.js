var express = require('express')
var bodyParser = require('body-parser')
var cors = require('cors')
var morgan = require('morgan')

var app = express() 

app.use(bodyParser.json())
app.use(cors())
app.use(express.json())
app.use(morgan('dev'))

require('./app/routes/hoadon.route.js')(app)
require('./app/routes/ct_hoadon.route.js')(app)


// mở cổng server
var port = process.env.PORT || 3000 
app.listen(port, () => {
  console.log(`backend is running on http://localhost:${port}`) 
})