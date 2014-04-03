Model.prototype.getProperty = (name, expect=true) ->
  if expect && not @hasProperty(name)
    throw new Error("""
        #{@getClassName()} has not #{name} property.
            attrs: #{JSON.stringify(@attrs())}
    """)
  else
    if ko.isObservable(@attrs()[name])
      @attrs()[name]();
    else
      @attrs()[name]
Model.prototype.setProperty = (name, value, expect=true) ->
  
  setProperty = (name, value) =>
    if Object.isObject(value)
      @attrs()[name] = value
    else if @hasProperty(name) && ko.isObservable(@attrs()[name])
      @attrs()[name](value)
    else
      if Object.isArray(value)
        @attrs()[name]= ko.observableArray(value)
      else
        @attrs()[name] = ko.observable(value)
  
  expectAttrs = @constructor.expectAttrs()
  if not(expectAttrs.isEmpty())
    if expectAttrs.indexOf(name) != -1
      setProperty(name, value)
  else
    setProperty(name, value)
    
Model.prototype.getObservable = (name, expect=true) ->
  if expect && not @hasProperty(name)
    throw new Error("""
        #{@getClassName()} has not #{name} property.
            attrs: #{JSON.stringify(@attrs())}
    """)
  else
    return @attrs()[name]

Model.prototype.setObservable = (name, ob, expect=true) ->
  setObservable = (name, ob) =>
    @attrs()[name] = ob
  
  expectAttrs = @constructor.expectAttrs()
  if not(expectAttrs.isEmpty())
    if expectAttrs.indexOf(name) != -1
      setObservable(name, ob)
  else
    setObservable(name, ob)