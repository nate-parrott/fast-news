import React from 'react';
require('./less/article.less');
import {Image} from './image.jsx';

class ArticleContent extends React.Component {
	render() {
		return <div className='ArticleContent'>{this.props.content.segments.map(this.renderSegment)}</div>
	}
	renderSegment(seg, i) {
		if (seg.type === 'text') {
			return <TextSegment seg={seg} key={i} />;
		} else if (seg.type === 'image') {
			return <ImageSegment seg={seg} key={i} />;
		} else {
			console.log("Unknown segment type:", seg.type);
			return null;
		}
	}
}

class TextSegment extends React.Component {
	render() {
		var ComponentName = {
			title: 'h1',
			h1: 'h1',
			h2: 'h2',
			h3: 'h3',
			h4: 'h4',
			h5: 'h5',
			h6: 'h6',
			p: 'p',
			caption: 'figcaption',
			figcaption: 'figcaption',
			li: 'li',
			blockquote: 'blockquote',
			meta: 'p'
		}[this.props.seg.kind] || 'p';
		var classes = ["TextSegment"];
		if (this.props.seg.kind === 'meta') { classes.push('meta') }
		var style = {};
		if (this.props.seg.left_padding) { style.paddingLeft = this.props.seg.left_padding + 'em' }
		return <ComponentName style={style} className={classes.join(' ')}><TextRun content={this.props.seg.content} /></ComponentName>;
	}
}

class TextRun extends React.Component {
	render() {
		var attrs = this.props.content[0];
		var items = this.props.content.slice(1);
		var rendered = items.map(this.renderItem);
		if (attrs.link) { rendered = <a href={attrs.link} target='_blank'>{rendered}</a> }
		if (attrs.bold) { rendered = <strong>{rendered}</strong> }
		if (attrs.italic) { rendered = <em>{rendered}</em> }
		if (attrs.monospace) { rendered = <code>{rendered}</code> }
		if (Array.isArray(rendered)) { rendered = <span>{rendered}</span> }
		return rendered;
	}
	renderItem(item, i) {
		// either a string or a child array representing a TextRun
		if (Array.isArray(item)) {
			return <TextRun key={i} content={item} />;
		} else {
			// assume item is text
			return <span key={i}>{item}</span>;
		}
	}
}

class ImageSegment extends React.Component {
	render() {
		var aspect = 1.7;
		if (this.props.seg.tiny && this.props.seg.tiny.real_size) {
			aspect = this.props.seg.tiny.real_size[0] / this.props.seg.tiny.real_size[1];
		}
		aspect = Math.max(1.7, aspect);
		return <div className='ImageSegment'><Image aspect={aspect} src={this.props.seg.src}/></div>;
	}
}

module.exports.ArticleContent = ArticleContent;
