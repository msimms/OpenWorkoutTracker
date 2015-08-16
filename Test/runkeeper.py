#
#  runkeeper.py
#
#  Created by Michael Simms on 2/24/14.
#  Copyright (c) 2014 Michael J. Simms. All rights reserved.
#

import json

def upload(type, notes, startTime, points):
	data = [ {
		"type":"running",
		"equipment":"none",
		"notes":notes,
		"post_to_facebook":True,
		"post_to_twitter":True } ]

	for point in points:
		pass
