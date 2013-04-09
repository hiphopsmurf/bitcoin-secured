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

app.factory("qrcode", ['$window', ($window)->

  renderQR: (msg)->
    $("#qr-code").empty()
    new $window.QRCode($("#qr-code").get(0), msg)

  hideQR: ->
    $("#qr-code").empty()

])


app.controller("FormCtrl", FormCtrl = ($scope, $http, $dialog, txevent, qrcode) ->

  $scope.clearAll = (e)->
    e.preventDefault()
    $scope.transaction_data = ""
    $scope.rawtx = ""
    $scope.secret = ""
    qrcode.hideQR()

  $scope.openDialog = (msg)->
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
      controller: "DialogCtrl"
    d = $dialog.dialog(opts)
    d.open().then (result) ->
      if result is 'ok'
        $scope.rawtx = msg.rawtx
        qrcode.renderQR(msg.rawtx)
      else
        alert "Your transaction is cancelled"

  $scope.processForm = ()->
    console.log "processing form now"
    tx = JSON.parse($scope.transaction_data)
    tx.sec = $scope.secret
    msg = txevent.doTrans(tx)
    $scope.openDialog(msg)
)


# the dialog is injected in the specified controller
app.controller("DialogCtrl", DialogCtrl = ($scope, dialog) ->
  $scope.close = (result) ->
    dialog.close result
)
