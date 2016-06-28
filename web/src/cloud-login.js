window.addEventListener('cloudkitloaded', function() {
    CloudKit.configure({
        containers: [{
            containerIdentifier: 'iCloud.com.nateparrott.Subscribed',
            apiToken: '0d283356d56f7ed3b58080413b39c519c66268eccff0b127aad4c8828b044d8e',
            environment: 'development',
			persist: true,
			signInButton: {
			        id: 'apple-sign-in-button',
			        theme: 'black' // Other options: 'white', 'white-with-outline'.
			}
        }]
    });
	var container = CloudKit.getDefaultContainer();
	var publicDB = container.publicCloudDatabase;
	
});
