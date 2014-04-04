Model.prototype.getProperty = function(name, expect) {
  if (expect == null) {
    expect = true;
  }
  if (expect && !this.hasProperty(name)) {
    throw new Error("" + (this.getClassName()) + " has not " + name + " property.\n    attrs: " + (JSON.stringify(this.attrs())));
  } else {
    if (ko.isObservable(this.attrs()[name])) {
      return this.attrs()[name]();
    } else {
      return this.attrs()[name];
    }
  }
};

Model.prototype.setProperty = function(name, value, expect) {
  var expectAttrs, setProperty;
  if (expect == null) {
    expect = true;
  }
  setProperty = (function(_this) {
    return function(name, value) {
      if (Object.isObject(value)) {
        return _this.attrs()[name] = value;
      } else if (_this.hasProperty(name) && ko.isObservable(_this.attrs()[name])) {
        return _this.attrs()[name](value);
      } else {
        if (Object.isArray(value)) {
          return _this.attrs()[name] = ko.observableArray(value);
        } else {
          return _this.attrs()[name] = ko.observable(value);
        }
      }
    };
  })(this);
  expectAttrs = this.constructor.expectAttrs();
  if (!(expectAttrs.isEmpty())) {
    if (expectAttrs.indexOf(name) !== -1) {
      return setProperty(name, value);
    }
  } else {
    return setProperty(name, value);
  }
};

Model.prototype.getObservable = function(name, expect) {
  if (expect == null) {
    expect = true;
  }
  if (expect && !this.hasProperty(name)) {
    throw new Error("" + (this.getClassName()) + " has not " + name + " property.\n    attrs: " + (JSON.stringify(this.attrs())));
  } else {
    return this.attrs()[name];
  }
};

Model.prototype.setObservable = function(name, ob, expect) {
  var expectAttrs, setObservable;
  if (expect == null) {
    expect = true;
  }
  setObservable = (function(_this) {
    return function(name, ob) {
      return _this.attrs()[name] = ob;
    };
  })(this);
  expectAttrs = this.constructor.expectAttrs();
  if (!(expectAttrs.isEmpty())) {
    if (expectAttrs.indexOf(name) !== -1) {
      return setObservable(name, ob);
    }
  } else {
    return setObservable(name, ob);
  }
};