# モデルクラス
class @Model

  # モデルの機能を付与する
  @mixin: (clazz) ->
    # IEのコンソール対策
    global = do () -> @
    global.console ?= {}
    global.console.log ?= () ->
    global.console.debug ?= () ->
    global.console.warn ?= () ->
    
    clazz[name] = method for name, method of Model
    
    if @relationalModels()[clazz.getName()]?
      capture = {}
      if Error.captureStackTrace?
        Error.captureStackTrace(capture, @mixin)
      else
        capture.stack = "stack trace unsupported."
      console.warn("override relationalModel: #{clazz.getName()} at #{capture.stack}")
    @relationalModels()[clazz.getName()] = clazz
    
    clazz.prototype[name] = method for name, method of Model.prototype
    return

  # 関連モデルを保持する
  @relationalModels: () ->
    Model.relationalModels ?= {}

  # 関連からモデルを作成する 
  @getRelationalModel: (assoc) ->
    model = @relationalModels()[assoc.options.model]
    if not model?
      throw new Error("#{assoc.options.model} is not registerd relationalModels")
    return model
  
  # 関連定義を保持する
  @associations: () ->
    @_associations ?= {}

  # 関連の定義をする
  @assign: (model, type, key, options) ->
    options.model ?= key.singularize().camelize()
    model.associations()[key] = {type: type, options: options}
  
  # belongsTo関連を定義する
  @belongsTo: (key, options={}) ->
    @assign(@, "belongsTo", key, options)

  # hasOne関連を定義する
  @hasOne: (key, options={}) ->
    @assign(@, "hasOne", key, options)

  # hasMany関連を定義する
  # optionsにはthrough: modelNameを指定できる
  @hasMany: (key, options={}) ->
    @assign(@, "hasMany", key, options)
  
  # このモデルが保持できるプロパティを定義する
  @expectAttrs: (expectAttrs=null) ->
    if arguments.length == 0
      @_expectAttrs ?= []
    else
      @_expectAttrs = expectAttrs
  
  @getName: () ->
    if not @hasOwnProperty(name)
      @name = (''+@).replace(/^\s*function\s*([^\(]*)[\S\s]+$/im, '$1')
    @name
  
  # クラス名を取得する
  getClassName: () ->
    @constructor.getName()
    
  # プロパティの一覧を取得する
  attrs: () ->
    @_attrs ?= {}
    
  # プロパティの存在を確認する
  hasProperty: (name) ->
    @attrs().hasOwnProperty(name)
    
  # プロパティを取得する
  # expect: trueの場合かつ、プロパティが存在しない場合にエラーを発生させる
  getProperty: (name, expect=true) ->
    if expect && not @hasProperty(name)
      throw new Error("""
          #{@getClassName()} has not #{name} property.
              attrs: #{JSON.stringify(@attrs())}
      """)
    else
      return @attrs()[name];
      
  # プロパティを設定する
  setProperty: (name, value, expect=true) ->
    expectAttrs = @constructor.expectAttrs()
    if not(expectAttrs.isEmpty())
      if expectAttrs.indexOf(name) != -1
        @attrs()[name] = value
    else
      @attrs()[name] = value
    
  # プロパティを取得する
  get: (name, expect=false) ->
    @getProperty(name, expect)
  
  # プロパティを設定する
  set: (name, value, expect=false) ->
    @setProperty(name, value, expect)

  # データをモデルに変換し、モデル名とIDで仕分けしたグループ情報を返す
  @grouping: (data, models={}) ->
    model = new @()
    for key, value of data
      assoc = @associations()?[key]
      if not(assoc?)
        model.setProperty(key, value)
      else
        switch assoc.type
          when "hasMany"
            if not Object.isArray(value)
              throw new Error("#{@getName()} has #{key} property is not array.")
            for item in value
              modelClass = @getRelationalModel(assoc)
              modelClass.grouping(item, models)
          when "hasOne"
            modelClass = @getRelationalModel(assoc)
            modelClass.grouping(value, models)
          when "belongsTo"
            modelClass = @getRelationalModel(assoc)
            modelClass.grouping(value, models)
          else
            throw new Error("#{assoc.type} is not association type.")
    
    models[@getName()] ?= {}
    if models[@getName()][model.getProperty("id")]?
      console.debug("#{@getName()}:#{model.getProperty('id')} is duplicated.")
    else
      models[@getName()][model.getProperty("id")] = model
    return {
      model: model
      models: models
    }

  # モデルの関連情報を元に渡されたグループ情報に存在するモデル同士を結びつける
  @mapping: (group) ->
    lazyLoaders = [];
    for clazz, models of group.models
      for id, model of models
        for key, assoc of model.constructor.associations()
          switch assoc.type
            when "hasMany"
              through = assoc.options.through
              if through?
                do (id, model, key, assoc) =>
                  # through する対象を記述している場合は処理を追加する
                  if model.hasProperty(through)
                    lazyLoaders.push () =>
                      
                      # 同じIDがある場合は複数登録しない
                      done = {}
                      targets = []
                      for throughModel in model.getProperty(through)
                        target = throughModel.getProperty(assoc.options.model.toLowerCase())
                        relationId = target.getProperty("id")
                        if not done.hasOwnProperty(relationId)
                          targets.push(target)
                        done[relationId] = true
                      
                      # 関連先がある場合は配列を代入する
                      model.setProperty(key, targets, false) if not targets.isEmpty()
                  
              else
                targets = []
                id = model.getProperty("id")
                for _none, target of group.models[assoc.options.model]
                  relationId = target.getProperty("#{model.getClassName().toLowerCase()}Id")
                  if id == relationId
                    targets.push(target)
                
                if not targets.isEmpty()
                  model.setProperty(key, targets, false)

            when "hasOne"
              id = model.getProperty("id")
              for _none, target of group.models[assoc.options.model]
                relationId = target.getProperty("#{model.getClassName().toLowerCase()}Id")
                if id == relationId
                  model.setProperty(key, target, false)
                  break

            when "belongsTo"
              relationId = model.getProperty("#{assoc.options.model.toLowerCase()}Id")
              target = group.models[assoc.options.model][relationId]
              if target?
                model.setProperty(key, target, false)
    
    # 後読み処理を実行する
    for lazyLoader in lazyLoaders
      lazyLoader()
    
    return @
    
  # 新しいオブジェクトを作成する
  @create: (data={}) ->
    model = new @()
    model.fromJS(data)
    return model
    
  # json をモデルに取り込む
  fromJSON: (json) -> 
    @fromJS(JSON.parse(json))
    return @

  # js をモデルに取り込む
  fromJS: (data) ->
    group = @constructor.grouping(data)
    @constructor.mapping(group)
    for key, value of group.model.attrs()
      @setProperty(key, value, false)
    return @

  # モデルをオブジェクトに変換する
  # includes に関連のプロパティを指定することによって、関連のプロパティもオブジェクトに変換する
  # {
  #   galaxies: {
  #     planets: [creatures]
  #     or planets: {}
  #   }
  # }
  toJS: (includes={}) ->
  
    # includes がオブジェクトまたは配列以外の場合はエラー
    if not(Object.isObject(includes)) && not(Object.isArray(includes))
      throw new Error("includes is object or array")
  
    # コピー作成
    js = {}
    for key, value of @attrs()
      js[key] = value

    # includes に含まれていない関連は削除する
    for key, assoc of @constructor.associations()
      if not(includes?) || (Object.isObject(includes) && not(includes.hasOwnProperty(key))) || (Object.isArray(includes) && includes.indexOf(key) == -1)
        delete js[key]
      else
        if Object.isArray(js[key])
          ary = []
          for model in js[key]
            ary.push(model.toJS(includes[key]))
          js[key] = ary
        else
          js[key] = js[key].toJS(includes[key])
    return js

  # json を取得する
  toJSON: (includes=[]) ->
    JSON.stringify(@toJS(includes))