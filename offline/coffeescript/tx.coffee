root = exports ? this

class root.TX

  constructor: (eckey)->
    @inputs = []
    # @outputs = []
    @eckey = eckey
    @balance = 0

  # addOutput: (addr, fval) ->
  #   @outputs.push
  #     address: addr
  #     value: fval

  getBalance: ->
    @balance

  getAddress: ->
    @eckey.getBitcoinAddress().toString()

  parseInputs: (text, address) ->
    # try
    res = tx_parseBCI(text, address)
    # catch err
    #   console.log err
    @balance = res.balance
    @inputs = res.unspenttxs

  construct: (address, changeAddress, sendValue, feeValue)->

    sendValue = btcstr2bignum(sendValue)
    feeValue = btcstr2bignum(feeValue)

    selectedOuts = []
    txValue = sendValue.add(feeValue)
    availableValue = BigInteger.ZERO
    for hash of @inputs
      continue  unless @inputs.hasOwnProperty(hash)
      for index of @inputs[hash]
        continue  unless @inputs[hash].hasOwnProperty(index)
        script = parseScript(@inputs[hash][index].script)
        b64hash = Crypto.util.bytesToBase64(Crypto.util.hexToBytes(hash))
        txin = new Bitcoin.TransactionIn(
          outpoint:
            hash: b64hash
            index: index

          script: script
          sequence: 4294967295
        )
        selectedOuts.push txin
        availableValue = availableValue.add(new BigInteger("" + @inputs[hash][index].amount, 10))
        break if availableValue.compareTo(txValue) >= 0

    throw new Error("Insufficient funds.")  if availableValue.compareTo(txValue) < 0

    changeValue = availableValue.subtract(txValue)

    sendTx = new Bitcoin.Transaction()
    i = 0
    while i < selectedOuts.length
      sendTx.addInput selectedOuts[i]
      i++
    sendTx.addOutput(new Bitcoin.Address(address), sendValue)
    sendTx.addOutput(new Bitcoin.Address(changeAddress), changeValue) if changeValue.compareTo(BigInteger.ZERO) > 0

    hashType = 1
    i = 0
    while i < sendTx.ins.length
      connectedScript = selectedOuts[i].script
      hash = sendTx.hashTransactionForSignature(connectedScript, i, hashType)
      pubKeyHash = connectedScript.simpleOutPubKeyHash()
      signature = @eckey.sign(hash)
      signature.push parseInt(hashType, 10)
      pubKey = @eckey.getPub()
      script = new Bitcoin.Script()
      script.writeBytes signature
      script.writeBytes pubKey
      sendTx.ins[i].script = script
      i++
    sendTx

  deserialize: (bytes) ->
    sendTx = new Bitcoin.Transaction()
    f = bytes.slice(0)
    tx_ver = u32(f)
    vin_sz = readVarInt(f)
    return null  if errv(vin_sz)
    i = 0

    while i < vin_sz
      op = readBuffer(f, 32)
      n = u32(f)
      script = readString(f)
      seq = u32(f)
      txin = new Bitcoin.TransactionIn(
        outpoint:
          hash: Crypto.util.bytesToBase64(op)
          index: n

        script: new Bitcoin.Script(script)
        sequence: seq
      )
      sendTx.addInput txin
      i++
    vout_sz = readVarInt(f)
    return null  if errv(vout_sz)
    i = 0

    while i < vout_sz
      value = u64(f)
      script = readString(f)
      txout = new Bitcoin.TransactionOut(
        value: value
        script: new Bitcoin.Script(script)
      )
      sendTx.addOutput txout
      i++
    lock_time = u32(f)
    sendTx.lock_time = lock_time
    sendTx

isEmpty = (ob) ->
  for i of ob
    return false  if ob.hasOwnProperty(i)
  true

bignum2btcstr = (satoshi) ->
  s = String(satoshi)
  if satoshi >= 100000000
    i = s.length - 8
    s.substr(0, i) + "." + s.substr(i)
  else
    i = 8 - s.length
    "0." + Array(i + 1).join("0") + s

btcstr2bignum = (btc) ->
  i = btc.indexOf(".")
  value = new BigInteger(btc.replace(/\./, ""))
  diff = 9 - (btc.length - i)
  if i is -1
    mul = "100000000"
  else if diff < 0
    return value.divide(new BigInteger(Math.pow(10, -1 * diff).toString()))
  else
    mul = Math.pow(10, diff).toString()
  value.multiply new BigInteger(mul)

# Adapted from bitcoin-js base58.js Bitcoin.Base58.decode
priv2key = (privBase58) ->
  bytes = Bitcoin.Base58.decode(privBase58)
  hash = bytes.slice(0, 33)
  checksum = Crypto.SHA256(Crypto.SHA256(hash,
    asBytes: true
  ),
    asBytes: true
  )
  throw "Checksum validation failed!"  if checksum[0] isnt bytes[33] or checksum[1] isnt bytes[34] or checksum[2] isnt bytes[35] or checksum[3] isnt bytes[36]
  version = hash.shift()
  throw "Version " + version + " not supported!"  unless version is 0x80
  key = new Bitcoin.ECKey(hash)
  key

uint = (f, size) ->
  return 0  if f.length < size
  bytes = f.slice(0, size)
  pos = 1
  n = 0
  i = 0

  while i < size
    b = f.shift()
    n += b * pos
    pos *= 256
    i++
  (if size <= 4 then n else bytes)

u8 = (f) ->
  uint f, 1
u16 = (f) ->
  uint f, 2
u32 = (f) ->
  uint f, 4
u64 = (f) ->
  uint f, 8
errv = (val) ->
  val instanceof BigInteger or val > 0xffff

readBuffer = (f, size) ->
  res = f.slice(0, size)
  i = 0

  while i < size
    f.shift()
    i++
  res

readString = (f) ->
  len = readVarInt(f)
  return []  if errv(len)
  readBuffer f, len

readVarInt = (f) ->
  t = u8(f)
  if t is 0xfd
    u16 f
  else if t is 0xfe
    u32 f
  else if t is 0xff
    u64 f
  else
    t

dumpScript = (script) ->
  out = []
  i = 0

  while i < script.chunks.length
    chunk = script.chunks[i]
    op = new Bitcoin.Opcode(chunk)
    (if typeof chunk is "number" then out.push(op.toString()) else out.push(Crypto.util.bytesToHex(chunk)))
    i++
  out.join " "

# blockchain.info parser (adapted)
# uses http://blockchain.info/unspent?address=<address>
tx_parseBCI = (data, address) ->
  # r = JSON.parse(data)
  r = data
  txs = r.unspent_outputs
  throw "Not a BCI format"  unless txs
  delete unspenttxs
  unspenttxs = {}
  balance = BigInteger.ZERO
  for i of txs
    o = txs[i]
    lilendHash = o.tx_hash
    
    #convert script back to BBE-compatible text
    script = dumpScript(new Bitcoin.Script(Crypto.util.hexToBytes(o.script)))
    value = new BigInteger("" + o.value, 10)
    unspenttxs[lilendHash] = {}  unless lilendHash of unspenttxs
    unspenttxs[lilendHash][o.tx_output_n] =
      amount: value
      script: script

    balance = balance.add(value)

  return {balance: balance, unspenttxs: unspenttxs}

isEmpty = (ob) ->
  for i of ob
    return false  if ob.hasOwnProperty(i)
  true
endian = (string) ->
  out = []
  i = string.length

  while i > 0
    out.push string.substring(i - 2, i)
    i -= 2
  out.join ""

btcstr2bignum = (btc) ->
  i = btc.indexOf(".")
  value = new BigInteger(btc.replace(/\./, ""))
  diff = 9 - (btc.length - i)
  if i is -1
    mul = "100000000"
  else if diff < 0
    return value.divide(new BigInteger(Math.pow(10, -1 * diff).toString()))
  else
    mul = Math.pow(10, diff).toString()
  value.multiply new BigInteger(mul)

parseScript = (script) ->
  newScript = new Bitcoin.Script()
  s = script.split(" ")
  for i of s
    if Bitcoin.Opcode.map.hasOwnProperty(s[i])
      newScript.writeOp Bitcoin.Opcode.map[s[i]]
    else
      newScript.writeBytes Crypto.util.hexToBytes(s[i])
  newScript



