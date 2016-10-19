import React from 'react';
require('./less/components.less');

class Chevron extends React.Component {
	render() {
		var cls = 'Chevron';
		if (this.props.reversed) cls += ' reversed';
		return <div className={cls}></div>
	}
}

module.exports.Chevron = Chevron;
