// Generated by CoffeeScript 1.5.0
(function() {
  var PageCtrl, app;

  app = angular.module("bitcoinSecured", []);

  app.factory("txevent", [
    '$window', function($window) {
      return {
        notify: function(msg) {
          return $window.alert(msg);
        },
        doTrans: function(tx_dest, tx_sec, tx_addr, tx_unspent) {
          var eckey, secret, sendTx, tx;
          secret = $window.Bitcoin.Base58.decode(tx_sec).slice(1, 33);
          eckey = new $window.Bitcoin.ECKey(secret);
          tx = new $window.TX(eckey);
          tx.parseInputs(tx_unspent, tx.getAddress());
          tx.addOutput(tx_dest, 0.1);
          sendTx = tx.construct();
          return console.log($window.Crypto.util.bytesToHex(sendTx.serialize()));
        }
      };
    }
  ]);

  app.factory("qrcode", [
    '$window', function($window) {
      return {
        renderQR: function(msg) {
          return $window.qr = new $window.QRCode($("#qr-code").get(0), msg);
        },
        hideQR: function() {
          return $window.qr.clear();
        }
      };
    }
  ]);

  app.controller("FormCtrl", PageCtrl = function($scope, $http, txevent) {
    $scope.rawtx = "";
    $scope.transaction = {};
    $scope.loadUrl = function() {
      var q, target, terminal, tx, url;
      q = "select * from html where url='http://blockchain.info/unspent?address=" + $scope.transaction.address + "'";
      url = "http://query.yahooapis.com/v1/public/yql?q=";
      terminal = "&format=json&callback=JSON_CALLBACK";
      target = url + encodeURIComponent(q) + terminal;
      tx = {};
      tx.dest = $scope.transaction.recipient;
      tx.addr = $scope.transaction.address;
      tx.amount = $scope.transaction.amount;
      tx.fee = $scope.transaction.fee;
      $http.jsonp(target).success(function(data, status) {
        console.log(data);
        tx.unspent = JSON.parse(data.query.results.body.p);
        $scope.rawtx = JSON.stringify(tx);
        return qrcode.renderQR(tx);
      });
      return true;
    };
    return $scope.processForm = function() {
      console.log("processing form");
      return $scope.loadUrl();
    };
  });

}).call(this);
