require('./cloud-login.js');
require('./less/index.less');

import React from 'react';
import {render} from 'react-dom';
var api = require('./api.jsx');

import { Router, Route, Link, hashHistory } from 'react-router';
import { Article } from './article.jsx';
import { FeedList, SourceDetail } from './feedList.jsx';
import { SourceList } from './sourceList.jsx';

class Main extends React.Component {
	constructor(props) {
		super(props);
		this.state = {source: null};
	}
	render() {
		return (
			<div className='Main'>
				<div className='sidebar'>{ this.renderSidebar() }</div>
				<div className='content'>{ this.props.children }</div>
			</div>
		)
	}
	renderSidebar() {
		var self = this;
		if (this.state.showSources) {
			return <SourceList onBack={ () => self.showFeed(true) } />;
		} else if (this.state.source) {
			return <SourceDetail source={this.state.source} onBack={ () => self.showFeed(false) } />
		} else {
			return <FeedList onClickedSource={ (source) => self.setState({source: source}) } onShowSources={ () => self.setState({showSources: true}) } />
		}
	}
	showFeed(refresh) {
		// TODO: refresh
		this.setState({ showSources: false, source: null })
	}
}


render((
	<Router history={hashHistory}>
		<Route path="/" component={Main}>
			<Route path="articles/:id" component={Article}/>
		</Route>
	</Router>
), document.getElementById('app'));

