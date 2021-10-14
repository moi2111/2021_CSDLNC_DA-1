var db = require('../utils/db');

exports.all = () => {
  return db.load('select * from students');
}

exports.single = id => {
  return db.load(`select * from students where id = ${id}`);
}

exports.add = entity => {
  return db.add('students', entity);
}

exports.del = id => {
  return db.del('students', 'id', id);
}

exports.patch = (id, entityWoId) => {
  return db.patch('students', 'id', id, entityWoId);
}