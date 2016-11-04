import React from 'react';
require('./less/components.less');

class Chevron extends React.Component {
	render() {
		var cls = 'Chevron';
		if (this.props.reversed) cls += ' reversed';
		return <div className={cls}></div>
	}
}

class Header extends React.Component {
	render() {
		var left = null;
		if (this.props.onBack) {
			var backContent = <div className='back left' onClick={this.props.onBack}><Chevron reversed={true} /> Back</div>
			left = <div className='clickable' onClick={this.props.onBack}>{backContent}</div>;
		}
		var right = null;
		if (this.props.rightButton){
			right = <div className='clickable right' onClick={this.props.rightButton.onClick}>{this.props.rightButton.title}</div>;
		}
		return <div className='ListHeader'>{left} {this.props.title} {right}</div>;
	}
}

module.exports.Header = Header;
module.exports.Chevron = Chevron;
