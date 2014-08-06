#!/usr/bin/env node

require('../lib/bin').run(null, function(err){
	if(err){
		process.exit(1);
	}
});
