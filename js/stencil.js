/*! Stencil.js templating/binding engine
https://github.com/rstacruz/stencil.js
*/


(function() {
  var $find, Stencil, uniqCount,
    __slice = [].slice;

  uniqCount = 0;

  $find = function($el, sub) {
    if (sub.length) {
      return $el.find(sub);
    } else {
      return $el;
    }
  };

  Stencil = (function() {

    function Stencil($el, model, rules, context) {
      this.$el = $el;
      this.model = model;
      this.events = this._flattenRules(rules);
      this.context = context != null ? context : this.model;
      this._memoize(this, 'getSingleRunner');
      this.bind();
    }

    Stencil.prototype._memoize = function(obj, attr) {
      var hasher;
      hasher = function(a, b, $el) {
        var uniq, _base, _ref;
        uniq = (_ref = (_base = $el[0]).uniq) != null ? _ref : _base.uniq = uniqCount++;
        return [a, b, uniq];
      };
      return obj[attr] = _.memoize(obj[attr], hasher);
    };

    Stencil.prototype.bind = function() {
      var _ref,
        _this = this;
      if ((_ref = this.model) != null ? _ref.on : void 0) {
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
      }
      return this;
    };

    Stencil.prototype.unbind = function() {
      var _ref,
        _this = this;
      if (((_ref = this.model) != null ? _ref.off : void 0) && this.handlers) {
        _.each(this.handlers, function(fn, event) {
          return _this.model.off(event, fn);
        });
        this.handlers = null;
      }
      return this;
    };

    Stencil.prototype._flattenRules = function(rules) {
      var re,
        _this = this;
      re = {};
      _.each(rules, function(directives, eventList) {
        var events;
        events = eventList.replace(/,/g, ' ').split(/\ +/);
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

    Stencil.prototype.run = function() {
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

    Stencil.prototype.runDirectives = function(directives, args, $el) {
      var fn;
      if ($el == null) {
        $el = this.$el;
      }
      fn = this.getRunner(directives, $el);
      return fn(args);
    };

    Stencil.prototype.getRunner = function(directives, $el) {
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

    Stencil.prototype.getSingleRunner = function(matcher, handler, $el) {
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

    Stencil.prototype.formats = {
      selector: /^\s*([^\s]+)\s*(.*?)\s*$/,
      add: /^(.*?)\s*>\s*([^>]+?)$/,
      attr: /^(.*?)\s*@([A-Za-z0-9\-\_]+)$/,
      remove: /^(.*?)\s*>\s*([^>]+?)\s*@([A-Za-z0-9\-\_]+)\s*$/
    };

    Stencil.prototype.runners = {
      "default": function(selector, handler, $el, action) {
        var fn,
          _this = this;
        fn = _.bind(handler, this.context);
        return function(args) {
          var val;
          val = fn.apply(null, args);
          return $find($el, selector)[action](val);
        };
      },
      html: function(selector, handler, $el) {
        return this.runners["default"].apply(this, [selector, handler, $el, 'html']);
      },
      text: function(selector, handler, $el) {
        return this.runners["default"].apply(this, [selector, handler, $el, 'text']);
      },
      val: function(selector, handler, $el) {
        return this.runners["default"].apply(this, [selector, handler, $el, 'val']);
      },
      value: function(selector, handler, $el) {
        return this.runners["default"].apply(this, [selector, handler, $el, 'val']);
      },
      attr: function(selector, handler, $el, sub, attribute) {
        var $_el, fn,
          _this = this;
        $_el = $find($el, sub);
        fn = _.bind(handler, this.context);
        return function(args) {
          return $_el.attr(attribute, fn.apply(null, args));
        };
      },
      add: function(selector, handler, $el, sub, template) {
        var $_el, $tpl,
          _this = this;
        $_el = $find($el, sub);
        $tpl = $($_el.find(template)[0]).remove();
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
        $_el = $find($el, m1);
        fn = _.bind(handler, this.context);
        return function(args) {
          var val;
          val = fn.apply(null, args);
          return $find($_el, m2).filter("[" + attribute + "=\"" + val + "\"]").remove();
        };
      }
    };

    Stencil.prototype.runGlob = function(glob) {
      var events;
      events = _.filter(_.keys(this.events), function(event) {
        return event.match(new RegExp("^" + (glob.replace('*', '.*')) + "$"));
      });
      return this.run(events);
    };

    Stencil.prototype.getDirectivesFor = function(events) {
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

    return Stencil;

  })();

  $.fn.stencil = function() {
    var args;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return (function(func, args, ctor) {
      ctor.prototype = func.prototype;
      var child = new ctor, result = func.apply(child, args), t = typeof result;
      return t == "object" || t == "function" ? result || child : child;
    })(Stencil, [this].concat(__slice.call(args)), function(){});
  };

  $.stencil = Stencil;

  $.stencil.version = "1.1.0";

}).call(this);
