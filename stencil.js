/*! Stencil.js templating/binding engine
https://github.com/rstacruz/stencil.js
*/


(function() {
  var Listener,
    __slice = [].slice;

  Listener = (function() {

    function Listener($el, model, rules) {
      this.$el = $el;
      this.model = model;
      this.events = this._flattenRules(rules);
      this.memoize(this, 'getSingleRunner');
      this.bind();
    }

    Listener.prototype.memoize = function(obj, attr) {
      var all, fn;
      all = function(a, b, $el) {
        var uniq, _ref;
                if ((_ref = $el.data('uniq')) != null) {
          _ref;

        } else {
          $el.data('uniq', Math.random());
        };
        uniq = $el.data('uniq');
        return [a, b, uniq];
      };
      fn = obj[attr];
      return obj[attr] = _.memoize(fn, all);
    };

    Listener.prototype.bind = function() {
      var _ref,
        _this = this;
      if (!((_ref = this.model) != null ? _ref.on : void 0)) {
        return;
      }
      this.unbind();
      this.handlers = {};
      _.each(this.events, function(directives, event) {
        _this.handlers[event] = function() {
          var args;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          return _this.run.apply(_this, [event].concat(__slice.call(args)));
        };
        return _this.model.on(event, _this.handlers[event]);
      });
      return this;
    };

    Listener.prototype.unbind = function() {
      var _ref,
        _this = this;
      if (!((_ref = this.model) != null ? _ref.off : void 0)) {
        return;
      }
      if (this.handlers) {
        _.each(this.handlers, function(fn, event) {
          return _this.model.off(event, fn);
        });
        this.handlers = null;
      }
      return this;
    };

    Listener.prototype._flattenRules = function(rules) {
      var re,
        _this = this;
      re = {};
      _.each(rules, function(directives, eventList) {
        var events;
        events = eventList.split(/, */);
        return _.each(events, function(event) {
          var _ref;
          if ((_ref = re[event]) == null) {
            re[event] = {};
          }
          return _.extend(re[event], directives);
        });
      });
      return re;
    };

    Listener.prototype.run = function() {
      var args, events;
      events = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      if (events == null) {
        events = '*';
      }
      if (events.indexOf('*') > -1) {
        return this.runGlob(events);
      }
      if (!_.isArray(events)) {
        events = [events];
      }
      this.runDirectives(this.getDirectivesFor(events), args);
      return this;
    };

    Listener.prototype.runDirectives = function(directives, args, $el) {
      var fn;
      if ($el == null) {
        $el = this.$el;
      }
      fn = this.getRunner(directives, $el);
      return fn(args);
    };

    Listener.prototype.getRunner = function(directives, $el) {
      var runners,
        _this = this;
      if ($el == null) {
        $el = this.$el;
      }
      runners = _.map(directives, function(handler, matcher) {
        return _this.getSingleRunner(matcher, handler, $el);
      });
      return function(args) {
        return _.each(runners, function(runner) {
          return runner(args);
        });
      };
    };

    Listener.prototype.getSingleRunner = function(matcher, handler, $el) {
      var action, m, match, selector;
      match = function(str, regex) {
        var m;
        if (!regex) {
          return [];
        }
        m = str.match(regex);
        if (!m) {
          throw "Matcher error: '" + str + "'";
        }
        return m;
      };
      m = match(matcher, this.formats.selector);
      action = m[1];
      selector = m[2];
      if (!this.runners[action]) {
        throw "Unknown action: '" + action + "'";
      }
      m = match(selector, this.formats[action]);
      return this.runners[action].apply(this, [selector, handler, $el, m[1], m[2], m[3]]);
    };

    Listener.prototype.formats = {
      selector: /^\s*([^\s]+)\s*(.*?)\s*$/,
      add: /^(.*?)\s*>\s*([^>]+?)$/,
      attr: /^(.*?)\s*@([A-Za-z0-9\-\_]+)$/,
      remove: /^(.*?)\s*>\s*([^>]+?)\s*@([A-Za-z0-9\-\_]+)\s*$/
    };

    Listener.prototype.runners = {
      "default": function(selector, handler, $el, action) {
        var fn,
          _this = this;
        fn = _.bind(handler, this.model);
        return function(args) {
          var val;
          val = fn.apply(null, args);
          return $el.find(selector)[action](val);
        };
      },
      html: function(selector, handler, $el) {
        return this.runners["default"].apply(this, [selector, handler, $el, 'html']);
      },
      text: function(selector, handler, $el) {
        return this.runners["default"].apply(this, [selector, handler, $el, 'text']);
      },
      attr: function(selector, handler, $el, m1, m2) {
        var $_el, fn,
          _this = this;
        $_el = $el;
        if (m1.length) {
          $_el = $_el.find(m1);
        }
        fn = _.bind(handler, this.model);
        return function(args) {
          return $_el.attr(m2, fn.apply(null, args));
        };
      },
      add: function(selector, handler, $el, m1, m2) {
        var $_el, $tpl,
          _this = this;
        $_el = $el;
        if (m1.length) {
          $_el = $_el.find(m1);
        }
        $tpl = $($_el.find(m2)[0]).remove();
        return function(args) {
          var work;
          work = function(_args) {
            var $new, runner;
            $new = $tpl.clone();
            runner = _this.getRunner(handler, $new);
            runner(_args);
            return $_el.append($new);
          };
          if (_.isArray(args[0])) {
            return _.each(args[0], function(model) {
              return work([model]);
            });
          } else if (args[0].each) {
            return args[0].each(function(model) {
              return work([model]);
            });
          } else {
            return work(args);
          }
        };
      },
      remove: function(selector, handler, $el, m1, m2, attribute) {
        var $_el, fn,
          _this = this;
        $_el = $el;
        if (m1.length) {
          $_el = $_el.find(m1);
        }
        fn = _.bind(handler, this.model);
        return function(args) {
          var val;
          val = fn.apply(null, args);
          return $_el.find(m2).filter("[" + attribute + "=\"" + val + "\"]").remove();
        };
      }
    };

    Listener.prototype.runGlob = function(glob) {
      var events;
      events = _.filter(_.keys(this.events), function(event) {
        return event.match(new RegExp("^" + (glob.replace('*', '.*')) + "$"));
      });
      return this.run(events);
    };

    Listener.prototype.getDirectivesFor = function(events) {
      var directives,
        _this = this;
      if (!_.isArray(events)) {
        events = [events];
      }
      directives = {};
      _.each(events, function(event) {
        if (typeof _this.events[event] === 'object') {
          return _.extend(directives, _this.events[event]);
        }
      });
      return directives;
    };

    return Listener;

  })();

  $.fn.stencil = function() {
    var args;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return (function(func, args, ctor) {
      ctor.prototype = func.prototype;
      var child = new ctor, result = func.apply(child, args), t = typeof result;
      return t == "object" || t == "function" ? result || child : child;
    })(Listener, [this].concat(__slice.call(args)), function(){});
  };

}).call(this);
