--  This Source Code Form is subject to the terms of the Mozilla Public
--  License, v. 2.0. If a copy of the MPL was not distributed with this
--  file, You can obtain one at http://mozilla.org/MPL/2.0/.

{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE UndecidableInstances #-}

{-# OPTIONS_GHC -fno-warn-orphans #-}

module Kupo.Data.Cardano
    ( -- * Constraints
      Crypto
    , StandardCrypto

      -- * Block
    , IsBlock (..)
    , Block

      -- * Transaction
    , Transaction

      -- * TransactionId
    , TransactionId
    , transactionIdToText
    , transactionIdFromHash
    , unsafeTransactionIdFromBytes
    , getTransactionId
    , transactionIdToJson

      -- * OutputIndex
    , OutputIndex
    , getOutputIndex
    , outputIndexToJson

      -- * Input
    , Input
    , OutputReference
    , mkOutputReference
    , withReferences

      -- * Output
    , Output
    , mkOutput
    , getAddress
    , getDatum
    , getValue

    -- * Value
    , Value
    , hasAssetId
    , hasPolicyId
    , unsafeValueFromList
    , valueToJson
    , assetNameMaxLength

    -- * AssetId
    , AssetId

    -- * PolicyId
    , PolicyId
    , unsafePolicyIdFromBytes
    , policyIdFromText
    , policyIdToText

    -- * AssetName
    , AssetName
    , unsafeAssetNameFromBytes
    , assetNameFromText
    , assetNameToText

    -- * Datum
    , Datum
    , getBinaryData
    , fromBinaryData
    , fromDatumHash
    , noDatum
    , hashDatum

    -- * DatumHash
    , DatumHash
    , datumHashFromText
    , datumHashToText
    , datumHashFromBytes
    , unsafeDatumHashFromBytes
    , datumHashToJson

    -- * BinaryData
    , BinaryData
    , hashBinaryData
    , binaryDataToJson
    , binaryDataFromBytes
    , unsafeBinaryDataFromBytes

      -- * Address
    , Address
    , addressFromBytes
    , addressToJson
    , addressToBytes
    , isBootstrap
    , getPaymentPartBytes
    , getDelegationPartBytes

      -- * BlockNo
    , BlockNo(..)

      -- * SlotNo
    , SlotNo (..)
    , slotNoFromText
    , slotNoToText
    , slotNoToJson
    , distanceToSlot

      -- * Hash
    , digest
    , digestSize
    , Blake2b_224
    , Blake2b_256
    , Ledger.unsafeMakeSafeHash

      -- * HeaderHash
    , HeaderHash
    , headerHashFromText
    , headerHashToJson
    , unsafeHeaderHashFromBytes

      -- * Point
    , Point (Point)
    , pointFromText
    , pointToJson
    , getPointSlotNo
    , getPointHeaderHash
    , unsafeGetPointHeaderHash
    , pattern GenesisPoint
    , pattern BlockPoint

      -- * Tip
    , Tip (..)
    , getTipSlotNo
    , distanceToTip

      -- * WithOrigin
    , WithOrigin (..)
    ) where

import Kupo.Prelude

import Cardano.Crypto.Hash
    ( Blake2b_224
    , Blake2b_256
    , Hash
    , HashAlgorithm (..)
    , pattern UnsafeHash
    , hashFromTextAsHex
    , hashToBytesShort
    , sizeHash
    )
import Cardano.Ledger.Allegra
    ( AllegraEra )
import Cardano.Ledger.Alonzo
    ( AlonzoEra )
import Cardano.Ledger.Babbage
    ( BabbageEra )
import Cardano.Ledger.Crypto
    ( Crypto, StandardCrypto )
import Cardano.Ledger.Mary
    ( MaryEra )
import Cardano.Ledger.Shelley
    ( ShelleyEra )
import Cardano.Ledger.Val
    ( Val (inject) )
import Cardano.Slotting.Block
    ( BlockNo (..) )
import Cardano.Slotting.Slot
    ( SlotNo (..) )
import Data.Binary.Put
    ( runPut )
import Data.ByteString.Bech32
    ( HumanReadablePart (..), encodeBech32 )
import Data.Maybe.Strict
    ( StrictMaybe (..), strictMaybeToMaybe )
import Data.Sequence.Strict
    ( pattern (:<|), pattern Empty, StrictSeq )
import GHC.Records
    ( HasField (..) )
import Ouroboros.Consensus.Block
    ( ConvertRawHash (..) )
import Ouroboros.Consensus.Byron.Ledger.Mempool
    ( GenTx (..) )
import Ouroboros.Consensus.Cardano.Block
    ( CardanoBlock, HardForkBlock (..) )
import Ouroboros.Consensus.HardFork.Combinator
    ( OneEraHash (..) )
import Ouroboros.Consensus.Ledger.SupportsMempool
    ( HasTxs (extractTxs) )
import Ouroboros.Consensus.Shelley.Ledger.Block
    ( ShelleyBlock (..) )
import Ouroboros.Consensus.Util
    ( eitherToMaybe )
import Ouroboros.Network.Block
    ( pattern BlockPoint
    , pattern GenesisPoint
    , HeaderHash
    , Point (Point)
    , Tip (..)
    , blockPoint
    , pointSlot
    )
import Ouroboros.Network.Point
    ( WithOrigin (..) )

import Ouroboros.Consensus.Cardano
    ()
import Ouroboros.Consensus.Protocol.Praos.Translate
    ()
import Ouroboros.Consensus.Shelley.Ledger.SupportsProtocol
    ()

import qualified Cardano.Chain.Common as Ledger.Byron
import qualified Cardano.Chain.UTxO as Ledger.Byron
import qualified Cardano.Crypto as Ledger.Byron
import qualified Cardano.Ledger.Address as Ledger
import qualified Cardano.Ledger.Alonzo.Data as Ledger
import qualified Cardano.Ledger.Alonzo.Tx as Ledger.Alonzo
import qualified Cardano.Ledger.Alonzo.TxBody as Ledger.Alonzo
import qualified Cardano.Ledger.Alonzo.TxSeq as Ledger.Alonzo
import qualified Cardano.Ledger.Alonzo.TxWitness as Ledger
import qualified Cardano.Ledger.Babbage.TxBody as Ledger.Babbage
import qualified Cardano.Ledger.BaseTypes as Ledger
import qualified Cardano.Ledger.Block as Ledger
import qualified Cardano.Ledger.Core as Ledger.Core
import qualified Cardano.Ledger.Credential as Ledger
import qualified Cardano.Ledger.Era as Ledger.Era
import qualified Cardano.Ledger.Hashes as Ledger
import qualified Cardano.Ledger.Mary.Value as Ledger
import qualified Cardano.Ledger.SafeHash as Ledger
import qualified Cardano.Ledger.Shelley.API as Ledger
import qualified Cardano.Ledger.Shelley.BlockChain as Ledger.Shelley
import qualified Cardano.Ledger.Shelley.Tx as Ledger.Shelley
import qualified Cardano.Ledger.ShelleyMA.TxBody as Ledger.MaryAllegra
import qualified Cardano.Ledger.TxIn as Ledger
import qualified Data.Aeson.Encoding as Json
import qualified Data.Aeson.Key as Json
import qualified Data.ByteString as BS
import qualified Data.ByteString.Short as SBS
import qualified Data.Map as Map
import qualified Data.Set as Set
import qualified Data.Text as T
import qualified Data.Text.Read as T
import qualified Ouroboros.Network.Block as Ouroboros

-- IsBlock

class IsBlock (block :: Type) where
    type BlockBody block :: Type

    getPoint
        :: block
        -> Point Block

    foldBlock
        :: (BlockBody block -> result -> result)
        -> result
        -> block
        -> result

    spentInputs
        :: BlockBody block
        -> Set Input

    mapMaybeOutputs
        :: (OutputReference -> Output -> Maybe result)
        -> BlockBody block
        -> [result]

    witnessedDatums
        :: BlockBody block
        -> Map DatumHash BinaryData

-- Block

type Block =
    Block' StandardCrypto

type Block' crypto =
    CardanoBlock crypto

instance IsBlock Block where
    type BlockBody Block = Transaction

    getPoint
        :: Block
        -> Point Block
    getPoint =
        blockPoint

    foldBlock
        :: (Transaction -> result -> result)
        -> result
        -> Block
        -> result
    foldBlock fn result = \case
        BlockByron blk ->
            let ignoreProtocolTxs = \case
                    ByronTx txId (Ledger.Byron.taTx -> tx) ->
                        fn (TransactionByron tx txId)
                    _ ->
                        identity
             in foldr ignoreProtocolTxs result (extractTxs blk)
        BlockShelley (ShelleyBlock (Ledger.Block _ txs) _) ->
            foldr (fn . TransactionShelley) result (Ledger.Shelley.txSeqTxns' txs)
        BlockAllegra (ShelleyBlock (Ledger.Block _ txs) _) ->
            foldr (fn . TransactionAllegra) result (Ledger.Shelley.txSeqTxns' txs)
        BlockMary (ShelleyBlock (Ledger.Block _ txs) _) ->
            foldr (fn . TransactionMary) result (Ledger.Shelley.txSeqTxns' txs)
        BlockAlonzo (ShelleyBlock (Ledger.Block _ txs) _) ->
            foldr (fn . TransactionAlonzo) result (Ledger.Alonzo.txSeqTxns txs)
        BlockBabbage (ShelleyBlock (Ledger.Block _ txs) _) ->
            foldr (fn . TransactionBabbage) result (Ledger.Alonzo.txSeqTxns txs)

    spentInputs
        :: Transaction
        -> Set Input
    spentInputs = \case
        TransactionByron tx _ ->
            foldr (Set.insert . transformByron) Set.empty (Ledger.Byron.txInputs tx)
        TransactionShelley tx ->
            getField @"inputs" (getField @"body" tx)
        TransactionAllegra tx ->
            getField @"inputs" (getField @"body" tx)
        TransactionMary tx ->
            getField @"inputs" (getField @"body" tx)
        TransactionAlonzo tx ->
            case Ledger.Alonzo.isValid tx of
                Ledger.Alonzo.IsValid True ->
                    getField @"inputs" (getField @"body" tx)
                Ledger.Alonzo.IsValid False ->
                    getField @"collateral" (getField @"body" tx)
        TransactionBabbage tx ->
            case Ledger.Alonzo.isValid tx of
                Ledger.Alonzo.IsValid True ->
                    getField @"inputs" (getField @"body" tx)
                Ledger.Alonzo.IsValid False ->
                    getField @"collateral" (getField @"body" tx)
      where
        transformByron (Ledger.Byron.TxInUtxo txId ix) =
            mkOutputReference
                (transactionIdFromByron txId)
                (fromIntegral @Word16 @Word64 ix)

    mapMaybeOutputs
        :: forall result. ()
        => (OutputReference -> Output -> Maybe result)
        -> Transaction
        -> [result]
    mapMaybeOutputs fn = \case
        TransactionByron tx (transactionIdFromByron -> txId) ->
            let
                out :| outs = Ledger.Byron.txOutputs tx
             in
                traverseAndTransformByron fromByronOutput txId 0 (out : outs)
        TransactionShelley tx ->
            let
                body = Ledger.Shelley.body tx
                txId = Ledger.txid @(ShelleyEra StandardCrypto) body
                outs = Ledger.Shelley._outputs body
             in
                traverseAndTransform (fromShelleyOutput inject) txId 0 outs
        TransactionAllegra tx ->
            let
                body = Ledger.Shelley.body tx
                txId = Ledger.txid @(AllegraEra StandardCrypto) body
                outs = Ledger.MaryAllegra.outputs' body
             in
                traverseAndTransform (fromShelleyOutput inject) txId 0 outs
        TransactionMary tx ->
            let
                body = Ledger.Shelley.body tx
                txId = Ledger.txid @(MaryEra StandardCrypto) body
                outs = Ledger.MaryAllegra.outputs' body
             in
                traverseAndTransform (fromShelleyOutput identity) txId 0 outs
        TransactionAlonzo tx ->
            let
                body = Ledger.Alonzo.body tx
                txId = Ledger.txid @(AlonzoEra StandardCrypto) body
                outs = Ledger.Alonzo.outputs' body
             in
                case Ledger.Alonzo.isValid tx of
                    Ledger.Alonzo.IsValid True ->
                        traverseAndTransform fromAlonzoOutput txId 0 outs
                    _ ->
                        []
        TransactionBabbage tx ->
            let
                body = Ledger.Alonzo.body tx
                txId = Ledger.txid @(BabbageEra StandardCrypto) body
                outs = Ledger.Babbage.outputs' body
             in
                case Ledger.Alonzo.isValid tx of
                    Ledger.Alonzo.IsValid True ->
                        traverseAndTransform identity txId 0 outs
                    _ ->
                        []
      where
        traverseAndTransformByron
            :: forall output. ()
            => (output -> Output)
            -> TransactionId
            -> OutputIndex
            -> [output]
            -> [result]
        traverseAndTransformByron transform txId ix = \case
            [] -> []
            (out:rest) ->
                let
                    outputRef = mkOutputReference txId ix
                    results   = traverseAndTransformByron transform txId (succ ix) rest
                 in
                    case fn outputRef (transform out) of
                        Nothing ->
                            results
                        Just result ->
                            result : results

        traverseAndTransform
            :: forall output. ()
            => (output -> Output)
            -> TransactionId
            -> OutputIndex
            -> StrictSeq output
            -> [result]
        traverseAndTransform transform txId ix = \case
            Empty -> []
            output :<| rest ->
                let
                    outputRef = mkOutputReference txId ix
                    results   = traverseAndTransform transform txId (succ ix) rest
                 in
                    case fn outputRef (transform output) of
                        Nothing ->
                            results
                        Just result ->
                            result : results

    witnessedDatums
        :: Transaction
        -> Map DatumHash BinaryData
    witnessedDatums = \case
        TransactionByron{} ->
            mempty
        TransactionShelley{} ->
            mempty
        TransactionAllegra{} ->
            mempty
        TransactionMary{} ->
            mempty
        TransactionAlonzo tx ->
            fromAlonzoData <$>
                Ledger.unTxDats (getField @"txdats" (getField @"wits" tx))
        TransactionBabbage tx ->
            fromBabbageData <$>
                Ledger.unTxDats (getField @"txdats" (getField @"wits" tx))

-- TransactionId

type TransactionId =
    TransactionId' StandardCrypto

type TransactionId' crypto =
    Ledger.TxId crypto

transactionIdFromByron
    :: Ledger.Byron.TxId
    -> TransactionId
transactionIdFromByron (Ledger.Byron.hashToBytes -> bytes) =
    Ledger.TxId (Ledger.unsafeMakeSafeHash (UnsafeHash (toShort bytes)))

transactionIdFromHash
    :: Hash Blake2b_256 Ledger.EraIndependentTxBody
    -> TransactionId
transactionIdFromHash =
    Ledger.TxId . Ledger.unsafeMakeSafeHash

unsafeTransactionIdFromBytes
    :: HasCallStack
    => ByteString
    -> TransactionId
unsafeTransactionIdFromBytes =
    transactionIdFromHash
    . UnsafeHash
    . toShort
    . sizeInvariant (== (digestSize @Blake2b_256))

class HasTransactionId f where
    getTransactionId
        :: forall crypto. (Crypto crypto)
        => f crypto
        -> TransactionId' crypto

transactionIdToText :: TransactionId -> Text
transactionIdToText =
    encodeBase16 . (\(UnsafeHash h) -> fromShort h) . Ledger.extractHash . Ledger._unTxId

transactionIdToJson :: TransactionId -> Json.Encoding
transactionIdToJson =
    hashToJson . Ledger.extractHash . Ledger._unTxId

-- OutputIndex

type OutputIndex = Word64

getOutputIndex :: OutputReference' crypto -> OutputIndex
getOutputIndex (Ledger.TxIn _ (Ledger.TxIx ix)) =
    ix

outputIndexToJson :: OutputIndex -> Json.Encoding
outputIndexToJson =
    Json.integer . toInteger

-- Transaction

type Transaction = Transaction' StandardCrypto

data Transaction' crypto
    = TransactionByron
        Ledger.Byron.Tx
        Ledger.Byron.TxId
    | TransactionShelley
        (Ledger.Shelley.Tx (ShelleyEra crypto))
    | TransactionAllegra
        (Ledger.Shelley.Tx (AllegraEra crypto))
    | TransactionMary
        (Ledger.Shelley.Tx (MaryEra crypto))
    | TransactionAlonzo
        (Ledger.Alonzo.ValidatedTx (AlonzoEra crypto))
    | TransactionBabbage
        (Ledger.Alonzo.ValidatedTx (BabbageEra crypto))

-- Input

type Input =
    Input' StandardCrypto

type Input' crypto =
    Ledger.TxIn crypto

-- OutputReference

type OutputReference =
    OutputReference' StandardCrypto

type OutputReference' crypto =
    Input' crypto

mkOutputReference
    :: TransactionId
    -> OutputIndex
    -> OutputReference
mkOutputReference i =
    Ledger.TxIn i . Ledger.TxIx

withReferences
    :: TransactionId
    -> [Output]
    -> [(OutputReference, Output)]
withReferences txId = loop 0
  where
    loop ix = \case
        [] -> []
        out:rest ->
            let
                results = loop (succ ix) rest
             in
                (mkOutputReference txId ix, out) : results

instance HasTransactionId Ledger.TxIn where
    getTransactionId (Ledger.TxIn i _) = i

-- Output

type Output =
    Output' StandardCrypto

type Output' crypto =
    Ledger.Babbage.TxOut (BabbageEra crypto)

mkOutput
    :: Address
    -> Value
    -> Datum
    -> Output
mkOutput address value datum =
    Ledger.Babbage.TxOut
        address
        value
        datum
        SNothing

fromShelleyOutput
    :: forall (era :: Type -> Type) crypto.
        ( Ledger.Era.Era (era crypto)
        , Ledger.Era.Crypto (era crypto) ~ crypto
        , Ledger.Core.TxOut (era crypto) ~ Ledger.Shelley.TxOut (era crypto)
        , Show (Ledger.Core.Value (era crypto))
        )
    => (Ledger.Core.Value (era crypto) -> Ledger.Value crypto)
    -> Ledger.Core.TxOut (era crypto)
    -> Ledger.Core.TxOut (BabbageEra crypto)
fromShelleyOutput liftValue (Ledger.Shelley.TxOut addr value) =
    Ledger.Babbage.TxOut addr (liftValue value) Ledger.Babbage.NoDatum SNothing

fromAlonzoOutput
    :: forall crypto.
        ( Crypto crypto
        )
    => Ledger.Core.TxOut (AlonzoEra crypto)
    -> Ledger.Core.TxOut (BabbageEra crypto)
fromAlonzoOutput (Ledger.Alonzo.TxOut addr value datum) =
    case datum of
        SNothing ->
            Ledger.Babbage.TxOut
                addr
                value
                Ledger.Babbage.NoDatum
                SNothing

        SJust datumHash ->
            Ledger.Babbage.TxOut
                addr
                value
                (Ledger.Babbage.DatumHash datumHash)
                SNothing


fromByronOutput
    :: forall crypto.
        ( Crypto crypto
        )
    => Ledger.Byron.TxOut
    -> Ledger.Core.TxOut (BabbageEra crypto)
fromByronOutput (Ledger.Byron.TxOut address value) =
    Ledger.Babbage.TxOut
        (Ledger.AddrBootstrap (Ledger.BootstrapAddress address))
        (inject $ Ledger.Coin $ toInteger $ Ledger.Byron.unsafeGetLovelace value)
        Ledger.Babbage.NoDatum
        SNothing

getAddress
    :: Output
    -> Address
getAddress (Ledger.Babbage.TxOut address _value _datum _refScript) =
    address

getValue
    :: Output
    -> Value
getValue (Ledger.Babbage.TxOut _address value _datum _refScript) =
    value

getDatum
    :: Output
    -> Datum
getDatum (Ledger.Babbage.TxOut _address _value datum _refScript) =
    datum

-- Datum

type Datum =
    Ledger.Datum (BabbageEra StandardCrypto)

getBinaryData
    :: Datum
    -> Maybe BinaryData
getBinaryData = \case
    Ledger.Datum bin -> Just bin
    Ledger.NoDatum -> Nothing
    Ledger.DatumHash{} -> Nothing

noDatum
    :: Datum
noDatum =
    Ledger.NoDatum

fromDatumHash
    :: DatumHash
    -> Datum
fromDatumHash =
    Ledger.DatumHash

fromBinaryData
    :: BinaryData
    -> Datum
fromBinaryData =
    Ledger.Datum

hashDatum
    :: Datum
    -> Maybe DatumHash
hashDatum =
    strictMaybeToMaybe . Ledger.datumDataHash

-- DatumHash

type DatumHash =
    DatumHash' StandardCrypto

type DatumHash' crypto =
    Ledger.DataHash crypto

datumHashFromBytes
    :: ByteString
    -> Maybe DatumHash
datumHashFromBytes bytes
    | BS.length bytes == (digestSize @Blake2b_256) =
        Just (unsafeDatumHashFromBytes bytes)
    | otherwise =
        Nothing

datumHashToText
    :: DatumHash
    -> Text
datumHashToText =
    encodeBase16 . Ledger.originalBytes

datumHashFromText
    :: Text
    -> Maybe DatumHash
datumHashFromText str =
    case datumHashFromBytes <$> decodeBase16 (encodeUtf8 str) of
        Right (Just hash) -> Just hash
        _ -> Nothing

unsafeDatumHashFromBytes
    :: forall crypto.
        ( HasCallStack
        , Crypto crypto
        )
    => ByteString
    -> DatumHash' crypto
unsafeDatumHashFromBytes =
    Ledger.unsafeMakeSafeHash
    . UnsafeHash
    . toShort
    . sizeInvariant (== (digestSize @Blake2b_256))

datumHashToJson
    :: DatumHash
    -> Json.Encoding
datumHashToJson =
    hashToJson . Ledger.extractHash

-- BinaryData

type BinaryData =
    Ledger.BinaryData (BabbageEra StandardCrypto)

type BinaryDataHash =
    DatumHash

hashBinaryData
    :: BinaryData
    -> BinaryDataHash
hashBinaryData  =
    Ledger.hashBinaryData

binaryDataToJson
    :: BinaryData
    -> Json.Encoding
binaryDataToJson =
    Json.text . encodeBase16 . Ledger.originalBytes

binaryDataFromBytes
    :: ByteString
    -> Maybe BinaryData
binaryDataFromBytes =
    either (const Nothing) Just . Ledger.makeBinaryData . toShort

unsafeBinaryDataFromBytes
    :: HasCallStack
    => ByteString
    -> BinaryData
unsafeBinaryDataFromBytes =
    either (error . toText) identity . Ledger.makeBinaryData . toShort

fromAlonzoData
    :: Ledger.Data (AlonzoEra StandardCrypto)
    -> BinaryData
fromAlonzoData =
    Ledger.dataToBinaryData . coerce

fromBabbageData
    :: Ledger.Data (BabbageEra StandardCrypto)
    -> BinaryData
fromBabbageData =
    Ledger.dataToBinaryData

-- Value

type Value =
    Value' StandardCrypto

type Value' crypto =
    Ledger.Value crypto

hasAssetId :: Value -> AssetId -> Bool
hasAssetId value (policyId, assetName) =
    Ledger.lookup policyId assetName value > 0

hasPolicyId :: Value -> PolicyId -> Bool
hasPolicyId value policyId =
    policyId `Set.member` Ledger.policies value

unsafeValueFromList
    :: Integer
    -> [(ByteString, ByteString, Integer)]
    -> Value
unsafeValueFromList ada assets =
    Ledger.valueFromList
        ada
        [ ( unsafePolicyIdFromBytes pid, unsafeAssetNameFromBytes name, q)
        | (pid, name, q) <- assets
        ]

valueToJson :: Value -> Json.Encoding
valueToJson (Ledger.Value coins assets) = Json.pairs $ mconcat
    [ Json.pair "coins"  (Json.integer coins)
    , Json.pair "assets" (assetsToJson assets)
    ]
  where
    assetsToJson :: Map (Ledger.PolicyID StandardCrypto) (Map Ledger.AssetName Integer) -> Json.Encoding
    assetsToJson =
        Json.pairs
        .
        Map.foldrWithKey
            (\k v r -> Json.pair (assetIdToKey k) (Json.integer v) <> r)
            mempty
        .
        flatten

    flatten :: (Ord k1, Ord k2) => Map k1 (Map k2 a) -> Map (k1, k2) a
    flatten = Map.foldrWithKey
        (\k inner -> Map.union (Map.mapKeys (k,) inner))
        mempty

    assetIdToKey :: (Ledger.PolicyID StandardCrypto, Ledger.AssetName) -> Json.Key
    assetIdToKey (Ledger.PolicyID (Ledger.ScriptHash (UnsafeHash pid)), Ledger.AssetName bytes)
        | SBS.null bytes = Json.fromText
            (encodeBase16 (fromShort pid))
        | otherwise     = Json.fromText
            (encodeBase16 (fromShort pid) <> "." <> encodeBase16 (fromShort bytes))

-- AssetId

type AssetId = (PolicyId, Ledger.AssetName)

-- PolicyId

type PolicyId = Ledger.PolicyID StandardCrypto

unsafePolicyIdFromBytes :: ByteString -> PolicyId
unsafePolicyIdFromBytes =
    Ledger.PolicyID
    . Ledger.ScriptHash
    . UnsafeHash
    . toShort
    . sizeInvariant (== (digestSize @Blake2b_224))

policyIdFromText :: Text -> Maybe PolicyId
policyIdFromText (encodeUtf8 -> bytes) = do
    -- NOTE: assuming base16 encoding, hence '2 *'
    guard (BS.length bytes == 2 * digestSize @Blake2b_224)
    unsafePolicyIdFromBytes <$> eitherToMaybe (decodeBase16 bytes)

policyIdToText :: PolicyId -> Text
policyIdToText (Ledger.PolicyID (Ledger.ScriptHash (UnsafeHash scriptHash))) =
    encodeBase16 (fromShort scriptHash)

-- AssetName

type AssetName = Ledger.AssetName

assetNameMaxLength :: Int
assetNameMaxLength = 32

unsafeAssetNameFromBytes :: ByteString -> Ledger.AssetName
unsafeAssetNameFromBytes =
    Ledger.AssetName
    . toShort
    . sizeInvariant (<= assetNameMaxLength)

assetNameFromText :: Text -> Maybe AssetName
assetNameFromText (encodeUtf8 -> bytes) = do
    -- NOTE: assuming base16 encoding, hence '2 *'
    guard (BS.length bytes <= 2 * assetNameMaxLength)
    unsafeAssetNameFromBytes <$> eitherToMaybe (decodeBase16 bytes)

assetNameToText :: AssetName -> Text
assetNameToText (Ledger.AssetName assetName) =
    encodeBase16 (fromShort assetName)

-- Address

type Address =
    Address' StandardCrypto

type Address' crypto =
    Ledger.Addr crypto

addressToJson :: Address -> Json.Encoding
addressToJson = \case
    addr@Ledger.AddrBootstrap{} ->
        (Json.text . encodeBase58 . addressToBytes) addr
    addr@(Ledger.Addr network _ _) ->
        (Json.text . encodeBech32 (hrp network) . addressToBytes) addr
  where
    hrp = \case
        Ledger.Mainnet -> HumanReadablePart "addr"
        Ledger.Testnet -> HumanReadablePart "addr_test"

addressToBytes :: Address -> ByteString
addressToBytes = Ledger.serialiseAddr
{-# INLINEABLE addressToBytes #-}

addressFromBytes :: ByteString -> Maybe Address
addressFromBytes = Ledger.deserialiseAddr
{-# INLINEABLE addressFromBytes #-}

isBootstrap :: Address -> Bool
isBootstrap = \case
    Ledger.AddrBootstrap{} -> True
    Ledger.Addr{} -> False
{-# INLINEABLE isBootstrap #-}

getPaymentPartBytes :: Address -> Maybe ByteString
getPaymentPartBytes = \case
    Ledger.Addr _ payment _ ->
        Just $ toStrict $ runPut $ Ledger.putCredential payment
    Ledger.AddrBootstrap{} ->
        Nothing

getDelegationPartBytes :: Address -> Maybe ByteString
getDelegationPartBytes = \case
    Ledger.Addr _ _ (Ledger.StakeRefBase delegation) ->
        Just $ toStrict $ runPut $ Ledger.putCredential delegation
    Ledger.Addr{} ->
        Nothing
    Ledger.AddrBootstrap{} ->
        Nothing

-- HeaderHash

-- | Deserialise a 'HeaderHash' from a base16-encoded text string.
headerHashFromText
    :: Text
    -> Maybe (HeaderHash Block)
headerHashFromText =
    fmap (OneEraHash . hashToBytesShort) . hashFromTextAsHex @Blake2b_256

headerHashToJson
    :: HeaderHash Block
    -> Json.Encoding
headerHashToJson =
    byteStringToJson . fromShort . toShortRawHash (Proxy @Block)

unsafeHeaderHashFromBytes
    :: ByteString
    -> HeaderHash Block
unsafeHeaderHashFromBytes =
    fromRawHash (Proxy @Block)

-- Tip

getTipSlotNo :: Tip Block -> SlotNo
getTipSlotNo tip =
    case Ouroboros.getTipSlotNo tip of
        Origin -> SlotNo 0
        At sl  -> sl

distanceToTip :: Tip Block -> SlotNo -> Word64
distanceToTip =
    distanceToSlot . getTipSlotNo

-- Point

-- | Parse a 'Point' from a text string. This alternatively tries two patterns:
--
-- - "origin"        → for a points that refers to the beginning of the blockchain
--
-- - "N.hhhh...hhhh" → A dot-separated integer and base16-encoded digest, which
--                     refers to a specific point on chain identified by this
--                     slot number and header hash.
--
pointFromText :: Text -> Maybe (Point Block)
pointFromText txt =
    genesisPointFromText <|> blockPointFromText
  where
    genesisPointFromText = GenesisPoint
        <$ guard (T.toLower txt == "origin")

    blockPointFromText = BlockPoint
        <$> slotNoFromText slotNo
        <*> headerHashFromText (T.drop 1 headerHash)
      where
        (slotNo, headerHash) = T.breakOn "." (T.strip txt)

getPointSlotNo :: Point Block -> SlotNo
getPointSlotNo pt =
    case pointSlot pt of
        Origin -> SlotNo 0
        At sl  -> sl

getPointHeaderHash :: Point Block -> Maybe (HeaderHash Block)
getPointHeaderHash = \case
    GenesisPoint -> Nothing
    BlockPoint _ h -> Just h

unsafeGetPointHeaderHash :: HasCallStack => Point Block -> HeaderHash Block
unsafeGetPointHeaderHash =
    fromMaybe (error "Point is 'Origin'") . getPointHeaderHash

pointToJson
    :: Point Block
    -> Json.Encoding
pointToJson = \case
    GenesisPoint ->
        Json.text "origin"
    BlockPoint slotNo headerHash ->
        Json.pairs $ mconcat
            [ Json.pair "slot_no" (slotNoToJson slotNo)
            , Json.pair "header_hash" (headerHashToJson headerHash)
            ]

-- SlotNo

slotNoToJson :: SlotNo -> Json.Encoding
slotNoToJson =
    Json.integer . toInteger . unSlotNo

-- | Parse a slot number from a text string.
slotNoFromText :: Text -> Maybe SlotNo
slotNoFromText txt = do
    (slotNo, remSlotNo) <- either (const Nothing) Just (T.decimal txt)
    guard (T.null remSlotNo)
    pure (SlotNo slotNo)

slotNoToText :: SlotNo -> Text
slotNoToText (SlotNo sl) =
    show sl

distanceToSlot :: SlotNo -> SlotNo -> Word64
distanceToSlot (SlotNo a) (SlotNo b)
    | a > b = a - b
    | otherwise = b - a

-- Hash

hashToJson :: HashAlgorithm alg => Hash alg a -> Json.Encoding
hashToJson (UnsafeHash h) = byteStringToJson (fromShort h)

-- Digest

digestSize :: forall alg. HashAlgorithm alg => Int
digestSize =
    fromIntegral (sizeHash (Proxy @alg))

-- WithOrigin

instance ToJSON (WithOrigin SlotNo) where
    toEncoding = \case
        Origin -> toEncoding ("origin" :: Text)
        At sl -> toEncoding sl

-- Helper

sizeInvariant :: HasCallStack => (Int -> Bool) -> ByteString -> ByteString
sizeInvariant predicate bytes
    | predicate (BS.length bytes) =
        bytes
    | otherwise =
        error ("predicate failed for bytes: " <> show bytes)
