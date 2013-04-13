app = angular.module("bitcoinSecured", ['ui.bootstrap']).config(['$routeProvider', '$locationProvider', ($routeProvider, $locationProvider)->

  $routeProvider.when("/",
    action: "home.default"
    controller: RegisterCtrl
    templateUrl: "register.html"
  ).when("/download",
    action: "download.default"
    controller: DownloadCtrl
    templateUrl: "download.html"
  )

])


app.factory("txevent",['$window', ($window)->

  notify: (msg)->
    $window.alert(msg)

  doTrans: (tx_dest, tx_sec, tx_addr, tx_unspent)->
    secret = $window.Bitcoin.Base58.decode(tx_sec).slice(1, 33)
    eckey = new $window.Bitcoin.ECKey(secret)
    tx = new $window.TX(eckey)
    tx.parseInputs(tx_unspent, tx.getAddress())
    tx.addOutput(tx_dest, 0.1)
    sendTx = tx.construct()
    # console.log tx.toBBE(sendTx)
    console.log $window.Crypto.util.bytesToHex(sendTx.serialize())

  ])

app.directive("qrCode", ['$window', ($window)->

  template: "<div id='qr-code'></div>"
  restrict: 'E'
  scope:
    localQrMsg: '=myAttr'

  link: (scope, element, attrs) ->

    el = angular.element(element)

    qr = new $window.QRCode(el[0], scope.localQrMsg)

])


# Define our root-level controller for the application.
app.controller("AppController", AppController = ($scope, $route, $routeParams) ->
  
  # Update the rendering of the page.
  render = ->
    
    # Pull the "action" value out of the
    # currently selected route.
    # We have to check if it's defined first since upon initial load of this single page app
    # there is an async redirect to '#/' which causes this issue
    if _.isUndefined($route.current.action)
      renderAction = "home.default"
    else
      renderAction = $route.current.action
    console.log "render action is: " + renderAction
    
    # Also, let's update the render path so that
    # we can start conditionally rendering parts
    # of the page.
    renderPath = renderAction.split(".")
    console.log "render path is: " + renderPath
    
    # Reset the booleans used to set the class
    # for the navigation.
    isHome = (renderPath[0] is "home")
    isDownload = (renderPath[0] is "download")
    
    # Store the values in the model.
    $scope.renderAction = renderAction
    $scope.renderPath = renderPath
    $scope.isHome = isHome
    $scope.isDownload = isDownload

  
  # Listen for changes to the Route. When the route
  # changes, let's set the renderAction model value so
  # that it can render in the Strong element.
  $scope.$on "$routeChangeSuccess", ($currentRoute, $previousRoute) ->
    
    # Update the rendering.
    render()

)


app.controller("DownloadCtrl", DownloadCtrl = ($scope) ->
  $scope.downloads = {}
)

app.controller("RegisterCtrl", RegisterCtrl = ($scope, $location, $dialog) ->

  $scope.appdata = {}

  $scope.steps = ["Enter Data", "Enter Paste"]
  $scope.selection = $scope.steps[0]
  $scope.getCurrentStepIndex = ->
    
    # Get the index of the current step given selection
    _.indexOf $scope.steps, $scope.selection

  
  # Go to a defined step index
  $scope.goToStep = (index) ->
    $scope.selection = $scope.steps[index]  unless _.isUndefined($scope.steps[index])

  $scope.hasNextStep = ->
    stepIndex = $scope.getCurrentStepIndex()
    nextStep = stepIndex + 1
    
    # Return true if there is a next step, false if not
    not _.isUndefined($scope.steps[nextStep])

  $scope.hasPreviousStep = ->
    stepIndex = $scope.getCurrentStepIndex()
    previousStep = stepIndex - 1
    
    # Return true if there is a next step, false if not
    not _.isUndefined($scope.steps[previousStep])

  $scope.incrementStep = ->
    if $scope.hasNextStep()
      stepIndex = $scope.getCurrentStepIndex()
      nextStep = stepIndex + 1
      $scope.selection = $scope.steps[nextStep]

  $scope.decrementStep = ->
    if $scope.hasPreviousStep()
      stepIndex = $scope.getCurrentStepIndex()
      previousStep = stepIndex - 1
      $scope.selection = $scope.steps[previousStep]

  $scope.openModal = ->
    console.log "opening modal"
    $scope.shouldBeOpen = true

  $scope.closeModal = ->
    $scope.closeMsg = "I was closed at: " + new Date()
    $scope.shouldBeOpen = false

  $scope.modalOpts =
    backdropFade: true
    dialogFade: true

)

app.controller("ModalCtrl", ModalCtrl = ($scope) ->

)

app.controller("FormCtrl", FormCtrl = ($scope, $http, $dialog) ->

  $scope.rawtx = ""

  $scope.buttonState = {}

  $scope.buttonState.qrcodestate = "disabled"

  $scope.transaction = {}

  $scope.loadUrl = ()->

    q = "/blockchain/unspent?address=#{$scope.transaction.address}"

    tx = {}

    tx.dest = $scope.transaction.recipient
    $scope.appdata.dest = tx.dest
    tx.addr = $scope.transaction.address
    tx.amount = $scope.transaction.amount
    tx.fee = $scope.transaction.fee

    $http.get(q)
      .success( (data, status)->
        console.log data
        console.log status
        tx.unspent = data
        $scope.appdata.rawtx = JSON.stringify(tx)
      ).error( (data, status)->
        if data is "No free outputs to spend"
          txevent.alert "No free outputs to spend at this address"


  $scope.processForm = ()->
    console.log "Processing form..."
    $scope.loadUrl()
    # $scope.openNotice(key_to_english($scope.appdata.dest))

  $scope.showQr = ()->
    $scope.openDialog($scope.appdata.rawtx)


  $scope.clearAll = (e)->
    e.preventDefault()
    $scope.transaction = {}
    $scope.paste = ""

  $scope.openDialog = (msg)->

    t = """
      <div id="modal">
          <qr-code my-attr="msg"></qr-code>
      </div>
      """

    opts =
      # templateUrl: 'dialog.html'
      template: t
      dialogClass: "modal qr-modal"
      controller: "DialogCtrl"
      backdrop: true
      resolve: {msg: ()->
        angular.copy(msg)
      }
    d = $dialog.dialog(opts)
    d.open().then (result) ->
      if result is 'ok'
        console.log "Your transaction is ok"
      else
        console.log "Your transaction is cancelled"

  $scope.openNotice = (msg)->

    t = """
      <div id="notice-modal">
        <div class="modal-header">
          <h3>Security Phrase</h3>
        </div>
        <div class="modal-body">
          <p>The phrase below is your security phrase.  The same phrase will be shown to you again when you enter your offline transaction.  If you notice any difference between the two phrases, please abandon the offline signing process.</p>
          <div>
            <h3>"{{msg}}"</h3>
          </div>
        </div>
        <div class="modal-footer">
          <button ng-click="close(result)" class="btn btn-primary" >I understand</button>
        </div>
      </div>
      """
 
    opts =
      # templateUrl: 'dialog.html'
      template: t
      dialogClass: "modal notice-modal"
      controller: "DialogCtrl"
      backdrop: true
      resolve: {msg: ()->
        angular.copy(msg)
      }
         
    d = $dialog.dialog(opts)
    d.open().then (result) ->
      if result is 'ok'
        console.log "Your transaction is ok"
      else
        console.log "Your transaction is cancelled"
)


app.controller("SubmitCtrl", SubmitCtrl = ($scope) ->

  $scope.submitTx = ()->

    config = {}

    config.url = "/blockchain/pushtx"
    config.data = JSON.stringify($scope.rawpaste)
    config.method = 'POST'

    $http(config)
      .success( (data, status)->
        console.log data
        console.log status
      )

)

# the dialog is injected in the specified controller
app.controller("DialogCtrl", DialogCtrl = ($scope, msg, dialog) ->
  $scope.close = (result) ->
    dialog.close result

  $scope.msg = msg
)

app.controller("AlertCtrl", AlertCtrl = ($scope) ->

  $scope.alerts = [
    type: "error"
    msg: "Bitcoin Secured 0.1 is beta quality software. As such, there is a small but real chance of software error. Please don't use this system to transfer large amounts of Bitcoins until this beta notice is removed."
  ]

  $scope.addAlert = (msg)->
    $scope.alerts.push msg: msg

  $scope.closeAlert = (index) ->
    $scope.alerts.splice index, 1

)
