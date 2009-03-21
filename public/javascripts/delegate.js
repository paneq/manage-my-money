// Delegate functions for prototype.js version 1.6
// ©2008 Ken Snyder (ken d snyder ~at~ gmail ~dot~ com) 
// under the creative commons attribution license v3.0 (http://creativecommons.org/licenses/by/3.0/)
Object.extend(Event, (function() {
  // Cache our delegates to allow removal.
  // handlers are stored in nested objects indexed thus:
  //   element.id => eventName => array of rules objects with selector : handler pairs
  var cache = { };
  return {
    // Add a delegate or set of delegate rules.
    // 3rd and 4th arguments can be rule, handler
    //   or 3rd argument can be rule-handler object property-value pairs.
    // (At least 3 arguments are required.)
    delegate: function(element, eventName) {
      // get the passed rules object
      if (arguments[3]) {
        // we have rule, handler in two arguments
        var rules = { };
        rules[arguments[2]] = arguments[3];
      } else {
        // we have a rule object
        var rules = Object.extend({ }, arguments[2]);
      }
      var el = $(element), ev = eventName, id = el.identify ? el.identify() : 'document';
      // set up our caching space if not defined
      if (!cache[id]) {
        // define observer function for each element
        cache[id] = {'$observer': function(event) {
          // function uses 'id' from scope above
          var el = event.element();
          if (cache[id][event.type])
            for (var i = 0, len = cache[id][event.type].length; i < len; i++)
              for (var selector in cache[id][event.type][i])
                if (cache[id][event.type][i][selector][1].match(el))
                  cache[id][event.type][i][selector][0](event);
        }};        
        // observe element
      }
      if (!cache[id][ev]) {
        cache[id][ev] = [];
        el.observe(ev, cache[id]['$observer']);
      }
      // cache the compiled Selector for each selector string
      for (var selectorStr in rules)
        rules[selectorStr] = [rules[selectorStr], new Selector(selectorStr)];
      // cache the rules
      cache[id][ev].push(rules);
      return el;
    },
    // Cancel a delegate or set of delegate rules.
    // 3rd argument can be a string rule
    //   or 3rd argument can be rule-handler object property-value pairs.
    // Without 3rd argument, all event rules for the event will be stopped.
    // Without eventName, all event rules for element will be stopped
    // Without element, all event rules ever defined will be stopped
    stopDelegating: function(element, eventName) {
      if (element === undefined) {
        // no element given, stop delegating everything
        for (var id in cache)
          Event.stopDelegating(id == '$document' ? document : id);
        cache = { };
        return true;
      }
      // get the passed rules object
      if (Object.isString(arguments[2])) {
        var rules = { };
        rules[arguments[2]] = true;
      } else if (arguments[2]) {
        var rules = arguments[2];
      } else {
        var rules = false;
      }
      var el = $(element), ev = eventName, id = el.identify ? el.identify() : '$document';
      // do we have such an id cached?
      if (cache[id]) {
        // do we have such an event cached
        if (ev && cache[id][ev]) {
          // check each rules set registered to this element for this event
          for (var i = 0, len = cache[id][ev].length; i < len; i++) {
            if (rules) {
              // we have one or more rules to stop
              for (var selector in rules)
                delete cache[id][ev][i][selector];
              // check if all rules are now stopped
            }
            if (!rules || $H(cache[id][ev][i]).any() == false) {
              // stop observing if we have no rules for this event
              el.stopObserving(ev, cache[id]['$observer']);
              cache[id][ev][i] = 'r';
            }
          }
          // remove all the entries that have just had their rules deleted
          cache[id][ev] = cache[id][ev].without('r');
        } else {
          // remove all entries for this whole element
          for (var evName in cache[id])
            if (evName != '$observer')
              el.stopObserving(evName, cache[id]['$observer']);
          delete cache[id];
        }
      }
      return el;
    }
  };
})());

// add our methods to elements and to the document
Element.addMethods({delegate: Event.delegate, stopDelegating: Event.stopDelegating});
document.delegate = Event.delegate.curry(document);
document.stopDelegating = Event.stopDelegating.curry(document);
Event.observe(window, 'unload', Event.stopDelegating);
