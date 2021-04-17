#!/bin/bash

# based on https://github.com/drlight17/bbb-html5client-blur-background

NAME="BBB BACKGROUND BLUR PATCH 1.0"

BASE="/usr/share/meteor/bundle/programs/web.browser"
BASEJS="${BASE}/app/compatibility"
KURENTO_UTILS="${BASEJS}/kurento-utils.js"
HEAD_HTML="${BASE}/head.html"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

BACKUP=".dist"

insert_at() {
	if [[ $# > 5 ]] ; then
		MARKER_START="$5"
		MARKER_END="$6"
	else
		MARKER_START="/**"
		MARKER_END="**/"
	fi

	sed -i "/^\s*$3\s*$/$1 ${MARKER_START} BEGIN ${NAME} ${MARKER_END}${4//$'\n'/\\n}${MARKER_START} END ${NAME} ${MARKER_END}" "$2"
}

insert_before() {
	insert_at "i" "$@" 
}

insert_after() {
	insert_at "a" "$@"
}

cd $DIR
if ! grep "$NAME" "$HEAD_HTML" >/dev/null ; then
	echo "Fetching dependencies for $NAME..."
	npm run dist
	cp -r dist/* ${BASEJS}/

	echo "Applying $NAME at $HEAD_HTML..."
	cp "$HEAD_HTML" "$HEAD_HTML$BACKUP"

insert_before "$HEAD_HTML" '<\/style>' '
    #hidden_video_element {
      position: fixed;
      top: 0;
      left:0;
      width: 50%;
      z-index: 999999;
      display: none;
    }
    #hidden_canvas_element {
      position: fixed;
      top: 0;
      left:0;
      width: 50%;
      z-index: 999999;
      display: none;
    }
    .tippy-box {
      font-size: 12px!important;
    }
'

insert_after "$HEAD_HTML" '<\/script>' '
  <script src="compatibility/@tensorflow/tfjs/tf.min.js"></script>
  <script src="compatibility/@tensorflow-models/body-pix/body-pix.min.js"></script>
  <script src="compatibility/jquery/jquery.min.js"></script>
  <script src="compatibility/@popperjs/core/umd/popper.min.js"></script>
  <script src="compatibility/tippy.js/tippy-bundle.umd.min.js"></script>
  <link href="compatibility/tippy.js/animations/shift-away.css" rel="stylesheet"/>
' '<!--' '-->'

	diff -u "$HEAD_HTML$BACKUP" "$HEAD_HTML"
fi

if ! grep "$NAME" "$KURENTO_UTILS" >/dev/null ; then
	echo "Applying $NAME at $KURENTO_UTILS..."
	cp "$KURENTO_UTILS" "$KURENTO_UTILS$BACKUP"


insert_after "$KURENTO_UTILS" 'var logger = window.Logger || console;' '
var blur_button_tippy = "";
'

insert_before "$KURENTO_UTILS" 'function WebRtcPeer(mode, options, callback) {' '
function _waitForElement(selector, delay = 50, tries = 10000) {
    const element = document.querySelector(selector);
    if (!window[`__${selector}`]) {
        window[`__${selector}`] = 0;
    }
    function _search() {
        return new Promise((resolve) => {
            window[`__${selector}`]++;
            setTimeout(resolve, delay);
        });
    }
    if (element === null) {
        if (window[`__${selector}`] >= tries) {
            window[`__${selector}`] = 0;
            return Promise.reject(null);
        }
        return _search().then(() => _waitForElement(selector));
    } else {
        return Promise.resolve(element);
    }
}
const start = (async () => {
    const $el = await _waitForElement(".icon-bbb-video_off");
    var video_state_off = $(".icon-bbb-video_off");
    if ((document.getElementById("blur_button") == null) && (video_state_off.get(0)!=null)) {
        var share_webcam_button = $("[class^=actionsbar-]").children().eq(2).children().eq(1);
        var blur_button = share_webcam_button.clone(false);
        blur_button.attr("id", "blur_button");
        blur_button.insertAfter(share_webcam_button);
        blur_button_tippy = tippy(blur_button.get(0), {
                    animation: "shift-away",
                    content(reference) {
                        const title = reference.getAttribute("aria-label");
                        return title;
                    },
                    arrow: false
        });        
        blur_turn_off(blur_button_tippy);
    }
})();
function blur_turn_on(blur_button_tippy) {
    var  blur_button = $("#blur_button");
    var blur_button_icon = blur_button.find("i");
    blur_button.attr("aria-label", "Unblur webcam background");
    blur_button_icon.addClass("icon-bbb-user").removeClass("icon-bbb-clear_status");
    blur_button.find(">:first-child").removeClass("default--Z19H5du").removeClass("ghost--Z136aiN").addClass("primary--1IbqAO");
    blur_button.removeClass("btn--29prju").removeClass("blur").addClass("unblur");
    if (blur_button_tippy !== undefined) {
        blur_button_tippy.setProps({
            content(reference) {
                        const title = reference.getAttribute("aria-label");
                        return title;
            }
        });
    }
    blur_button.off();
    blur_button.on( "click", function () {
            blur_turn_off(blur_button_tippy);
    });
}
function blur_turn_off(blur_button_tippy) {
    var blur_button = $("#blur_button");
    var blur_button_icon = blur_button.find("i");
    blur_button.attr("aria-label", "Blur webcam background");
    blur_button_icon.removeClass( "icon-bbb-video_off" ).addClass("icon-bbb-clear_status").removeClass("icon-bbb-user");
    blur_button.find(">:first-child").addClass("default--Z19H5du").addClass("ghost--Z136aiN").removeClass("primary--1IbqAO");
    blur_button.addClass("btn--29prju").removeClass("unblur").addClass("blur");
    if (blur_button_tippy !== undefined) {
        blur_button_tippy.setProps({
            content(reference) {
                        const title = reference.getAttribute("aria-label");
                        return title;
            }
        });
    }
    blur_button.off();
    blur_button.on( "click", function () {
            blur_turn_on(blur_button_tippy);
    });
    return blur_button;
}
'

insert_before "$KURENTO_UTILS" 'Object.defineProperties(this, {' '
    var is_mobile;
    var videoElement = document.createElement("video");
    videoElement.id = "hidden_video_element";
    var canvasElement = document.createElement("canvas");
    canvasElement.id = "hidden_canvas_element";
    var ctx = canvasElement.getContext("2d");
    var canvasStream = canvasElement.captureStream(30);
    // check mobile device
    if(/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)) {is_mobile = true} else {is_mobile = false};
'

insert_before "$KURENTO_UTILS" 'function start() {' '
    function loadBodyPix(videoElement) {
        if (is_mobile === true) {
            multiplier = 0.50;
        } else {
            multiplier = 1;
        }
        options = {
            architecture: "MobileNetV1", // MobileNetV1 -faster less accurate, ResNet50 - slower more accurate
            multiplier: multiplier, // 1, 0.75, 0.50 smaller - lower accuracy
            outputStride: 16, // Stride 16, 32 are supported for the ResNet architecture and stride 8, and 16 are supported for the MobileNetV1 architecture). It specifies the output stride of the BodyPix model. The smaller the value, the larger the output resolution, and more accurate the model at the cost of speed. A larger value results in a smaller model and faster prediction time but lower accuracy.
            quantBytes: 4 //1, 2, 4 smaller - lower accuracy
        }
        bodyPix.load(options)
            .then(net => perform(net,videoElement))
            .catch(err => console.log(err))
    }
    async function perform(net,videoElement) {
        while (videoElement) {
            // TODO The video element has not loaded data yet. Please wait for `loadeddata` event on the <video> element
            const backgroundBlurAmount = 10; // Defaults to 3. Should be an integer between 1 and 20.
            const edgeBlurAmount = 5; //Defaults to 3. Should be an integer between 0 and 20.
            const flipHorizontal = false; // If the output should be flipped horizontally. Defaults to false.
            const internalResolution = "medium"; // high, low, medium, full
            const segmentationThreshold = 0.7; // 0...1 a higher value will create a tighter crop around a person but may result in some pixels being that are part of a person being excluded from the returned segmentation mask.
            options = {
                flipHorizontal: flipHorizontal,
                internalResolution: internalResolution,
                segmentationThreshold: segmentationThreshold
            };
            segmentation = await net.segmentPerson(videoElement, options);
            bodyPix.drawBokehEffect(canvasElement, videoElement, segmentation, backgroundBlurAmount, edgeBlurAmount, flipHorizontal);
        }
    }
    videoElement.onplaying = () => {
        function gcd (a, b) {
            return (b == 0) ? a : gcd (b, a%b);
        };
        var divider = gcd (videoElement.videoWidth,videoElement.videoHeight);
        var width_aspect = videoElement.videoWidth/divider;
        var height_aspect = videoElement.videoHeight/divider;
        videoElement.width = "480";
        videoElement.height = videoElement.width/width_aspect*height_aspect;
        canvasElement.width = videoElement.width;
        canvasElement.height = videoElement.height;
    };
'

insert_after "$KURENTO_UTILS" 'navigator.mediaDevices.getUserMedia(constraints).then(function (stream) {' '
                videoStream = stream;
                videoElement.srcObject = videoStream;
                videoElement.play();
                // check if blur button enabled
                if ($(".blur").get(0) === undefined) {
                    loadBodyPix(videoElement);
                    videoStream = canvasStream;
                }
                start();
                const wait_video_on = (async () => {
                    const $el = await _waitForElement(".icon-bbb-video");
                    var blur_button = $("#blur_button");
                    blur_button.attr("disabled", true).off();
                    blur_button.attr("aria-disabled", true);
                })();
                return;
'

insert_after "$KURENTO_UTILS" "this.on('_dispose', function () {" '
        // wait for video turned off button
        const wait_video_off = (async () => {
            const $el = await _waitForElement(".icon-bbb-video_off");
            var blur_button = $("#blur_button");
            if ($(".blur").get(0) === undefined)  {
                blur_turn_on(blur_button_tippy);
            } else {
                blur_turn_off(blur_button_tippy);
            };
            blur_button.attr("disabled", false).on();
            blur_button.attr("aria-disabled", false);    
        })();
'

	diff -u "$KURENTO_UTILS$BACKUP" "$KURENTO_UTILS"
fi
