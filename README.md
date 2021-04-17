# bbb-html5client-blur-background

Meteor client customization to support [BodyPix](https://github.com/tensorflow/tfjs-models/tree/master/body-pix) for blurred webcam background in [BigBlueButton](https://bigbluebutton.org/).

To apply the patch, just run

	./patcher.sh
	bbb-conf --restart

on your *BigBlueButton* instance -- this modifies the files

	/usr/share/meteor/bundle/programs/web.browser/head.html
	/usr/share/meteor/bundle/programs/web.browser/app/compatibility/kurento-utils.js

(backup copies of the files are stored in the corresponding directory with the suffix `.dist`)
and downloads and deploys the required libraries via `compatibility` subfolders -- no CDNs will be used.

If an update of *BigBlueButton* replaces these files, the patcher script must be run again.
However, it is safe to always run the patcher after updates (it will skip already patched files).


These scripts are based on the work of [drlight17](https://github.com/drlight17/bbb-html5client-blur-background).
