// ==UserScript==
// @name         Ad Block: Mobile Reddit
// @namespace    xarantolus
// @version      0.0.1
// @description  Removes sponsored posts and ads on Reddit
// @author       xarantolus
// @match        *://reddit.com/*
// @match        *://*.reddit.com/*
// @grant        none
// @run-at       document-end
// @homepage     https://userscripts.010.one
// @url_source   https://github.com/xarantolus/bromite-userscripts/releases/latest/download/reddit.user.js
// ==/UserScript==

var log = function (...data) {
  console.log("[Ad Block: Reddit]:", ...data);
};

var scriptFun = function () {
  // Source: http://ryanmorr.com/using-mutation-observers-to-watch-for-element-availability/
  (function (win) {
    "use strict";

    var listeners = [],
      doc = win.document,
      MutationObserver = win.MutationObserver || win.WebKitMutationObserver,
      observer;

    function ready(selector, fn) {
      // Store the selector and callback to be monitored
      listeners.push({
        selector: selector,
        fn: fn,
      });
      if (!observer) {
        // Watch for changes in the document
        observer = new MutationObserver(check);
        observer.observe(doc.documentElement, {
          childList: true,
          subtree: true,
        });
      }
      // Check if the element is currently in the DOM
      check();
    }

    function check() {
      // Check the DOM for elements matching a stored selector
      for (
        var i = 0, len = listeners.length, listener, elements;
        i < len;
        i++
      ) {
        listener = listeners[i];
        // Query for elements matching the specified selector
        elements = doc.querySelectorAll(listener.selector);
        for (var j = 0, jLen = elements.length, element; j < jLen; j++) {
          element = elements[j];
          // Make sure the callback isn't invoked with the
          // same element more than once
          if (!element.ready) {
            element.ready = true;
            // Invoke the callback with the element
            listener.fn.call(element, element);
          }
        }
      }
    }

    // Expose `ready`
    win.ready = ready;
  })(this);

  function removeWithReason(adType) {
    return function (element) {
      element.remove();
      log("Removed " + adType);
    };
  }

  // removeIfAd returns a function that gets an HTML element and removes it if it's an ad
  function removeAd(adType) {
    var remove = removeWithReason(adType);
    return function (element) {
		remove(element);
    };
  }

  ready("shreddit-ad-post", removeAd("feed ad"));
  ready("shreddit-comments-page-ad", removeAd("comments page ad"));
};

scriptFun()


// if (document.readyState == "complete") {
//   scriptFun();
//   log("Ran on completed document");
// } else {
//   window.addEventListener("load", scriptFun);
//   log("Registered as 'load' event listener");
// }
