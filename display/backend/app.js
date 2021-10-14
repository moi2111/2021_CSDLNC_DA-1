var express = require('express');
var cors = require('cors');
var morgan = require('morgan');

var app = express();

app.use(morgan('dev'));
app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({
    msg: 'root'
  });
})

app.use('/students', require('./routes/student.route'));

var port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log(`backend is running on http://localhost:${port}`);
})