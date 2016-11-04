import React from 'react';
var api = require('./api.jsx');
require('./less/feedList.less');
import { Image } from './image.jsx';
import { Chevron, Header } from './components.jsx';
import { Link, browserHistory } from 'react-router';

class SourceDetail extends React.Component {
	constructor(props) {
		super(props);
		this.state = {state: 'none', articles: []};
	}
	componentWillReceiveProps(nextProps) {
		if (nextProps.source.id !== this.props.source.id) {
			this.loadWithSource(nextProps.source);
		}
	}
	componentDidMount() {
		this.loadWithSource(this.props.source);
	}
	loadWithSource(source) {
		var self = this;
		self.setState({state: 'loading', articles: source.articles || []})
		api.source(source.id, function(success, source) {
			if (success) {
				self.setState({state: 'loaded', articles: source.articles || []})
			} else {
				self.setState({state: 'failed'});
			}
		})
	}
	render() {
		return (
			<div className='SourceDetail scrollable-with-header'>
				<Header title={this.props.source.title} onBack={this.props.onBack} />
				<div className='articles scrollable-content'>{ this.state.articles.map( (article, i) => <ArticleCell key={i} article={article} /> ) }</div>
			</div>
		)
	}
}

class FeedList extends React.Component {
	constructor(props) {
		super(props);
		this.state = {feed: null, state: 'none'};
	}
	componentDidMount() {
		this.reload()
	}
	reload() {
		var self = this;
		self.setState({state: 'loading'});
		api.feed(function(success, feed) {
			self.setState({state: success ? 'loaded' : 'failed', feed: feed});
		})
	}
	render() {
		return (
			<div className='FeedList scrollable-with-header'>
				<Header title="A1 News" rightButton={{title: 'Subscriptions', onClick: this.props.onShowSources}}/> 
				<div className='feedItems scrollable-content'>{ this.renderInner() }</div>
			</div>
		)
	}
	renderInner() {
		var onClickedSource = this.props.onClickedSource;
		if (this.state.state === 'loading') {
			// return <div className='loading'>Loading...</div>
			return null;
		} else if (this.state.state === 'failed') {
			return <div className='error'>Error</div>
		} else if (this.state.state == 'loaded') {
			return this.state.feed.sources.map( (source) => <FeedCell source={source} key={source.id} onClickedSource={onClickedSource} /> )
		}
	}
}

class FeedCell extends React.Component {
	render() {
		var title = this.props.source.short_title || this.props.source.title;
		return (
		<div className='FeedCell'>
			<div className='sourceName' onClick={this.clickedSource.bind(this)}>{ title } <Chevron/></div>
			{ this.renderArticle() }
		</div>
		)
	}
	renderArticle() {
		var a = this.articleToRender();
		return a ? <ArticleCell article={a} /> : null;
	}
	articleToRender() {
		var articles = this.props.source.articles;
		for (var i=0; i<articles.length; i++) {
			if (articles[i].fetch_failed === false) {
				return articles[i];
			}
		}
		if (articles.length > 0) {
			return articles[0];
		}
		return null;
	}
	clickedSource() {
		this.props.onClickedSource(this.props.source);
	}
}

class ArticleCell extends React.Component {
	render() {
		var link = '/articles/' + encodeURIComponent(this.props.article.id);
		return (
		<Link to={link} className='ArticleCell' key={this.props.article.id}>
			<div>
				<h4>{ this.props.article.title }</h4>
				<p>{ this.props.article.description }</p>
			</div>
			<div>{ this.renderImage() }</div>
		</Link>
		)
	}
	renderImage() {
		return this.props.article.top_image ? <Image src={this.props.article.top_image} /> : null;
	}
}

module.exports.SourceDetail = SourceDetail;
module.exports.FeedList = FeedList;
