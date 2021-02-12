// Created by Michael Simms on 2/12/21.
// Copyright (c) 2021 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "ImageUtils.h"

@implementation ImageUtils

+ (UIImage*)invertImage:(UIImage*)img
{
	CIFilter* filter = [CIFilter filterWithName:@"CIColorInvert"];
	[filter setDefaults];
	[filter setValue:img.CIImage forKey:@"inputImage"];
	return [[UIImage alloc] initWithCIImage:filter.outputImage];
}

+ (UIImage*)invertImage2:(UIImage*)img
{
	CGFloat width = img.size.width;
	CGFloat height = img.size.height;

	CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceRGB();
	uint8_t* memoryPool = (uint8_t*)calloc(width * height * 4, 1);
	CGContextRef context = CGBitmapContextCreate(memoryPool, width, height, 8, width * 4, colourSpace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast);
	CGColorSpaceRelease(colourSpace);
	CGContextDrawImage(context, CGRectMake(0, 0, width, height), [img CGImage]);

	for (int y = 0; y < height; y++)
	{
		unsigned char* linePointer = &memoryPool[(size_t)(y * width * 4)];

		for (int x = 0; x < width; x++)
		{
			int r, g, b;

			if (linePointer[3])
			{
				r = linePointer[0] * 255 / linePointer[3];
				g = linePointer[1] * 255 / linePointer[3];
				b = linePointer[2] * 255 / linePointer[3];
			}
			else
			{
				r = g = b = 0;
			}

			// perform the colour inversion
			r = 255 - r;
			g = 255 - g;
			b = 255 - b;

			if ((r+g+b) / (3*255) == 0)
			{
				linePointer[0] = linePointer[1] = linePointer[2] = 0;
				linePointer[3] = 0;
			}
			else
			{
				linePointer[0] = r * linePointer[3] / 255;
				linePointer[1] = g * linePointer[3] / 255;
				linePointer[2] = b * linePointer[3] / 255;
			}
			linePointer += 4;
		}
	}

	CGImageRef cgImage = CGBitmapContextCreateImage(context);
	UIImage* outputImage = [UIImage imageWithCGImage:cgImage];

	CGImageRelease(cgImage);
	CGContextRelease(context);
	free(memoryPool);

	return outputImage;
}

@end
