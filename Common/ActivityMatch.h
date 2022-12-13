//
//  ActivityMatch.h
//  Created by Michael Simms on 12/7/22.
//

#pragma once

// Activity match codes used for sync.
typedef enum ActivityMatch {
	ACTIVITY_MATCH_CODE_NO_ACTIVITY = 0, // Activity does not exist
	ACTIVITY_MATCH_CODE_HASH_NOT_COMPUTED = 1, // Activity exists, hash not computed
	ACTIVITY_MATCH_CODE_HASH_DOES_NOT_MATCH = 2, // Activity exists, has does not match
	ACTIVITY_MATCH_CODE_HASH_MATCHES = 3, // Activity exists, hash matches as well
	ACTIVITY_MATCH_CODE_HASH_NOT_PROVIDED = 4 // Activity exists, hash not provided
} ActivityMatch;
