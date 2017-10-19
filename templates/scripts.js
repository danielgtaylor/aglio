/* eslint-env browser */
/* eslint quotes: [2, "single"] */
'use strict';

/*
  Determine if a string starts with another string.
*/
function startsWith(str, prefix) {
    return str.indexOf(prefix) === 0;
}

/*
  Determine if a string ends with another string.
*/
function endsWith(str, suffix) {
    return str.indexOf(suffix, str.length - suffix.length) !== -1;
}

/*
  Get a list of direct child elements by class name.
*/
function childrenByClass(element, name) {
  var filtered = [];

  for (var i = 0; i < element.children.length; i++) {
    var child = element.children[i];
    var classNames = child.className.split(' ');
    if (classNames.indexOf(name) !== -1) {
      filtered.push(child);
    }
  }

  return filtered;
}

/*
  Get an array [width, height] of the window.
*/
function getWindowDimensions() {
  var w = window,
      d = document,
      e = d.documentElement,
      g = d.body,
      x = w.innerWidth || e.clientWidth || g.clientWidth,
      y = w.innerHeight || e.clientHeight || g.clientHeight;

  return [x, y];
}

/*
  Collapse or show a request/response example.
*/
function toggleCollapseButton(event) {
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

function toggleTabButton(event) {
    var i, index;
    var button = event.target;

    // Get index of the current button.
    var buttons = childrenByClass(button.parentNode, 'tab-button');
    for (i = 0; i < buttons.length; i++) {
        if (buttons[i] === button) {
            index = i;
            button.className = 'tab-button active';
        } else {
            buttons[i].className = 'tab-button';
        }
    }

    // Hide other tabs and show this one.
    var tabs = childrenByClass(button.parentNode.parentNode, 'tab');
    for (i = 0; i < tabs.length; i++) {
        if (i === index) {
            tabs[i].style.display = 'block';
        } else {
            tabs[i].style.display = 'none';
        }
    }
}

/*
  Collapse or show a navigation menu. It will not be hidden unless it
  is currently selected or `force` has been passed.
*/
function toggleCollapseNav(event, force) {
    var heading = event.target.parentNode;
    var content = heading.nextSibling;
    var inner = content.children[0];

    if (heading.className.indexOf('heading') === -1) {
      // Clicked without hitting the right element?
      return;
    }

    if (content.style.maxHeight && content.style.maxHeight !== '0px') {
      // Currently showing, so let's hide it, but only if this nav item
      // is already selected. This prevents newly selected items from
      // collapsing in an annoying fashion.
      if (force || window.location.hash && endsWith(event.target.href, window.location.hash)) {
        content.style.maxHeight = '0px';
      }
    } else {
      // Currently hidden, so let's show it
      content.style.maxHeight = inner.offsetHeight + 12 + 'px';
    }
}

/*
  Get a value for the given field and operator.
*/
function createFieldValue(field, operator, explosive) {
    if (operator === '*') {
        explosive = true;
        operator = false;
    }
    var fieldValue, values, i;
    if (explosive) {
        fieldValue = '';
        if (field.tagName.toLowerCase() === 'select' && field.options) {
            values = [];
            for (i = 0; i < field.options.length; i++) {
                var option = field.options[i];
                if (option.selected) {
                    values.push(option.value || option.text);
                }
            }
        } else {
            values = field.value.split(/\s*,\s*/g);
        }
        for (i = 0; i < values.length; i++) {
            fieldValue += createFieldValue({name: field.name, value: values[i]}, operator);
            if (operator === '?') {
                operator = '&';
            }
        }
        return fieldValue;
    }

    fieldValue = encodeURIComponent(field.value);
    if (operator && (fieldValue || field.required)) {
        if (operator === '?' || operator === '&') {
            fieldValue = operator + field.name + '=' + fieldValue;
        } else if (operator === '#') {
            fieldValue = '#' + fieldValue;
        } else if (operator === '+') {
            fieldValue = field.value;
        }
    }
    return fieldValue;
}

/*
  Send a sandbox request to the server.
*/
function sendSandboxRequest(event) {
    var i, body, regex, regexResult, fieldValue;
    var button = event.target;
    var fields = button.form.elements;
    var method = fields.__method.value;
    var uri = fields.__uri.value;
    var headerPrefix = '__' + fields.__request.value + '-header_';
    var headers = [];
    var xhr = new XMLHttpRequest();
    xhr.withCredentials = true;

    if (uri.indexOf('://') === -1 && window.location.hostname) {
        if (uri.charAt(0) !== '/') {
            uri = '/' + uri;
        }
        if (window.location.port) {
            uri = window.location.protocol + '//' + window.location.hostname + ':' + window.location.port + uri;
        } else {
            uri = window.location.protocol + '//' + window.location.hostname + uri;
        }
    }

    if (fields.__body) {
        body = fields.__body.value;
    }

    for (i = 0; i < fields.length; i++) {
        if (startsWith(fields[i].name, '__')) {
            if (startsWith(fields[i].name, headerPrefix)) {
                headers.push({
                    name: fields[i].name.substring(headerPrefix.length),
                    value: fields[i].value
                });
            }
        } else {
            regex = new RegExp('\\{([#\\+\\?&]?)' + fields[i].name + '(\\*?)\\}');
            regexResult = regex.exec(uri);
            if (!regexResult) {
                continue;
            }
            var operator = regexResult[1];
            if (operator === '&' && uri.indexOf('?') === -1) {
                operator = '?';
            }
            fieldValue = createFieldValue(fields[i], operator, regexResult[2]);
            uri = uri.substring(0, regexResult.index) + fieldValue + uri.substring(regexResult.index + regexResult[0].length);
        }
    }
    button.form.querySelector('.response-request-uri').textContent = uri;

    xhr.onload = handleSandboxResponse.bind(null, xhr, button);
    xhr.onerror = xhr.onload;
    xhr.open(method, uri);
    for (i = 0; i < headers.length; i++) {
        xhr.setRequestHeader(headers[i].name, headers[i].value);
    }
    if (!window.__jwt && storageAvailable('sessionStorage')) {
      window.__jwt = sessionStorage.getItem('__jwt');
    }
    if (window.__jwt) {
      xhr.setRequestHeader('Authorization', 'Bearer ' + window.__jwt);
    }

    button.querySelector('.spinner').style.display = 'inline-block';
    xhr.send(body);
}

/*
  Handle a sandbox response from the server, showing its output.
*/
function handleSandboxResponse(xhr, button) {
    var content = button.form.querySelector('.response.collapse-content');
    var inner = content.children[0];
    var responseBody = button.form.querySelector('.response-body');
    var responseHeaders = button.form.querySelector('.response-headers');

    button.querySelector('.spinner').style.display = 'none';
    button.form.querySelector('.response.title').style.display = 'block';
    content.style.display = 'block';

    try {
        responseBody.textContent = JSON.stringify(JSON.parse(xhr.responseText), null, 2);
    } catch (e) {
        responseBody.textContent = xhr.responseText;
    }
    responseHeaders.textContent = xhr.getAllResponseHeaders();
    window.__jwt = xhr.getResponseHeader('X-Set-JWT') || window.__jwt;
    if (window.__jwt && storageAvailable('sessionStorage')) {
      sessionStorage.setItem('__jwt', window.__jwt);
    }

    content.style.maxHeight = inner.offsetHeight + 12 + 'px';
}

/*
  Detect whether web storage is available.
*/
function storageAvailable(type) {
  try {
    var storage = window[type],
      x = '__storage_test__';
    storage.setItem(x, x);
    storage.removeItem(x);
    return true;
  }
  catch(e) {
    return false;
  }
}

/*
  Fill a field with the content of a text element.
*/
function fillField(fieldName, event) {
    var element = event.target;
    while (element && !element.dataset.fillTarget) {
        element = element.parentNode;
    }
    var field = document.getElementById(fieldName);
    if (field && element) {
        field.value = element.textContent;
    }
}

/*
  Refresh the page after a live update from the server. This only
  works in live preview mode (using the `--server` parameter).
*/
function refresh(body) {
    document.querySelector('body').className = 'preload';
    document.body.innerHTML = body;

    // Re-initialize the page
    init();
    autoCollapse();

    document.querySelector('body').className = '';
}

/*
  Determine which navigation items should be auto-collapsed to show as many
  as possible on the screen, based on the current window height. This also
  collapses them.
*/
function autoCollapse() {
  var windowHeight = getWindowDimensions()[1];
  var itemsHeight = 64; /* Account for some padding */
  var itemsArray = Array.prototype.slice.call(
    document.querySelectorAll('nav .resource-group .heading'));

  // Get the total height of the navigation items
  itemsArray.forEach(function (item) {
    itemsHeight += item.parentNode.offsetHeight;
  });

  // Should we auto-collapse any nav items? Try to find the smallest item
  // that can be collapsed to show all items on the screen. If not possible,
  // then collapse the largest item and do it again. First, sort the items
  // by height from smallest to largest.
  var sortedItems = itemsArray.sort(function (a, b) {
    return a.parentNode.offsetHeight - b.parentNode.offsetHeight;
  });

  while (sortedItems.length && itemsHeight > windowHeight) {
    for (var i = 0; i < sortedItems.length; i++) {
      // Will collapsing this item help?
      var itemHeight = sortedItems[i].nextSibling.offsetHeight;
      if ((itemsHeight - itemHeight <= windowHeight) || i === sortedItems.length - 1) {
        // It will, so let's collapse it, remove its content height from
        // our total and then remove it from our list of candidates
        // that can be collapsed.
        itemsHeight -= itemHeight;
        toggleCollapseNav({target: sortedItems[i].children[0]}, true);
        sortedItems.splice(i, 1);
        break;
      }
    }
  }
}

/*
  Initialize the interactive functionality of the page.
*/
function init() {
    var i, j;

    // Make collapse buttons clickable
    var buttons = document.querySelectorAll('.collapse-button');
    for (i = 0; i < buttons.length; i++) {
        buttons[i].onclick = toggleCollapseButton;

        // Show by default? Then toggle now.
        if (buttons[i].className.indexOf('show') !== -1) {
            toggleCollapseButton({target: buttons[i].children[0]});
        }
    }

    var responseCodes = document.querySelectorAll('.example-names');
    for (i = 0; i < responseCodes.length; i++) {
        var tabButtons = childrenByClass(responseCodes[i], 'tab-button');
        for (j = 0; j < tabButtons.length; j++) {
            tabButtons[j].onclick = toggleTabButton;

            // Show by default?
            if (j === 0) {
                toggleTabButton({target: tabButtons[j]});
            }
        }
    }

    // Make nav items clickable to collapse/expand their content.
    var navItems = document.querySelectorAll('nav .resource-group .heading');
    for (i = 0; i < navItems.length; i++) {
        navItems[i].onclick = toggleCollapseNav;

        // Show all by default
        toggleCollapseNav({target: navItems[i].children[0]});
    }

    // Set up the sandbox functionality
    var tryitButtons = document.querySelectorAll('button.tryit');
    for (i = 0; i < tryitButtons.length; i++) {
        tryitButtons[i].onclick = sendSandboxRequest;
    }
    var clickToFills = document.querySelectorAll('.click-to-fill');
    for (i = 0; i < clickToFills.length; i++) {
        clickToFills[i].title = clickToFills[i].title || 'Click to fill the field with this value';
        clickToFills[i].onclick = fillField.bind(null, clickToFills[i].dataset.fillTarget);
    }
}

// Initial call to set up buttons
init();

window.onload = function () {
    autoCollapse();
    // Remove the `preload` class to enable animations
    document.querySelector('body').className = '';
};
