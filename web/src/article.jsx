import React from 'react';
require('./less/article.less');
var api = require('./api.jsx');
import {parseURL} from './util.jsx';
import {ArticleContent} from './articleContent.jsx';

class Article extends React.Component {
	constructor(props) {
		super(props);
		this.state = {state: 'none'};
	}
	componentDidMount() {
		this.reload(this.props);
	}
	componentWillReceiveProps(nextProps) {
		this.reload(nextProps);
	}
	reload(props) {
		var self = this;
		self.setState({state: 'loading'});
		var id = decodeURIComponent(props.params.id);
		api.article(id, function(success, resp) {
			if (success) {
				document.title = resp.title;
				self.setState({state: 'loaded', article: resp});
			} else {
				self.setState({state: 'failed'});
			}
		})
	}
	render() {
		return <div className='Article'>{ this.renderInner() }</div>
	}
	renderInner() {
		if (this.state.state === 'loaded') {
			if (this.state.article.article_json && !this.state.article.article_json.is_low_quality_parse) {
				return <ArticleContent content={ this.state.article.article_json } />;
			} else {
				return <ArticleExternalLink article={ this.state.article } />;
			}
		}
	}
}

class ArticleExternalLink extends React.Component {
	render() {
		var siteName = this.props.article.site_name || parseURL(this.props.article.url).host;
		return (
			<div className='ArticleExternalLink'>
				<a href={this.props.article.url} target='_blank'>{siteName} <img src='/static/outbound.svg'/></a>
			</div>
		)
	}
}

module.exports.Article = Article;
