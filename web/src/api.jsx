var uuid = require('node-uuid');
var xhr = require('xhr');

var getUID = function() {
	if (!localStorage.uid) {
		localStorage.uid = uuid.v4();
	}
	return localStorage.uid;
}

var req = function(method, path, params, cb) {
	params = JSON.parse(JSON.stringify(params || {}))
	params.uid = getUID();
	var options = {
		url: 'https://fast-news.appspot.com/' + path + queryString(params),
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
