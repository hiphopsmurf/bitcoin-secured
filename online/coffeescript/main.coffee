app = angular.module("bitcoinSecured", ['ui.bootstrap', 'ngSanitize'])


###
@ngdoc directive
@name ngSanitize.directive:ngBindHtml

@description
Creates a binding that will sanitize the result of evaluating the `expression` with the
{@link ngSanitize.$sanitize $sanitize} service and innerHTML the result into the current element.

See {@link ngSanitize.$sanitize $sanitize} docs for examples.

@element ANY
@param {expression} ngBindHtml {@link guide/expression Expression} to evaluate.
###
# app.directive "ngBindHtml", ["$sanitize", ($sanitize) ->
#   (scope, element, attr) ->
#     element.addClass("ng-binding").data "$binding", attr.ngBindHtml
#     scope.$watch attr.ngBindHtml, ngBindHtmlWatchAction = (value) ->
#       value = $sanitize(value)
#       element.html value or ""
# 
# ]

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
      )

    return true

  $scope.processForm = ()->
    console.log "Processing form..."
    $scope.loadUrl()
    $scope.openNotice(key_to_english($scope.appdata.dest))

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

