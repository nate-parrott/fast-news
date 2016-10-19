var uuid = require('node-uuid');
var xhr = require('xhr');

var getUID = function() {
	if (!localStorage.uid) {
		localStorage.uid = uuid.v4();
	}
	return localStorage.uid;
}

var USE_LOCAL = false;
var API_ROOT = USE_LOCAL ? 'http://localhost:8080' : 'http://a1.nateparrott.com';

var req = function(method, path, params, cb) {
	params = JSON.parse(JSON.stringify(params || {}))
	params.uid = getUID();
	var options = {
		url: API_ROOT + path + queryString(params),
		method: method
	};
	xhr(options, function(err, resp, body) {
		if (!err && resp.statusCode == 200) {
			cb(true, JSON.parse(body));
		} else {
			cb(false, err);
		}
	});
}

var queryString = function(obj) {
  return '?'+Object.keys(obj).reduce(function(a,k){a.push(k+'='+encodeURIComponent(obj[k]));return a},[]).join('&')
}

module.exports.req = req;

var feed = function(callback) {
	req('GET', '/feed', null, callback);
}
module.exports.feed = feed;

var article = function(id, callback) {
	req('GET', '/article', {id: id}, callback);
}
module.exports.article = article;

var source = function(id, callback) {
	req('GET', '/source', {id: id}, callback);
}
module.exports.source = source;
