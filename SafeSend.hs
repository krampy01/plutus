module Contracts.Samples.SafeSend where
import Jambhala.Plutus
import Jambhala.Utils

data SafeSendDatum = SafeSendDatum
  { receiverAddr :: PubKeyHash
   ,returnAddr :: PubKeyHash
   ,claimKey :: Integer
  }
  deriving (Generic, ToJSON, FromJSON)
unstableMakeIsData ''SafeSendDatum

newtype ClaimRedeemer = ClaimRedeemer Integer
unstableMakeIsData ''ClaimRedeemer


safeSendLambda :: SafeSendDatum -> ClaimRedeemer -> ScriptContext -> Bool
safeSendLambda (SafeSendDatum receiverAddr returnAddr claimKey) (ClaimRedeemer rKey) (ScriptContext txInfo _)
  | (txSignedBy txInfo receiverAddr) && claimKey #== rKey = True
  | (txSignedBy txInfo returnAddr) = True
  | otherwise = traceError "Error while claimng!"
{-# INLINEABLE safeSendLambda #-}

untypedLambda :: UntypedValidator
untypedLambda = mkUntypedValidator safeSendLambda
{-# INLINEABLE untypedLambda #-}

type SafeSend = ValidatorContract "safeSend"
compiledScript :: SafeSend
compiledScript = mkValidatorContract $$(compile [||untypedLambda||])

exports :: JambExports
exports =
  export
    (defExports compiledScript)
      { dataExports =
          [ SafeSendDatum
              { returnAddr = "72a5ed759f41494b755694348c507fafdc94721499bbb3cf7f76286b"
                ,receiverAddr = "47635906f786f855e7e350a506950519301d7693c2948454da6127db"
                ,claimKey = 1337
              }
              `toJSONfile` "safeSendDatum"
          ]
      , emulatorTest = test
      }

instance ValidatorEndpoints SafeSend where
  data GiveParam SafeSend = Give
    { lovelace :: Integer
    , withDatum :: SafeSendDatum
    }
    deriving (Generic, ToJSON, FromJSON)
  data GrabParam SafeSend = Grab {withClaim :: Integer}
    deriving (Generic, ToJSON, FromJSON)

  give :: GiveParam SafeSend -> ContractM SafeSend ()
  give (Give lovelace datum) = do
      submitAndConfirm
        Tx
          { lookups = scriptLookupsFor compiledScript
          , constraints = mustPayScriptWithDatum compiledScript datum (lovelaceValueOf lovelace)
          }
      logStr $ printf "Sent %d lovelace to %s!" lovelace (show $ receiverAddr datum)  

  grab :: GrabParam SafeSend -> ContractM SafeSend ()
  grab (Grab claimKey) = do
      pubKeyHash <- getOwnPKH
      scriptUtxos <- getUtxosAt compiledScript
      let claimUtxos = filterByDatum (\(SafeSendDatum receiverAddr _ datumClaimKey) -> (datumClaimKey == claimKey && receiverAddr == pubKeyHash)) scriptUtxos
      if claimUtxos == mempty
        then do
          let returnUtxos = filterByDatum (\(SafeSendDatum _ returnAddr _) -> (returnAddr == pubKeyHash)) scriptUtxos
          if returnUtxos == mempty
            then logStr "No utxo to claim!"
            else do
              submitAndConfirm
                Tx
                  { lookups = scriptLookupsFor compiledScript `andUtxos` returnUtxos
                  , constraints = mustSign pubKeyHash
                  }
              logStr "Returned!"
        else do
          submitAndConfirm
            Tx
                { lookups = scriptLookupsFor compiledScript `andUtxos` claimUtxos
                , constraints =
                    mconcat
                      [ mustSign pubKeyHash
                      , claimUtxos `mustAllBeSpentWith` ClaimRedeemer claimKey
                      ]
                }
          logStr "Claimed!"

test :: EmulatorTest
test =
  initEmulator @SafeSend
    3
    [ Give
        { lovelace = 40_000_000
        , withDatum =
            SafeSendDatum
              { returnAddr = pkhForWallet 1
              , receiverAddr = pkhForWallet 2
              , claimKey = 1337
              }
        }
        `fromWallet` 1
    , Give
        { lovelace = 40_000_000
        , withDatum =
            SafeSendDatum
              { returnAddr = pkhForWallet 3
              , receiverAddr = pkhForWallet 2
              , claimKey = 1337
              }
        }
        `fromWallet` 3
     , Grab {withClaim = 1000} `toWallet` 2 -- fail -> not a return adress and has not valid claim key
     , Grab {withClaim = 1000} `toWallet` 1 -- success -> valid return adress
     , Grab {withClaim = 1000} `toWallet` 2 -- fail -> wrong claim 
     , Grab {withClaim = 1337} `toWallet` 2 -- sucess -> correct receiver address and claim 
    ]