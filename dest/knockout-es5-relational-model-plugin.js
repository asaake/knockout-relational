Model.prototype.setProperty = function(name, value, expect) {
  var expectAttrs;
  if (expect == null) {
    expect = true;
  }
  expectAttrs = this.constructor.expectAttrs();
  if (!(expectAttrs.isEmpty())) {
    if (expectAttrs.indexOf(name) !== -1) {
      this.attrs()[name] = value;
      return ko.track(this.attrs(), [name]);
    }
  } else {
    this.attrs()[name] = value;
    return ko.track(this.attrs(), [name]);
  }
};

Model.prototype.getObservable = function(name, expect) {
  if (expect == null) {
    expect = true;
  }
  if (expect && !this.hasProperty(name)) {
    throw new Error("" + (this.getClassName()) + " has not " + name + " property.\n    attrs: " + (JSON.stringify(this.attrs())));
  } else {
    return ko.getObservable(this.attrs(), name);
  }
};