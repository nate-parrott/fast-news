import React from 'react';
import { Header } from './components.jsx';
require('./less/sourceList.less');


class SourceList extends React.Component {
	constructor(props) {
		super(props);
		this.state = {subscriptions: null};
	}
	render() {
		return (
			<div className='SourceList scrollable-with-header'>
				<Header title='Subscriptions' onBack={this.props.onBack}/>
				<div className='scrollable-content'>
					<SourceForm onAdd={this.addSource}/>
					<SubscriptionList subscriptions={this.state.subscriptions} />
				</div>
			</div>
		)
	}
}

class SourceForm extends React.Component {
	render() {
		return (
			<form className='SourceForm' onSubmit={this.submit}>
				<input type='text' placeholder='Site URL'/>
			</form>
		)
	}
}

class SubscriptionList extends React.Component {
	render() {
		return (
			<div className='SourceList'>nothing here</div>
		)
	}
}

module.exports.SourceList = SourceList;
