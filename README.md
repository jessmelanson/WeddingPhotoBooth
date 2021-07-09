# iOS Photo Booth

This repository is an upgraded version of [Ben D. Jones'](https://github.com/bendjones) [WeddingPhotoBooth](https://github.com/bendjones/WeddingPhotoBooth) that now compiles in Swift 5, builds in XCode 12.5, and runs on iOS 14.4+ on iPad in landscape mode. Ben previously released this under an MIT license, and I hope whoever comes along and needs a DIY photobooth for their COVID-postponed wedding (like me) can use it with ease.

To personalize this for your wedding:

1. Change the image in Assets.xcassets named "BrandImage" to whatever you want to be in the bottom right corner of the photo strip. This should be a 300x400 image. I recommend using [Pixlr](https://pixlr.com) to make yourself something simple and custom.
2. In Main.storyboard, change the title label to your and your future spouse's names.
3. Change the email and text subject in ViewController.swift:408 in `getShareSubject` to something relevant to your wedding.
4. I removed the print functionality, but to add it back in, you can uncomment ViewController.swift:201. The print modal is working for me on this version, but I haven't actually printed anything with it so you'll want to test it out for yourself first.

The app icon, launch screen image, and landing screen background image are by [NeoONBRAND on Unsplash](https://unsplash.com/photos/aMr23XVkWos) and used under the [Unsplash License](https://unsplash.com/license).
