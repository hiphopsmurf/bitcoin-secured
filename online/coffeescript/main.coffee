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


app.controller("FormCtrl", PageCtrl = ($scope, $http, txevent) ->

  $scope.rawtx = ""

  $scope.transaction = {}

  $scope.loadUrl = ()->

    q = "select * from html where url='http://blockchain.info/unspent?address=#{$scope.transaction.address}'"

    url = "http://query.yahooapis.com/v1/public/yql?q="

    terminal = "&format=json&callback=JSON_CALLBACK"

    target = url + encodeURIComponent(q) + terminal

    tx = {}

    tx.dest = $scope.transaction.recipient
    tx.addr = $scope.transaction.address
    tx.amount = $scope.transaction.amount
    tx.fee = $scope.transaction.fee

    $http.jsonp(target)
      .success( (data, status)->
        console.log data
        tx.unspent = JSON.parse(data.query.results.body.p)
        $scope.rawtx = JSON.stringify(tx)
        qrcode.renderQR(tx)

      )

    return true

  $scope.processForm = ()->

    console.log "processing form"
    $scope.loadUrl()


)


