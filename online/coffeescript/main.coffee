app = angular.module("bitcoinSecured", [])

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

app.factory("qrcode", ['$window', ($window)->

  renderQR: (msg)->
    $window.qr = new $window.QRCode($("#qr-code").get(0), msg)

  hideQR: ->
    $window.qr.clear()

])


app.controller("RegisterCtrl", RegisterCtrl = ($scope, $location) ->

  $scope.appdata = {}

  $scope.steps = ["Enter Data", "Copy Paste", "Enter Paste"]
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

)

app.controller("FormCtrl", FormCtrl = ($scope, $http) ->

  $scope.rawtx = ""

  $scope.transaction = {}

  $scope.loadUrl = ()->

    q = "http://http://23.21.122.172/blockchain/unspent?address=#{$scope.transaction.address}"

    tx = {}

    tx.dest = $scope.transaction.recipient
    tx.addr = $scope.transaction.address
    tx.amount = $scope.transaction.amount
    tx.fee = $scope.transaction.fee

    $http.get(q)
      .success( (data, status)->
        console.log data
        tx.unspent = JSON.parse(data)
        $scope.data.tx = tx

      )

    return true

  $scope.processForm = ()->

    console.log "processing form"
    $scope.loadUrl()

)


app.controller("TextCtrl", TextCtrl = ($scope, qrcode) ->


  $scope.renderTx = ()->

    tx = $scope.data.tx
    $scope.rawtx = JSON.stringify(tx)
    qrcode.renderQR(tx)

)

app.controller("SubmitCtrl", SubmitCtrl = ($scope, txevent) ->

)
