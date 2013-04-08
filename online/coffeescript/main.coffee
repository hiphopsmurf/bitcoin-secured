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
      )

    return true

  $scope.processForm = ()->

    console.log "processing form"
    $scope.loadUrl()

  $scope.doTransaction = ()->
    tx_dest = "17Ww5bR6NGAk4AfhsDWAwHgjHRacemLcwV"
    tx_sec = "5HvkAaBtux2M2uuxUYMFeo9RSD4N9eW5DHqAHN2Z71qU7x9KPd7"
    tx_addr = "16FPmNu2tFfpN4yXKScGEA7FVpm4grkxd7"
    tx_unspent = """
        {
           
          "unspent_outputs":[
          
            {
              "tx_hash":"dc1bd19bad9da9e14cc2f685fea52a9a10fba4712f057dcc6c1d512e9658ed9a",
              "tx_index":64224712,
              "tx_output_n": 1,
              "script": "76a914399174ac8475f1e6e65c452fa85ce13755b2a1aa88ac",
              "value": 4000000,
              "value_hex": "3d0900",
              "confirmations": 611
            },
            
            {
              "tx_hash":"16407c175b2e5bd0090eef4d542aba15def27c13f16e819a594df4f6123e88d1",
              "tx_index":65018229,
              "tx_output_n": 1, 
              "script":"76a914399174ac8475f1e6e65c452fa85ce13755b2a1aa88ac",
              "value": 6680000,
              "value_hex": "65edc0",
              "confirmations":0
            }
            
          ]
        }
        """

    txevent.doTrans(tx_dest, tx_sec, tx_addr, tx_unspent)
    # txevent.notify("hi there")


  $scope.doTransaction()

)


