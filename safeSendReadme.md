This script is simple idea of "safe" send. You can send ADA to adress and it can be claimed with "secret" key. But if something goes wrong for example you spedified wrong receiver adress then you can recover the funds yourself and not loose it.

1. Example locking value in script and claiming it by receiver specified in datum.
Send (lock value at script address)

cardano-cli address build \
--payment-script-file $PLUTUS_SCRIPTS_PATH/safeSend.plutus \ 
--out-file $ADDR_PATH/safeSend.addr

cardano-cli transaction build \
--tx-in 0b152ab8520421a9fc0cb80c81e09115c950974697605e001d029ffd045f9b43#1 \
--tx-out $(addr safeSend)+3000000 \
--tx-out-datum-hash-file $DATA_PATH/safeSendDatum.json \
--change-address $(addr testAddr) \
--out-file $TX_PATH/safeSend-lock-h.raw

ardano-cli transaction sign \
--tx-body-file $TX_PATH/safeSend-lock-h.raw \
--signing-key-file $KEYS_PATH/testAddr.skey \
--out-file $TX_PATH/safeSend-lock-h.signed

cardano-cli transaction submit \
--tx-file "$TX_PATH/safeSend-lock-h.signed"


Unlock:
cardano-cli transaction build \
--tx-in 42260c60821f578143eebd1e1d8cb4470a778d71ea5bc8f643e5594a9899c0dc#0 \
--tx-in-script-file $PLUTUS_SCRIPTS_PATH/safeSend.plutus \
--tx-in-datum-file $DATA_PATH/safeSendDatum.json \
--tx-in-redeemer-file $DATA_PATH/safeSendRedeemer.json \
--tx-in-collateral 9884a0065e19786875659a487a09efd8326a88f0869fb504ed8616e8780f08b1#0 \
--change-address $(addr testAddr2) \
--required-signer-hash 47635906f786f855e7e350a506950519301d7693c2948454da6127db --out-file $TX_PATH/safeSend-unlock-h.raw
Estimated transaction fee: Lovelace 315906

cardano-cli transaction sign \  
--tx-body-file $TX_PATH/safeSend-unlock-h.raw \                             
--signing-key-file $KEYS_PATH/testAddr2.skey \
--out-file $TX_PATH/safeSend-unlock-h.signed

cardano-cli transaction submit \
--tx-file "$TX_PATH/safeSend-unlock-h.signed"                               

2. Example is about locking funds at script adress but instead of claiming it with receiver its recovered by original sender.
Lock2: 
cardano-cli transaction build \
--tx-in 42260c60821f578143eebd1e1d8cb4470a778d71ea5bc8f643e5594a9899c0dc#1 \
--tx-out $(addr safeSend)+3000000 \
--tx-out-datum-hash-file $DATA_PATH/safeSendDatum.json \
--change-address $(addr testAddr) \
--out-file $TX_PATH/safeSend2-lock-h.raw
Estimated transaction fee: Lovelace 167349

ardano-cli transaction sign \                                            
--tx-body-file $TX_PATH/safeSend2-lock-h.raw \                                         
--signing-key-file $KEYS_PATH/testAddr.skey \
--out-file $TX_PATH/safeSend2-lock-h.signed

cardano-cli transaction submit \
--tx-file "$TX_PATH/safeSend2-lock-h.signed"
Transaction successfully submitted.

Unlock 2:

cardano-cli transaction build \
--tx-in 260f2523f7772ec006c3dbc847371ec483cae895a8fd593e6f2ad29376b6f8e4#0 \
--tx-in-script-file $PLUTUS_SCRIPTS_PATH/safeSend.plutus \
--tx-in-datum-file $DATA_PATH/safeSendDatum.json \
--tx-in-redeemer-file $DATA_PATH/safeSendRedeemerZero.json \
--tx-in-collateral 260f2523f7772ec006c3dbc847371ec483cae895a8fd593e6f2ad29376b6f8e4#1 \
--change-address $(addr testAddr) \
--required-signer-hash 72a5ed759f41494b755694348c507fafdc94721499bbb3cf7f76286b --out-file $TX_PATH/safeSend2-unlock-h.raw

cardano-cli transaction sign \
--tx-body-file $TX_PATH/safeSend2-unlock-h.raw \
--signing-key-file $KEYS_PATH/testAddr.skey \
--out-file $TX_PATH/safeSend2-unlock-h.signed

cardano-cli transaction submit \
--tx-file "$TX_PATH/safeSend2-unlock-h.signed"