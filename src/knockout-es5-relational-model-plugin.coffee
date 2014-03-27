Model.prototype.setProperty = (name, value, expect=true) ->
  expectAttrs = @constructor.expectAttrs()
  if not(expectAttrs.isEmpty())
    if expectAttrs.indexOf(name) != -1
      @attrs()[name] = value
      ko.track(@attrs(), [name])
  else
    @attrs()[name] = value
    ko.track(@attrs(), [name])
    
Model.prototype.getObservable = (name, expect=true) ->
  if expect && not @hasProperty(name)
    throw new Error("""
        #{@getClassName()} has not #{name} property.
            attrs: #{JSON.stringify(@attrs())}
    """)
  else
    return ko.getObservable(@attrs(), name);