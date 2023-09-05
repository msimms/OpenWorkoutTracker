//
//  Downloader.swift
//  Created by Michael Simms on 8/23/23.
//

import Foundation

class Downloader {
	
	func download(source: URL, destination: URL, completion: @escaping (Error?) -> Void) {
		let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
		var request = URLRequest(url: source)
		request.httpMethod = "GET"

		let task = session.dataTask(with: request, completionHandler: { data, response, error in
			if error == nil {
				if let response = response as? HTTPURLResponse {
					if response.statusCode == 200 {
						if let data = data {
							if let _ = try? data.write(to: destination, options: Data.WritingOptions.atomic) {
								completion(error)
							}
							else {
								completion(error)
							}
						}
						else {
							completion(error)
						}
					}
				}
			}
			else {
				completion(error)
			}
		})
		task.resume()
	}
}
