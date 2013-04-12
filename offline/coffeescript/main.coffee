app = angular.module("bitcoinSecured", ['ui.bootstrap'])

app.factory("txevent",['$window', ($window)->

  notify: (msg)->
    $window.alert(msg)

  doTrans: (tx_data)->
    secret = $window.Bitcoin.Base58.decode(tx_data.sec).slice(1, 33)
    eckey = new $window.Bitcoin.ECKey(secret)
    tx = new $window.TX(eckey)
    tx.parseInputs(tx_data.unspent, tx.getAddress())
    sendTx = tx.construct(tx_data.dest,tx_data.addr, tx_data.amount, tx_data.fee)
    console.log $window.Crypto.util.bytesToHex(sendTx.serialize())
    msg = {}
    msg.rawtx = $window.Crypto.util.bytesToHex(sendTx.serialize())
    msg.tx_data = tx_data
    msg

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


app.controller("FormCtrl", FormCtrl = ($scope, $http, $dialog, txevent) ->

  $scope.buttonState = {}

  $scope.buttonState.qrcodestate = "disabled"

  $scope.clearAll = (e)->
    e.preventDefault()
    $scope.transaction_data = ""
    $scope.rawtx = ""
    $scope.secret = ""

  $scope.openConfirmation = (msg)->
    tx_data = msg.tx_data
    t = """
    <div id="modal">
      <div class="modal-header">
        <h3>Raw Transaction Confirmation</h3>
      </div>
      <div class="modal-body">
      You are sending <strong>#{tx_data.amount} btc</strong> from cold storage address:<br>
      <strong>#{tx_data.addr}</strong><br>
      to Bitcoin address:<br>
      <strong>#{tx_data.dest}</strong><br>
      for a transaction fee of <strong>#{tx_data.fee}</strong>
      <p>If these are the amounts and recipient you intended, please click OK below.
      Otherwise, please cancel the transaction and repeat the online portion</p>
      </div>
      <div class="modal-footer">
        <button ng-click="close('cancel')" class="btn" >Cancel</button>
        <button ng-click="close('ok')" class="btn btn-primary" >OK</button>
      </div>
    </div>
    """
    opts =
      backdrop: true
      template: t
      controller: "ConfirmationCtrl"
    d = $dialog.dialog(opts)
    d.open().then (result) ->
      if result is 'ok'
        $scope.rawtx = msg.rawtx
      else
        alert "Your transaction is cancelled"

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

  $scope.showQr = ()->
    $scope.openDialog($scope.rawtx)

  $scope.processForm = ()->
    console.log "processing form now"
    tx = JSON.parse($scope.transaction_data)
    tx.sec = $scope.secret
    msg = txevent.doTrans(tx)
    $scope.openConfirmation(msg)
    $scope.buttonState.qrcodestate = ""
)

# the dialog is injected in the specified controller
app.controller("ConfirmationCtrl", ConfirmationCtrl = ($scope, dialog) ->
  $scope.close = (result) ->
    dialog.close result
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

