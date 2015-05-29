function toggleCollapse(event) {
    var button = event.target.parentNode;
    var content = button.parentNode.nextSibling;
    var inner = content.children[0];

    if (button.className.indexOf('collapse-button') === -1) {
      // Clicked without hitting the right element?
      return;
    }

    if (content.style.maxHeight && content.style.maxHeight !== '0px') {
        // Currently showing, so let's hide it
        button.className = 'collapse-button';
        content.style.maxHeight = '0px';
    } else {
        // Currently hidden, so let's show it
        button.className = 'collapse-button show';
        content.style.maxHeight = inner.offsetHeight + 12 + 'px';
    }
}

function refresh(body) {
    document.querySelector('body').className = 'preload';
    document.body.innerHTML = body;

    // Re-initialize the page
    init();

    document.querySelector('body').className = '';
}

function init() {
    // Make collapse buttons clickable
    var buttons = document.querySelectorAll('.collapse-button');
    for (var i = 0; i < buttons.length; i++) {
        buttons[i].onclick = toggleCollapse;

        // Show by default? Then toggle now.
        if (buttons[i].className.indexOf('show') !== -1) {
            toggleCollapse({target: buttons[i].children[0]});
        }
    }
}

// Initial call to set up buttons
init();

window.onload = function () {
    // Remove the `preload` class to enable animations
    document.querySelector('body').className = '';
};
