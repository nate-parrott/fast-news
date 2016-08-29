require('./cloud-login.js');
require('./less/index.less');

import React from 'react';
import {render} from 'react-dom';
var api = require('./api.jsx');

import { Router, Route, Link, hashHistory } from 'react-router';

class Feed extends React.Component {
  render () {
	  if (!this.props.children) {
	  	return <div>Feed!</div>
	  } else {
		  return <div>{this.props.children}</div>
	  }
  }
}

class Article extends React.Component {
	render() {
		return <p>article {this.props.params.id}</p>
	}
}

class Source extends React.Component {
	render() {
		return <p>source {this.props.params.id}</p>
	}
}

render((
	<Router history={hashHistory}>
		<Route path="/" component={Feed}>
			<Route path="articles/:id" component={Article}/>
			<Route path="sources/:id" component={Source}/>
		</Route>
	</Router>
), document.getElementById('app'));

api.req('GET', 'feed', {}, function(success, body) {
	console.log(body)
})
