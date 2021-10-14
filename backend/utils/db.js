var mysql = require('mysql');

var createConnection = () => mysql.createConnection({
  host: 'localhost',
  port: 3306,
  user: 'root',
  password: 'admin',
  database: 'testDB',
});

exports.load = sql => {
  return new Promise((resolve, reject) => {
    var connection = createConnection();
    connection.connect();
    connection.query(sql, (error, results, fields) => {
      if (error) {
        reject(error);
      } else {
        resolve(results);
      }
      connection.end();
    });
  });
}

exports.add = (tableName, entity) => {
  return new Promise((resolve, reject) => {
    var sql = `insert into ${tableName} set ?`;
    var connection = createConnection();
    connection.connect();
    connection.query(sql, entity, (error, results) => {
      if (error) {
        reject(error);
      } else {
        resolve(results.insertId);
      }
      connection.end();
    });
  });
}

exports.del = (tableName, idField, id) => {
  return new Promise((resolve, reject) => {
    var sql = `delete from ${tableName} where ${idField} = ?`;
    var connection = createConnection();
    connection.connect();
    connection.query(sql, id, (error, results) => {
      if (error) {
        reject(error);
      } else {
        resolve(results.affectedRows);
      }
      connection.end();
    });
  });
}

exports.patch = (tableName, idField, id, entityWoId) => {
  return new Promise((resolve, reject) => {
    var sql = `update ${tableName} set ? where ${idField} = ?`;
    var connection = createConnection();
    connection.connect();
    connection.query(sql, [entityWoId, id], (error, results) => {
      if (error) {
        reject(error);
      } else {
        resolve(results.changedRows);
      }
      connection.end();
    });
  });
}