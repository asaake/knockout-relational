#= require knockout-relational-model-plugin.coffee

describe "Model", () ->

  describe "コモンメソッド", () ->
  
    before () ->
      class @Employee
        Model.mixin(@)
      
    after () ->
      delete @Employee
      
    beforeEach () ->
      @employee = new @Employee()
      
    afterEach () ->
      delete @employee
      
    it "setObservableでObservableが設定できる", () ->
      @employee.setObservable("key", ko.observable("value"))
      ob = @employee.attrs()["key"]
      expect(ko.isObservable(ob)).to.eql(true)
      expect(ob()).to.eql("value")
      
    it "getObservableでObservableが取得できる", () ->
      @employee.setObservable("key", ko.observable("value"))
      ob = @employee.getObservable("key")
      expect(ko.isObservable(ob)).to.eql(true)
      expect(ob()).to.eql("value")
      
    it "setPropertyでObservableが設定できる", () ->
      @employee.setProperty("key", "value")
      ob = @employee.getObservable("key")
      expect(ko.isObservable(ob)).to.eql(true)
      expect(ob()).to.eql("value")
    
    it "getPropertyでObservableの値が取得できる", () ->
      @employee.setProperty("key", "value")
      value = @employee.getProperty("key")
      expect(value).to.eql("value")
      
    it "setPropertyでオブジェクトはObservableとしない", () ->
      @employee.setProperty("obj", {})
      value = @employee.getObservable("obj")
      expect(value).to.eql({})
      
    it "getPropertyでオブジェクトを取得できる", () ->
      @employee.setProperty("obj", {})
      value = @employee.getProperty("obj")
      expect(value).to.eql({})
      
  describe "ネストした関連をObservableで取り込める", () ->
    
    before () ->
      data = {
        id: 1
        name: "emp1"
        assigns: [{
          id: 21
          employeeId: 1
          departmentId: 11
          department: {
            id: 11
            name: "dept11"
          }
        }, {
          id: 22
          employeeId: 1
          departmentId: 11
        }]
      }
      
      class Employee
        Model.mixin(@)
        @hasMany("assigns")
        @hasMany("departments", {through: "assigns"})
        
      class Assign
        Model.mixin(@)
        @belongsTo("employee")
        @belongsTo("department")

      class Department
        Model.mixin(@)
        @hasMany("assigns")
        @hasMany("employees", {through: "assigns"})
      
      group = Employee.grouping(data)
      Employee.mapping(group)
      @employee = group.model
    
    after () ->
      delete @employee
      
    it "employeeのモデルが取り込んだデータと一致する", () ->
      expect(@employee.get("id")).to.eql(1)
      expect(@employee.get("name")).to.eql("emp1")
      
    it "employee.assignsが取り込んだデータと一致する", () ->
      expect(@employee.attrs()).to.have.property("assigns")
      
      assigns = @employee.get("assigns")
      expect(assigns.length).to.eql(2)
      
      expect(assigns[0].get("id")).to.eql(21)
      expect(assigns[0].get("employeeId")).to.eql(1)
      expect(assigns[0].get("departmentId")).to.eql(11)
      
      expect(assigns[1].get("id")).to.eql(22)
      expect(assigns[1].get("employeeId")).to.eql(1)
      expect(assigns[1].get("departmentId")).to.eql(11)
      
    it "employee.assings.departmentが取り込んだデータと一致する", () ->
      expect(@employee.attrs()).to.have.property("assigns")
      
      department = @employee.get("assigns")[0].get("department")
      expect(department.get("id")).to.eql(11)
      expect(department.get("name")).to.eql("dept11")
      
    it "employee.departmentsが取り込んだデータと一致する", () ->
      expect(@employee.attrs()).to.have.property("departments")
      
      departments = @employee.get("departments")
      
      expect(departments.length).to.eql(1)
      expect(departments[0].get("id")).to.eql(11)
      expect(departments[0].get("name")).to.eql("dept11")
      
    it "配列はobservableArrayになっている", () ->
      departments = @employee.getObservable("departments")
      expect(ko.isObservable(departments)).to.eql(true)
      expect(departments).to.have.property("push")