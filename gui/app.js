var express = require('express');
var explorer = require('./routes/explorer');
var manage = require('./routes/manage');
var fs = require('fs');
var path = require('path');
var bodyParser = require('body-parser')
var app = express();
var server = require('http').createServer(app);


//config
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');
app.use( bodyParser.json() );       // to support JSON-encoded bodies
app.use(bodyParser.urlencoded({     // to support URL-encoded bodies
  extended: true
})); 

app.use("/public", express.static(__dirname + '/public'));
app.use('/', explorer);
app.use('/manage', manage)

server.listen(3000,function(){
	console.log('Server started at http://localhost:3000');
});