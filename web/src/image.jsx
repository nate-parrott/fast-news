import React from 'react';

class Image extends React.Component {
	render() {
		var style = {backgroundColor: '#ddd'};
		style.backgroundImage = 'url(' + this.props.src + ')';
		style.backgroundSize = 'cover';
		if (this.props.aspect) {
			style.paddingBottom = Math.round(100 / this.props.aspect) + '%';
		}
		return <div className='Image' style={style}></div>
	}
}

module.exports.Image = Image;
